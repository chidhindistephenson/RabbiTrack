<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Farm;
use App\Models\Litter;
use App\Models\Task;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class WeaningController extends Controller
{
    public function store(Request $request, Farm $farm, Litter $litter): JsonResponse
    {
        $this->authorizeFarmAccess($request, $farm);
        abort_unless($litter->farm_id === $farm->id, 404);

        $validated = $request->validate([
            'weaned_on' => ['required', 'date'],
            'number_weaned' => ['required', 'integer', 'min:0', 'max:100'],
            'average_weight_value' => ['nullable', 'numeric', 'min:0', 'max:99999'],
            'weight_unit' => ['nullable', 'string', 'max:10'],
            'destination' => ['nullable', 'string', 'max:120'],
            'notes' => ['nullable', 'string', 'max:2000'],
        ]);

        $weaning = $farm->weanings()->create([
            'litter_id' => $litter->id,
            'doe_id' => $litter->doe_id,
            'recorded_by_id' => $request->user()->id,
            'weaned_on' => $validated['weaned_on'],
            'number_weaned' => $validated['number_weaned'],
            'average_weight_value' => $validated['average_weight_value'] ?? null,
            'weight_unit' => $validated['weight_unit'] ?? 'kg',
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
}
