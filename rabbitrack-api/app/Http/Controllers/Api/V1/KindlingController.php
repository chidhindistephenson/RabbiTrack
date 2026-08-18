<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Farm;
use App\Models\Litter;
use App\Models\LitterFoster;
use App\Models\Location;
use App\Models\Mating;
use App\Models\Rabbit;
use App\Models\Task;
use Illuminate\Database\QueryException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Carbon;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

class KindlingController extends Controller
{
    public function index(Request $request, Farm $farm): JsonResponse
    {
        $this->authorizeFarmAccess($request, $farm);

        $litters = $farm->litters()
            ->with(['doe', 'buck'])
            ->orderByDesc('kindled_on')
            ->limit(100)
            ->get()
            ->map(fn (Litter $litter) => $this->litterPayload($litter));

        return response()->json(['data' => $litters]);
    }

    public function store(Request $request, Farm $farm): JsonResponse
    {
        $this->authorizeFarmAccess($request, $farm);

        $validated = $request->validate([
            'mating_id' => ['nullable', 'uuid', 'exists:matings,id'],
            'doe_id' => ['required_without:mating_id', 'uuid', 'exists:rabbits,id'],
            'kindled_on' => ['required', 'date'],
            'kits_born_alive' => ['required', 'integer', 'min:0', 'max:100'],
            'kits_stillborn' => ['nullable', 'integer', 'min:0', 'max:100'],
            'kits_weak' => ['nullable', 'integer', 'min:0', 'max:100'],
            'birth_weight_value' => ['required', 'numeric', 'min:0.001', 'max:99999'],
            'weight_unit' => ['nullable', 'string', 'max:10'],
            'nest_condition' => ['nullable', 'string', 'max:160'],
            'doe_condition' => ['nullable', 'string', 'max:160'],
            'notes' => ['nullable', 'string', 'max:2000'],
        ]);

        $mating = isset($validated['mating_id'])
            ? $farm->matings()->with(['doe', 'buck'])->whereKey($validated['mating_id'])->first()
            : null;

        if (isset($validated['mating_id']) && ! $mating) {
            throw ValidationException::withMessages([
                'mating_id' => ['The selected mating does not belong to this farm.'],
            ]);
        }

        $doe = $mating?->doe ?? $this->farmDoe($farm, $validated['doe_id']);
        $buck = $mating?->buck;

        if ($this->isTerminalRabbitStatus($doe->status)) {
            throw ValidationException::withMessages([
                'doe_id' => ['This doe is no longer active on the farm.'],
            ]);
        }

        $kindledOn = Carbon::parse($validated['kindled_on']);
        $weaningDays = (int) (($farm->settings ?? [])['weaning_days'] ?? 35);
        $plannedWeaningOn = $kindledOn->copy()->addDays($weaningDays)->toDateString();
        $alive = (int) $validated['kits_born_alive'];
        $stillborn = (int) ($validated['kits_stillborn'] ?? 0);
        $weak = (int) ($validated['kits_weak'] ?? 0);
        $weightUnit = $validated['weight_unit'] ?? 'kg';
        $birthWeight = (float) $validated['birth_weight_value'];
        $averageBirthWeight = $alive > 0 ? round($birthWeight / $alive, 3) : null;

        $litter = $farm->litters()->create([
            'identifier' => $this->uniqueLitterIdentifier($farm, $kindledOn),
            'doe_id' => $doe->id,
            'buck_id' => $buck?->id,
            'mating_id' => $mating?->id,
            'kindled_on' => $kindledOn->toDateString(),
            'kits_born_alive' => $alive,
            'kits_stillborn' => $stillborn,
            'kits_weak' => $weak,
            'current_live_count' => $alive,
            'planned_weaning_on' => $plannedWeaningOn,
            'status' => 'nursing',
            'notes' => $validated['notes'] ?? null,
        ]);

        $farm->kindlings()->create([
            'mating_id' => $mating?->id,
            'litter_id' => $litter->id,
            'doe_id' => $doe->id,
            'recorded_by_id' => $request->user()->id,
            'kindled_on' => $kindledOn->toDateString(),
            'kits_born_alive' => $alive,
            'kits_stillborn' => $stillborn,
            'kits_weak' => $weak,
            'nest_condition' => $validated['nest_condition'] ?? null,
            'doe_condition' => $validated['doe_condition'] ?? null,
            'notes' => $validated['notes'] ?? null,
        ]);

        $farm->weightRecords()->create([
            'litter_id' => $litter->id,
            'stage' => 'birth',
            'recorded_by_id' => $request->user()->id,
            'weighed_on' => $kindledOn->toDateString(),
            'weight_value' => $birthWeight,
            'weight_unit' => $weightUnit,
            'kit_count' => $alive,
            'average_weight_value' => $averageBirthWeight,
            'method' => 'Kindling record',
            'notes' => 'Birth litter weight recorded during kindling.',
        ]);

        $doe->update(['status' => 'nursing']);
        $mating?->update(['status' => 'kindled']);

        $this->closeKindlingPreparationTasks($mating);
        $this->createWeaningTask($farm, $litter, $request->user()->id);
        $this->createRetirementReviewTaskIfNeeded($farm, $doe, $request->user()->id);

        return response()->json([
            'data' => $this->litterPayload($litter->load(['doe', 'buck'])),
        ], 201);
    }

