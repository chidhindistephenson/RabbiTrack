<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Farm;
use App\Models\Litter;
use App\Models\Mating;
use App\Models\Rabbit;
use App\Models\Task;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Str;
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

        $doe->update(['status' => 'nursing']);
        $mating?->update(['status' => 'kindled']);

        $this->closeKindlingPreparationTasks($mating);
        $this->createWeaningTask($farm, $litter, $request->user()->id);

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
                'weights' => $litter->weightRecords->map(fn ($weight) => [
                    'id' => $weight->id,
                    'weighed_on' => $weight->weighed_on?->toDateString(),
                    'weight_value' => $weight->weight_value,
                    'weight_unit' => $weight->weight_unit,
                    'method' => $weight->method,
                    'notes' => $weight->notes,
                ]),
            ],
        ]);
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

    private function uniqueLitterIdentifier(Farm $farm, Carbon $kindledOn): string
    {
        do {
            $identifier = 'LIT-'.$kindledOn->format('ymd').'-'.Str::upper(Str::random(4));
        } while ($farm->litters()->where('identifier', $identifier)->exists());

        return $identifier;
    }

    private function litterPayload(Litter $litter): array
    {
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
            'planned_weaning_on' => $litter->planned_weaning_on?->toDateString(),
            'status' => $litter->status,
            'notes' => $litter->notes,
        ];
    }
}
