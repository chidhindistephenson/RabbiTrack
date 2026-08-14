<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Farm;
use App\Models\Litter;
use App\Models\Task;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;

class WeaningController extends Controller
{
    public function store(Request $request, Farm $farm, Litter $litter): JsonResponse
    {
        $this->authorizeFarmAccess($request, $farm);
        abort_unless($litter->farm_id === $farm->id, 404);

        $validated = $request->validate([
            'weaned_on' => ['required', 'date'],
            'number_weaned' => ['required', 'integer', 'min:0', 'max:100'],
            'average_weight_value' => ['required', 'numeric', 'min:0.001', 'max:99999'],
            'weight_unit' => ['nullable', 'string', 'max:10'],
            'destination' => ['nullable', 'string', 'max:120'],
            'notes' => ['nullable', 'string', 'max:2000'],
        ]);

        $weightUnit = $validated['weight_unit'] ?? 'kg';
        $averageWeight = (float) $validated['average_weight_value'];
        $totalWeight = round($averageWeight * (int) $validated['number_weaned'], 3);

        $weaning = $farm->weanings()->create([
            'litter_id' => $litter->id,
            'doe_id' => $litter->doe_id,
            'recorded_by_id' => $request->user()->id,
            'weaned_on' => $validated['weaned_on'],
            'number_weaned' => $validated['number_weaned'],
            'average_weight_value' => $averageWeight,
            'weight_unit' => $weightUnit,
            'destination' => $validated['destination'] ?? null,
            'notes' => $validated['notes'] ?? null,
        ]);

        $litter->update([
            'current_live_count' => $validated['number_weaned'],
            'status' => 'weaned',
        ]);

        $litter->doe()->update(['status' => 'available_for_breeding']);

        Task::query()
            ->where('related_type', Litter::class)
            ->where('related_id', $litter->id)
            ->where('type', 'weaning')
            ->where('status', 'open')
            ->update(['status' => 'completed']);

        $farm->weightRecords()->updateOrCreate(
            [
                'litter_id' => $litter->id,
                'stage' => 'weaning',
            ],
            [
                'recorded_by_id' => $request->user()->id,
                'weighed_on' => $validated['weaned_on'],
                'weight_value' => $totalWeight,
                'weight_unit' => $weightUnit,
                'kit_count' => $validated['number_weaned'],
                'average_weight_value' => $averageWeight,
                'method' => 'Weaning record',
                'notes' => 'Weaning litter weight recorded during weaning.',
            ],
        );

        $this->createKitIdentificationTask($farm, $litter, $request->user()->id, $validated['weaned_on']);

        return response()->json([
            'data' => [
                'id' => $weaning->id,
                'litter_id' => $weaning->litter_id,
                'doe_id' => $weaning->doe_id,
                'weaned_on' => $weaning->weaned_on->toDateString(),
                'number_weaned' => $weaning->number_weaned,
                'average_weight_value' => $weaning->average_weight_value,
                'weight_unit' => $weaning->weight_unit,
                'destination' => $weaning->destination,
                'litter_status' => $litter->fresh()->status,
                'doe_status' => $litter->doe->fresh()->status,
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

    private function createKitIdentificationTask(Farm $farm, Litter $litter, int $userId, string $weanedOn): void
    {
        $settings = $farm->settings ?? [];
        $daysAfterWeaning = (int) ($settings['kit_identification_days_after_weaning'] ?? 7);
        $dueOn = Carbon::parse($weanedOn)->addDays($daysAfterWeaning)->toDateString();

        $farm->tasks()->updateOrCreate(
            [
                'related_type' => Litter::class,
                'related_id' => $litter->id,
                'type' => 'kit_identification',
            ],
            [
                'assigned_to_id' => $userId,
                'title' => "Identify/tag kits from {$litter->identifier}",
                'description' => 'Create rabbit records for weaned kits and mark each kit with its assigned Rabbit ID.',
                'due_on' => $dueOn,
                'priority' => 'normal',
                'status' => 'open',
                'rabbit_id' => $litter->doe_id,
                'litter_id' => $litter->id,
                'metadata' => [
                    'litter_id' => $litter->id,
                    'weaned_on' => $weanedOn,
                    'number_weaned' => $litter->current_live_count,
                ],
            ],
        );
    }
}