    public function show(Request $request, Farm $farm, Litter $litter): JsonResponse
    {
        $this->authorizeFarmAccess($request, $farm);
        abort_unless($litter->farm_id === $farm->id, 404);

        $litter->load([
            'doe',
            'buck',
            'checks' => fn ($query) => $query->orderByDesc('checked_on')->orderByDesc('created_at'),
            'fostersOut' => fn ($query) => $query->with('toLitter')->orderByDesc('fostered_on')->orderByDesc('created_at'),
            'fostersIn' => fn ($query) => $query->with('fromLitter')->orderByDesc('fostered_on')->orderByDesc('created_at'),
            'weanings' => fn ($query) => $query->orderByDesc('weaned_on'),
            'weightRecords' => fn ($query) => $query->orderByDesc('weighed_on'),
        ]);

        return response()->json([
            'data' => $this->litterPayload($litter) + [
                'weanings' => $litter->weanings->map(fn ($weaning) => [
                    'id' => $weaning->id,
                    'weaned_on' => $weaning->weaned_on?->toDateString(),
                    'number_weaned' => $weaning->number_weaned,
                    'average_weight_value' => $weaning->average_weight_value,
                    'weight_unit' => $weaning->weight_unit,
                    'destination' => $weaning->destination,
                    'notes' => $weaning->notes,
                ]),
                'checks' => $litter->checks->map(fn ($check) => [
                    'id' => $check->id,
                    'checked_on' => $check->checked_on?->toDateString(),
                    'live_count' => $check->live_count,
                    'dead_count' => $check->dead_count,
                    'weak_count' => $check->weak_count,
                    'suspected_cause' => $check->suspected_cause,
                    'nest_observation' => $check->nest_observation,
                    'corrective_action' => $check->corrective_action,
                    'notes' => $check->notes,
                ]),
                'fosters_out' => $litter->fostersOut->map(fn (LitterFoster $foster) => $this->fosterPayload($foster)),
                'fosters_in' => $litter->fostersIn->map(fn (LitterFoster $foster) => $this->fosterPayload($foster)),
                'weights' => $litter->weightRecords->map(fn ($weight) => [
                    'id' => $weight->id,
                    'weighed_on' => $weight->weighed_on?->toDateString(),
                    'weight_value' => $weight->weight_value,
                    'weight_unit' => $weight->weight_unit,
                    'stage' => $weight->stage,
                    'kit_count' => $weight->kit_count,
                    'average_weight_value' => $weight->average_weight_value,
                    'method' => $weight->method,
                    'notes' => $weight->notes,
                ]),
            ],
        ]);
    }

