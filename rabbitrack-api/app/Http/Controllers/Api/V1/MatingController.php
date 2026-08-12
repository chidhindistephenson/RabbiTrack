<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Farm;
use App\Models\Mating;
use App\Models\Rabbit;
use App\Models\Task;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Carbon;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

class MatingController extends Controller
{
    public function index(Request $request, Farm $farm): JsonResponse
    {
        $this->authorizeFarmAccess($request, $farm);

        $validated = $request->validate([
            'rabbit_id' => ['nullable', 'uuid'],
        ]);

        $matings = $farm->matings()
            ->with(['doe', 'buck'])
            ->when($validated['rabbit_id'] ?? null, function ($query, string $rabbitId): void {
                $query->where(function ($query) use ($rabbitId): void {
                    $query->where('doe_id', $rabbitId)->orWhere('buck_id', $rabbitId);
                });
            })
            ->orderByDesc('mated_at')
            ->limit(100)
            ->get()
            ->map(fn (Mating $mating) => $this->matingPayload($mating));

        return response()->json([
            'data' => $matings,
        ]);
    }

    public function store(Request $request, Farm $farm): JsonResponse
    {
        $this->authorizeFarmAccess($request, $farm);

        $validated = $request->validate([
            'doe_id' => ['required', 'uuid', 'exists:rabbits,id'],
            'buck_id' => ['required', 'uuid', 'exists:rabbits,id'],
            'mated_at' => ['required', 'date'],
            'outcome' => ['nullable', 'string', Rule::in(Mating::OUTCOMES)],
            'behavior_observed' => ['nullable', 'string', 'max:160'],
            'notes' => ['nullable', 'string', 'max:2000'],
        ]);

        $doe = $this->farmRabbit($farm, $validated['doe_id']);
        $buck = $this->farmRabbit($farm, $validated['buck_id']);

        if ($doe->sex !== 'female') {
            throw ValidationException::withMessages([
                'doe_id' => ['The selected doe must be female.'],
            ]);
        }

        if ($buck->sex !== 'male') {
            throw ValidationException::withMessages([
                'buck_id' => ['The selected buck must be male.'],
            ]);
        }

        if ($this->isTerminalRabbitStatus($doe->status)) {
            throw ValidationException::withMessages([
                'doe_id' => ['This doe is no longer active on the farm.'],
            ]);
        }

        if ($this->isTerminalRabbitStatus($buck->status)) {
            throw ValidationException::withMessages([
                'buck_id' => ['This buck is no longer active on the farm.'],
            ]);
        }

        if (in_array($doe->status, ['awaiting_pregnancy_check', 'pregnant'], true)) {
            throw ValidationException::withMessages([
                'doe_id' => ['This doe already has an unresolved breeding cycle.'],
            ]);
        }

        $hasOpenMating = $farm->matings()
            ->where('doe_id', $doe->id)
            ->whereIn('status', ['awaiting_pregnancy_check', 'uncertain', 'pregnant'])
            ->exists();

        if ($hasOpenMating) {
            throw ValidationException::withMessages([
                'doe_id' => ['This doe already has an unresolved mating record.'],
            ]);
        }

        $matedAt = Carbon::parse($validated['mated_at']);
        $dates = $this->breedingDates($farm, $matedAt);

        $mating = $farm->matings()->create([
            'doe_id' => $doe->id,
            'buck_id' => $buck->id,
            'recorded_by_id' => $request->user()->id,
            'mated_at' => $matedAt,
            'outcome' => $validated['outcome'] ?? 'observed',
            'behavior_observed' => $validated['behavior_observed'] ?? null,
            'pregnancy_check_due_on' => $dates['pregnancy_check_due_on'],
            'expected_kindling_on' => $dates['expected_kindling_on'],
            'nest_box_due_on' => $dates['nest_box_due_on'],
            'status' => 'awaiting_pregnancy_check',
            'notes' => $validated['notes'] ?? null,
        ]);

        $doe->update(['status' => 'awaiting_pregnancy_check']);

        $this->createMatingTasks($farm, $mating, $doe);

        return response()->json([
            'data' => $this->matingPayload($mating->load(['doe', 'buck'])),
        ], 201);
    }

    public function show(Request $request, Farm $farm, Mating $mating): JsonResponse
    {
        $this->authorizeFarmAccess($request, $farm);
        abort_unless($mating->farm_id === $farm->id, 404);

        $mating->load([
            'doe',
            'buck',
            'pregnancyChecks' => fn ($query) => $query->orderByDesc('checked_on'),
            'litters' => fn ($query) => $query->orderByDesc('kindled_on'),
        ]);

        return response()->json([
            'data' => $this->matingPayload($mating) + [
                'pregnancy_checks' => $mating->pregnancyChecks->map(fn ($check) => [
                    'id' => $check->id,
                    'checked_on' => $check->checked_on?->toDateString(),
                    'result' => $check->result,
                    'notes' => $check->notes,
                ]),
                'litters' => $mating->litters->map(fn ($litter) => [
                    'id' => $litter->id,
                    'identifier' => $litter->identifier,
                    'kindled_on' => $litter->kindled_on?->toDateString(),
                    'born_alive' => $litter->born_alive,
                    'born_dead' => $litter->born_dead,
                    'status' => $litter->status,
                ]),
            ],
        ]);
    }

