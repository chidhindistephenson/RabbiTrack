<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Farm;
use App\Models\Mating;
use App\Models\PregnancyCheck;
use App\Models\Task;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

class PregnancyCheckController extends Controller
{
    public function store(Request $request, Farm $farm, Mating $mating): JsonResponse
    {
        $this->authorizeFarmAccess($request, $farm);
        abort_unless($mating->farm_id === $farm->id, 404);

        if (! in_array($mating->status, ['awaiting_pregnancy_check', 'uncertain'], true)) {
            throw ValidationException::withMessages([
                'mating_id' => ['Pregnancy check has already been completed for this mating.'],
            ]);
        }

        if (Carbon::today()->lt($mating->pregnancy_check_due_on)) {
            throw ValidationException::withMessages([
                'pregnancy_check_due_on' => ["Pregnancy check is due on {$mating->pregnancy_check_due_on->toDateString()}."],
            ]);
        }

        $validated = $request->validate([
            'checked_on' => ['required', 'date'],
            'result' => ['required', 'string', Rule::in(PregnancyCheck::RESULTS)],
            'notes' => ['nullable', 'string', 'max:2000'],
        ]);

        $mating->load('doe');

        $check = $farm->pregnancyChecks()->create([
            'mating_id' => $mating->id,
            'doe_id' => $mating->doe_id,
            'examiner_id' => $request->user()->id,
            'checked_on' => $validated['checked_on'],
            'result' => $validated['result'],
            'notes' => $validated['notes'] ?? null,
        ]);

        $this->completePregnancyCheckTasks($mating);
        $this->applyOutcome($farm, $mating, $validated['result'], $request->user()->id);

        return response()->json([
            'data' => [
                'id' => $check->id,
                'mating_id' => $check->mating_id,
                'doe_id' => $check->doe_id,
                'checked_on' => $check->checked_on->toDateString(),
                'result' => $check->result,
                'notes' => $check->notes,
                'mating_status' => $mating->fresh()->status,
                'doe_status' => $mating->doe->fresh()->status,
            ],
        ], 201);
    }

    public function reviseLatest(Request $request, Farm $farm, Mating $mating): JsonResponse
    {
        $this->authorizeFarmAccess($request, $farm);
        abort_unless($mating->farm_id === $farm->id, 404);

        if ($mating->litters()->exists()) {
            throw ValidationException::withMessages([
                'mating_id' => ['This mating has litter records and its pregnancy decision cannot be revised.'],
            ]);
        }

        $check = $mating->pregnancyChecks()
            ->orderByDesc('checked_on')
            ->orderByDesc('created_at')
            ->first();

        if (! $check) {
            throw ValidationException::withMessages([
                'pregnancy_check' => ['Record a pregnancy check before revising the decision.'],
            ]);
        }

        $validated = $request->validate([
            'checked_on' => ['required', 'date'],
            'result' => ['required', 'string', Rule::in(PregnancyCheck::RESULTS)],
            'notes' => ['nullable', 'string', 'max:2000'],
        ]);

        $mating->load('doe');

        $check->update([
            'examiner_id' => $request->user()->id,
            'checked_on' => $validated['checked_on'],
            'result' => $validated['result'],
            'notes' => $validated['notes'] ?? null,
        ]);

        $this->applyOutcome($farm, $mating, $validated['result'], $request->user()->id);

        return response()->json([
            'data' => [
                'id' => $check->id,
                'mating_id' => $check->mating_id,
                'doe_id' => $check->doe_id,
                'checked_on' => $check->fresh()->checked_on->toDateString(),
                'result' => $check->fresh()->result,
                'notes' => $check->fresh()->notes,
                'mating_status' => $mating->fresh()->status,
                'doe_status' => $mating->doe->fresh()->status,
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

    private function completePregnancyCheckTasks(Mating $mating): void
    {
        Task::query()
            ->where('related_type', Mating::class)
            ->where('related_id', $mating->id)
            ->where('type', 'pregnancy_check')
            ->where('status', 'open')
            ->update(['status' => 'completed']);
    }

    private function applyOutcome(Farm $farm, Mating $mating, string $result, int $userId): void
    {
        match ($result) {
            'pregnant' => $this->markPregnant($mating),
            'not_pregnant' => $this->markNotPregnant($mating),
            'uncertain' => $this->markUncertain($farm, $mating, $userId),
            'not_checked' => $this->markUncertain($farm, $mating, $userId),
        };
    }

    private function markPregnant(Mating $mating): void
    {
        $mating->update(['status' => 'pregnant']);
        $mating->doe->update(['status' => 'pregnant']);
    }

    private function markNotPregnant(Mating $mating): void
    {
        $mating->update(['status' => 'not_pregnant']);
        $mating->doe->update(['status' => 'available_for_breeding']);

        Task::query()
            ->where('related_type', Mating::class)
            ->where('related_id', $mating->id)
            ->whereIn('type', ['nest_box_preparation', 'expected_kindling'])
            ->where('status', 'open')
            ->update(['status' => 'cancelled']);
    }

    private function markUncertain(Farm $farm, Mating $mating, int $userId): void
    {
        $repeatAfterDays = (int) (($farm->settings ?? [])['repeat_pregnancy_check_days'] ?? 3);

        $repeatDueOn = now()->addDays($repeatAfterDays)->toDateString();

        $mating->update([
            'status' => 'uncertain',
            'pregnancy_check_due_on' => $repeatDueOn,
        ]);
        $mating->doe->update(['status' => 'awaiting_pregnancy_check']);

        $farm->tasks()->create([
            'assigned_to_id' => $userId,
            'type' => 'pregnancy_check',
            'title' => "Repeat pregnancy check for {$mating->doe->identifier}",
            'description' => 'Repeat the pregnancy check because the previous result was uncertain.',
            'due_on' => $repeatDueOn,
            'priority' => 'high',
            'status' => 'open',
            'related_type' => Mating::class,
            'related_id' => $mating->id,
            'rabbit_id' => $mating->doe_id,
            'metadata' => [
                'mating_id' => $mating->id,
                'repeat_after_days' => $repeatAfterDays,
            ],
        ]);
    }
}