    public function storeCheck(Request $request, Farm $farm, Litter $litter): JsonResponse
    {
        $this->authorizeFarmAccess($request, $farm);
        abort_unless($litter->farm_id === $farm->id, 404);

        if (in_array($litter->status, ['closed', 'archived'], true)) {
            throw ValidationException::withMessages([
                'litter_id' => ['This litter is closed and cannot receive new checks.'],
            ]);
        }

        $validated = $request->validate([
            'checked_on' => ['required', 'date'],
            'live_count' => ['required', 'integer', 'min:0', 'max:100'],
            'dead_count' => ['nullable', 'integer', 'min:0', 'max:100'],
            'weak_count' => ['nullable', 'integer', 'min:0', 'max:100'],
            'suspected_cause' => ['nullable', 'string', 'max:160'],
            'nest_observation' => ['nullable', 'string', 'max:160'],
            'corrective_action' => ['nullable', 'string', 'max:160'],
            'notes' => ['nullable', 'string', 'max:2000'],
        ]);

        $liveCount = (int) $validated['live_count'];
        $deadCount = (int) ($validated['dead_count'] ?? 0);
        $weakCount = (int) ($validated['weak_count'] ?? 0);

        if ($liveCount > $litter->current_live_count) {
            throw ValidationException::withMessages([
                'live_count' => ['Live count cannot be higher than the current litter count.'],
            ]);
        }

        if ($deadCount > $litter->current_live_count) {
            throw ValidationException::withMessages([
                'dead_count' => ['Dead count cannot exceed the current litter count.'],
            ]);
        }

        if ($liveCount + $deadCount > $litter->current_live_count) {
            throw ValidationException::withMessages([
                'live_count' => ['Live and dead counts cannot exceed the current litter count.'],
            ]);
        }

        if ($weakCount > $liveCount) {
            throw ValidationException::withMessages([
                'weak_count' => ['Weak count cannot exceed live count.'],
            ]);
        }

        $check = DB::transaction(function () use ($request, $farm, $litter, $validated, $liveCount, $deadCount, $weakCount) {
            $check = $farm->litterChecks()->create([
                'litter_id' => $litter->id,
                'recorded_by_id' => $request->user()->id,
                'checked_on' => Carbon::parse($validated['checked_on'])->toDateString(),
                'live_count' => $liveCount,
                'dead_count' => $deadCount,
                'weak_count' => $weakCount,
                'suspected_cause' => $validated['suspected_cause'] ?? null,
                'nest_observation' => $validated['nest_observation'] ?? null,
                'corrective_action' => $validated['corrective_action'] ?? null,
                'notes' => $validated['notes'] ?? null,
            ]);

            $litter->update([
                'current_live_count' => $liveCount,
            ]);

            return $check;
        });

        return response()->json([
            'data' => [
                'id' => $check->id,
                'litter_id' => $check->litter_id,
                'checked_on' => $check->checked_on?->toDateString(),
                'live_count' => $check->live_count,
                'dead_count' => $check->dead_count,
                'weak_count' => $check->weak_count,
                'suspected_cause' => $check->suspected_cause,
                'nest_observation' => $check->nest_observation,
                'corrective_action' => $check->corrective_action,
                'notes' => $check->notes,
                'litter_live_count' => $liveCount,
            ],
        ], 201);
    }

    public function storeFoster(Request $request, Farm $farm, Litter $litter): JsonResponse
    {
        $this->authorizeFarmAccess($request, $farm);
        abort_unless($litter->farm_id === $farm->id, 404);

        $validated = $request->validate([
            'to_litter_id' => ['required', 'uuid', 'exists:litters,id'],
            'fostered_on' => ['required', 'date'],
            'kit_count' => ['required', 'integer', 'min:1', 'max:100'],
            'reason' => ['nullable', 'string', 'max:160'],
            'notes' => ['nullable', 'string', 'max:2000'],
        ]);

        $toLitter = $farm->litters()->whereKey($validated['to_litter_id'])->first();

        if (! $toLitter instanceof Litter) {
            throw ValidationException::withMessages([
                'to_litter_id' => ['Select a litter from this farm.'],
            ]);
        }

        if ($toLitter->id === $litter->id) {
            throw ValidationException::withMessages([
                'to_litter_id' => ['Choose a different litter to receive the fostered kits.'],
            ]);
        }

        $activeStatuses = ['newborn', 'nursing', 'partially_weaned'];
        if (! in_array($litter->status, $activeStatuses, true)) {
            throw ValidationException::withMessages([
                'litter_id' => ['This litter is not active for fostering.'],
            ]);
        }

        if (! in_array($toLitter->status, $activeStatuses, true)) {
            throw ValidationException::withMessages([
                'to_litter_id' => ['The receiving litter is not active for fostering.'],
            ]);
        }

        $kitCount = (int) $validated['kit_count'];
        if ($kitCount > $litter->current_live_count) {
            throw ValidationException::withMessages([
                'kit_count' => ['Cannot foster more kits than the source litter currently has.'],
            ]);
        }

        $foster = DB::transaction(function () use ($request, $farm, $litter, $toLitter, $validated, $kitCount): LitterFoster {
            $foster = $farm->litterFosters()->create([
                'from_litter_id' => $litter->id,
                'to_litter_id' => $toLitter->id,
                'recorded_by_id' => $request->user()->id,
                'fostered_on' => Carbon::parse($validated['fostered_on'])->toDateString(),
                'kit_count' => $kitCount,
                'reason' => $validated['reason'] ?? null,
                'notes' => $validated['notes'] ?? null,
            ]);

            $litter->decrement('current_live_count', $kitCount);
            $toLitter->increment('current_live_count', $kitCount);

            return $foster->load(['fromLitter', 'toLitter']);
        });

        $litter->refresh();
        $toLitter->refresh();

        return response()->json([
            'data' => $this->fosterPayload($foster) + [
                'from_live_count' => $litter->current_live_count,
                'to_live_count' => $toLitter->current_live_count,
            ],
        ], 201);
    }