    public function destroy(Request $request, Farm $farm, Mating $mating): Response
    {
        $this->authorizeFarmAccess($request, $farm);
        abort_unless($mating->farm_id === $farm->id, 404);

        if ($mating->litters()->exists()) {
            throw ValidationException::withMessages([
                'mating_id' => ['This mating has litter records and cannot be deleted.'],
            ]);
        }

        $doe = $mating->doe;

        Task::query()
            ->where('related_type', Mating::class)
            ->where('related_id', $mating->id)
            ->delete();

        $mating->delete();

        if (
            $doe &&
            ! in_array($doe->status, ['sold', 'deceased', 'culled', 'retired'], true) &&
            ! $farm->matings()
                ->where('doe_id', $doe->id)
                ->whereIn('status', ['awaiting_pregnancy_check', 'uncertain', 'pregnant'])
                ->exists()
        ) {
            $doe->update(['status' => 'available_for_breeding']);
        }

        return response()->noContent();
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

    private function farmRabbit(Farm $farm, string $rabbitId): Rabbit
    {
        $rabbit = $farm->rabbits()->whereKey($rabbitId)->first();

        if (! $rabbit) {
            throw ValidationException::withMessages([
                'rabbit_id' => ['The selected rabbit does not belong to this farm.'],
            ]);
        }

        return $rabbit;
    }

    private function breedingDates(Farm $farm, Carbon $matedAt): array
    {
        $settings = $farm->settings ?? [];
        $pregnancyCheckStartDays = (int) ($settings['pregnancy_check_start_days'] ?? 10);
        $pregnancyCheckEndDays = (int) ($settings['pregnancy_check_end_days'] ?? 14);
        $gestationDays = (int) ($settings['gestation_days'] ?? 31);
        $nestBoxLeadDays = (int) ($settings['nest_box_lead_days'] ?? 3);
        $pregnancyCheckDays = max($pregnancyCheckStartDays, $pregnancyCheckEndDays);

        return [
            'pregnancy_check_due_on' => $matedAt->copy()->addDays($pregnancyCheckDays)->toDateString(),
            'expected_kindling_on' => $matedAt->copy()->addDays($gestationDays)->toDateString(),
            'nest_box_due_on' => $matedAt->copy()->addDays($gestationDays - $nestBoxLeadDays)->toDateString(),
        ];
    }

    private function createMatingTasks(Farm $farm, Mating $mating, Rabbit $doe): void
    {
        $farm->tasks()->create([
            'assigned_to_id' => $mating->recorded_by_id,
            'type' => 'pregnancy_check',
            'title' => "Pregnancy check for {$doe->identifier}",
            'description' => 'Check whether the doe conceived from the recorded mating.',
            'due_on' => $mating->pregnancy_check_due_on,
            'priority' => 'high',
            'status' => 'open',
            'related_type' => Mating::class,
            'related_id' => $mating->id,
            'rabbit_id' => $doe->id,
            'metadata' => [
                'mating_id' => $mating->id,
                'buck_id' => $mating->buck_id,
            ],
        ]);

        $farm->tasks()->create([
            'assigned_to_id' => $mating->recorded_by_id,
            'type' => 'nest_box_preparation',
            'title' => "Prepare nest box for {$doe->identifier}",
            'description' => 'Prepare the nest box before the expected kindling date.',
            'due_on' => $mating->nest_box_due_on,
            'priority' => 'normal',
            'status' => 'open',
            'related_type' => Mating::class,
            'related_id' => $mating->id,
            'rabbit_id' => $doe->id,
            'metadata' => [
                'mating_id' => $mating->id,
                'expected_kindling_on' => $mating->expected_kindling_on->toDateString(),
            ],
        ]);
    }

    private function matingPayload(Mating $mating): array
    {
        return [
            'id' => $mating->id,
            'farm_id' => $mating->farm_id,
            'doe_id' => $mating->doe_id,
            'doe_identifier' => $mating->doe?->identifier,
            'buck_id' => $mating->buck_id,
            'buck_identifier' => $mating->buck?->identifier,
            'mated_at' => $mating->mated_at?->toISOString(),
            'outcome' => $mating->outcome,
            'behavior_observed' => $mating->behavior_observed,
            'pregnancy_check_due_on' => $mating->pregnancy_check_due_on?->toDateString(),
            'expected_kindling_on' => $mating->expected_kindling_on?->toDateString(),
            'nest_box_due_on' => $mating->nest_box_due_on?->toDateString(),
            'status' => $mating->status,
            'notes' => $mating->notes,
        ];
    }

    private function isTerminalRabbitStatus(string $status): bool
    {
        return in_array($status, ['sold', 'retired', 'deceased', 'culled'], true);
    }
}