    public function convertKits(Request $request, Farm $farm, Litter $litter): JsonResponse
    {
        $this->authorizeFarmAccess($request, $farm);
        abort_unless($litter->farm_id === $farm->id, 404);

        $validated = $request->validate([
            'count' => ['required', 'integer', 'min:1', 'max:100'],
            'sex' => ['nullable', 'string', Rule::in(Rabbit::SEXES)],
            'breed' => ['nullable', 'string', 'max:120'],
            'colour' => ['nullable', 'string', 'max:120'],
            'current_location_id' => ['nullable', 'uuid', 'exists:locations,id'],
            'notes' => ['nullable', 'string', 'max:2000'],
        ]);

        if (! in_array($litter->status, ['partially_weaned', 'weaned'], true)) {
            throw ValidationException::withMessages([
                'litter_id' => ['Kits can be converted after the litter has been weaned.'],
            ]);
        }

        $convertedCount = $farm->rabbits()
            ->where('origin_litter_id', $litter->id)
            ->count();
        $remainingCount = max(0, $litter->current_live_count - $convertedCount);

        if ((int) $validated['count'] > $remainingCount) {
            throw ValidationException::withMessages([
                'count' => ["Only {$remainingCount} unconverted kits remain in this litter."],
            ]);
        }

        $location = null;
        if (! empty($validated['current_location_id'])) {
            $location = $farm->locations()
                ->whereKey($validated['current_location_id'])
                ->first();

            if (! $location instanceof Location || ! $location->is_active) {
                throw ValidationException::withMessages([
                    'current_location_id' => ['Select an active location from this farm.'],
                ]);
            }
        }

        $sex = $validated['sex'] ?? 'unknown';
        $breed = $validated['breed'] ?? $litter->doe?->breed;
        $count = (int) $validated['count'];

        $rabbits = DB::transaction(function () use ($request, $farm, $litter, $validated, $sex, $breed, $location, $count) {
            $created = collect();

            for ($index = 0; $index < $count; $index++) {
                $rabbit = $this->createLitterRabbitWithRetry($request, $farm, $litter, [
                    'name' => null,
                    'sex' => $sex,
                    'date_of_birth' => $litter->kindled_on?->toDateString(),
                    'breed' => $breed,
                    'colour' => $validated['colour'] ?? null,
                    'weight_unit' => 'kg',
                    'status' => 'growing',
                    'current_location_id' => $location?->id,
                    'mother_id' => $litter->doe_id,
                    'father_id' => $litter->buck_id,
                    'origin_type' => 'born_on_farm',
                    'origin_litter_id' => $litter->id,
                    'is_farm_born' => true,
                    'acquired_at' => now()->toDateString(),
                    'notes' => $validated['notes'] ?? null,
                ]);

                $created->push($rabbit->load('currentLocation'));
            }

            $totalConverted = $farm->rabbits()
                ->where('origin_litter_id', $litter->id)
                ->count();

            if ($totalConverted >= $litter->current_live_count) {
                Task::query()
                    ->where('related_type', Litter::class)
                    ->where('related_id', $litter->id)
                    ->where('type', 'kit_identification')
                    ->where('status', 'open')
                    ->update(['status' => 'completed']);
            }

            return $created;
        });

        $totalConverted = $farm->rabbits()
            ->where('origin_litter_id', $litter->id)
            ->count();

        return response()->json([
            'data' => [
                'converted_count' => $rabbits->count(),
                'remaining_count' => max(0, $litter->current_live_count - $totalConverted),
                'rabbits' => $rabbits->map(fn (Rabbit $rabbit) => $this->rabbitPayload($rabbit))->values(),
            ],
        ], 201);
    }

    private function authorizeFarmAccess(Request $request, Farm $farm): void
    {
        $hasAccess = $request->user()
            ->memberships()
            ->where('farm_id', $farm->id)
            ->where('is_active', true)
            ->exists();

        abort_unless($hasAccess, 404);
    }

    private function farmDoe(Farm $farm, string $doeId): Rabbit
    {
        $doe = $farm->rabbits()->whereKey($doeId)->first();

        if (! $doe || $doe->sex !== 'female') {
            throw ValidationException::withMessages([
                'doe_id' => ['The selected doe must be female and belong to this farm.'],
            ]);
        }

        return $doe;
    }

    private function isTerminalRabbitStatus(string $status): bool
    {
        return in_array($status, ['sold', 'retired', 'deceased', 'culled'], true);
    }

    private function closeKindlingPreparationTasks(?Mating $mating): void
    {
        if (! $mating) {
            return;
        }

        Task::query()
            ->where('related_type', Mating::class)
            ->where('related_id', $mating->id)
            ->whereIn('type', ['nest_box_preparation', 'expected_kindling'])
            ->where('status', 'open')
            ->update(['status' => 'completed']);
    }

    private function createWeaningTask(Farm $farm, Litter $litter, int $userId): void
    {
        $farm->tasks()->create([
            'assigned_to_id' => $userId,
            'type' => 'weaning',
            'title' => "Wean litter {$litter->identifier}",
            'description' => 'Record actual weaning count, weights, and destination.',
            'due_on' => $litter->planned_weaning_on,
            'priority' => 'normal',
            'status' => 'open',
            'related_type' => Litter::class,
            'related_id' => $litter->id,
            'rabbit_id' => $litter->doe_id,
            'metadata' => [
                'litter_id' => $litter->id,
                'planned_weaning_on' => $litter->planned_weaning_on->toDateString(),
            ],
        ]);
    }

    private function createRetirementReviewTaskIfNeeded(Farm $farm, Rabbit $doe, int $userId): void
    {
        $threshold = (int) (($farm->settings ?? [])['retirement_review_litter_threshold'] ?? 0);
        if ($threshold <= 0) {
            return;
        }

        $completedLitters = $farm->litters()
            ->where('doe_id', $doe->id)
            ->count();

        if ($completedLitters < $threshold) {
            return;
        }

        $alreadyOpen = $farm->tasks()
            ->where('type', 'retirement_review')
            ->where('rabbit_id', $doe->id)
            ->where('status', 'open')
            ->exists();

        if ($alreadyOpen) {
            return;
        }

        $farm->tasks()->create([
            'assigned_to_id' => $userId,
            'type' => 'retirement_review',
            'title' => "Review {$doe->identifier} for retirement",
            'description' => "This doe has reached {$completedLitters} completed litters. Review age, health, survival and breeding performance before deciding whether to rest, retire or keep breeding.",
            'due_on' => now()->toDateString(),
            'priority' => 'high',
            'status' => 'open',
            'related_type' => Rabbit::class,
            'related_id' => $doe->id,
            'rabbit_id' => $doe->id,
            'metadata' => [
                'completed_litters' => $completedLitters,
                'threshold' => $threshold,
            ],
        ]);
    }

    private function uniqueLitterIdentifier(Farm $farm, Carbon $kindledOn): string
    {
        do {
            $identifier = 'LIT-'.$kindledOn->format('ymd').'-'.Str::upper(Str::random(4));
        } while ($farm->litters()->where('identifier', $identifier)->exists());

        return $identifier;
    }

    private function litterPayload(Litter $litter): array
    {
        $convertedCount = $litter->farm
            ? $litter->farm->rabbits()->where('origin_litter_id', $litter->id)->count()
            : Rabbit::query()->where('origin_litter_id', $litter->id)->count();

        return [
            'id' => $litter->id,
            'identifier' => $litter->identifier,
            'doe_id' => $litter->doe_id,
            'doe_identifier' => $litter->doe?->identifier,
            'buck_id' => $litter->buck_id,
            'buck_identifier' => $litter->buck?->identifier,
            'mating_id' => $litter->mating_id,
            'kindled_on' => $litter->kindled_on?->toDateString(),
            'kits_born_alive' => $litter->kits_born_alive,
            'kits_stillborn' => $litter->kits_stillborn,
            'kits_weak' => $litter->kits_weak,
            'current_live_count' => $litter->current_live_count,
            'converted_rabbits_count' => $convertedCount,
            'unconverted_kits_count' => max(0, $litter->current_live_count - $convertedCount),
            'planned_weaning_on' => $litter->planned_weaning_on?->toDateString(),
            'status' => $litter->status,
            'notes' => $litter->notes,
        ];
    }

    private function fosterPayload(LitterFoster $foster): array
    {
        return [
            'id' => $foster->id,
            'fostered_on' => $foster->fostered_on?->toDateString(),
            'kit_count' => $foster->kit_count,
            'reason' => $foster->reason,
            'notes' => $foster->notes,
            'from_litter_id' => $foster->from_litter_id,
            'from_litter_identifier' => $foster->fromLitter?->identifier,
            'to_litter_id' => $foster->to_litter_id,
            'to_litter_identifier' => $foster->toLitter?->identifier,
        ];
    }

    private function createLitterRabbitWithRetry(Request $request, Farm $farm, Litter $litter, array $attributes): Rabbit
    {
        for ($attempt = 1; $attempt <= 5; $attempt++) {
            $attributes['identifier'] = $this->nextRabbitIdentifier($farm, $attributes['sex']);
            $attributes['tag_or_tattoo'] = $attributes['identifier'];

            try {
                return DB::transaction(function () use ($request, $farm, $attributes): Rabbit {
                    $rabbit = $farm->rabbits()->create($attributes);

                    if ($rabbit->current_location_id !== null) {
                        $rabbit->movements()->create([
                            'farm_id' => $farm->id,
                            'from_location_id' => null,
                            'to_location_id' => $rabbit->current_location_id,
                            'user_id' => $request->user()->id,
                            'moved_at' => now(),
                            'reason' => 'Litter kit conversion',
                        ]);
                    }

                    return $rabbit;
                });
            } catch (QueryException $exception) {
                if (! $this->isUniqueIdentifierCollision($exception) || $attempt === 5) {
                    throw $exception;
                }
            }
        }

        throw ValidationException::withMessages([
            'identifier' => ['A rabbit identifier could not be assigned. Try again.'],
        ]);
    }

    private function nextRabbitIdentifier(Farm $farm, string $sex): string
    {
        $prefix = match ($sex) {
            'female' => 'DOE',
            'male' => 'BUCK',
            default => 'RAB',
        };

        $maxNumber = $farm->rabbits()
            ->where('identifier', 'like', "{$prefix}-%")
            ->pluck('identifier')
            ->map(function (string $identifier) use ($prefix): ?int {
                if (preg_match('/^'.$prefix.'-(\d+)$/', $identifier, $matches) !== 1) {
                    return null;
                }

                return (int) $matches[1];
            })
            ->filter()
            ->max() ?? 0;

        $nextNumber = $maxNumber + 1;

        do {
            $identifier = sprintf('%s-%04d', $prefix, $nextNumber);
            $nextNumber++;
        } while ($farm->rabbits()->where('identifier', $identifier)->exists());

        return $identifier;
    }

    private function rabbitPayload(Rabbit $rabbit): array
    {
        return [
            'id' => $rabbit->id,
            'identifier' => $rabbit->identifier,
            'name' => $rabbit->name,
            'sex' => $rabbit->sex,
            'date_of_birth' => $rabbit->date_of_birth?->toDateString(),
            'breed' => $rabbit->breed,
            'colour' => $rabbit->colour,
            'tag_or_tattoo' => $rabbit->tag_or_tattoo,
            'status' => $rabbit->status,
            'current_location_id' => $rabbit->current_location_id,
            'current_location_name' => $rabbit->currentLocation?->name,
            'mother_id' => $rabbit->mother_id,
            'father_id' => $rabbit->father_id,
            'origin_type' => $rabbit->origin_type,
            'origin_litter_id' => $rabbit->origin_litter_id,
            'is_farm_born' => $rabbit->is_farm_born,
            'notes' => $rabbit->notes,
        ];
    }

    private function isUniqueIdentifierCollision(QueryException $exception): bool
    {
        $sqlState = $exception->errorInfo[0] ?? null;

        if (! in_array($sqlState, ['23000', '23505'], true)) {
            return false;
        }

        $message = $exception->getMessage();

        return str_contains($message, 'rabbits') && str_contains($message, 'identifier');
    }
}
