<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Farm;
use App\Models\Task;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

class TaskController extends Controller
{
    public function index(Request $request, Farm $farm): JsonResponse
    {
        $this->authorizeFarmAccess($request, $farm);

        $validated = $request->validate([
            'status' => ['nullable', 'string', Rule::in(Task::STATUSES)],
            'due' => ['nullable', 'string', Rule::in(['today', 'overdue', 'upcoming'])],
        ]);

        $tasks = $farm->tasks()
            ->with(['rabbit', 'location'])
            ->when($validated['status'] ?? null, fn ($query, string $status) => $query->where('status', $status))
            ->when(($validated['due'] ?? null) === 'today', fn ($query) => $query->whereDate('due_on', now()->toDateString()))
            ->when(($validated['due'] ?? null) === 'overdue', fn ($query) => $query->whereDate('due_on', '<', now()->toDateString())->where('status', 'open'))
            ->when(($validated['due'] ?? null) === 'upcoming', fn ($query) => $query->whereDate('due_on', '>', now()->toDateString())->where('status', 'open'))
            ->orderBy('due_on')
            ->orderBy('priority')
            ->limit(150)
            ->get()
            ->map(fn (Task $task) => $this->taskPayload($task));

        return response()->json(['data' => $tasks]);
    }

    public function store(Request $request, Farm $farm): JsonResponse
    {
        $this->authorizeFarmAccess($request, $farm);

        $validated = $request->validate([
            'title' => ['required', 'string', 'max:160'],
            'description' => ['nullable', 'string', 'max:2000'],
            'due_on' => ['required', 'date'],
            'due_time' => ['nullable', 'date_format:H:i'],
            'priority' => ['nullable', 'string', Rule::in(['low', 'normal', 'high', 'critical'])],
            'rabbit_id' => ['nullable', 'uuid', 'exists:rabbits,id'],
            'location_id' => ['nullable', 'uuid', 'exists:locations,id'],
        ]);

        $rabbit = isset($validated['rabbit_id'])
            ? $farm->rabbits()->whereKey($validated['rabbit_id'])->first()
            : null;

        if (isset($validated['rabbit_id']) && ! $rabbit) {
            abort(422);
        }

        if ($rabbit && $this->isTerminalRabbitStatus($rabbit->status)) {
            throw ValidationException::withMessages([
                'rabbit_id' => ['This rabbit is no longer active on the farm.'],
            ]);
        }

        if (isset($validated['location_id'])) {
            abort_unless($farm->locations()->whereKey($validated['location_id'])->exists(), 422);
        }

        $task = $farm->tasks()->create([
            'assigned_to_id' => $request->user()->id,
            'type' => 'manual',
            'title' => $validated['title'],
            'description' => $validated['description'] ?? null,
            'due_on' => $validated['due_on'],
            'due_time' => $validated['due_time'] ?? null,
            'priority' => $validated['priority'] ?? 'normal',
            'status' => 'open',
            'rabbit_id' => $validated['rabbit_id'] ?? null,
            'location_id' => $validated['location_id'] ?? null,
        ]);

        return response()->json(['data' => $this->taskPayload($task)], 201);
    }

    public function update(Request $request, Farm $farm, Task $task): JsonResponse
    {
        $this->authorizeFarmAccess($request, $farm);
        abort_unless($task->farm_id === $farm->id, 404);

        $validated = $request->validate([
            'action' => ['required', 'string', Rule::in(['complete', 'snooze', 'cancel', 'reschedule'])],
            'due_on' => ['required_if:action,snooze,reschedule', 'date'],
            'due_time' => ['nullable', 'date_format:H:i'],
        ]);

        match ($validated['action']) {
            'complete' => $task->update(['status' => 'completed']),
            'cancel' => $task->update(['status' => 'cancelled']),
            'snooze' => $task->update([
                'status' => 'snoozed',
                'due_on' => $validated['due_on'],
                'due_time' => $validated['due_time'] ?? $task->due_time,
            ]),
            'reschedule' => $task->update([
                'status' => 'open',
                'due_on' => $validated['due_on'],
                'due_time' => $validated['due_time'] ?? $task->due_time,
            ]),
        };

        return response()->json(['data' => $this->taskPayload($task->fresh(['rabbit', 'location']))]);
    }

    public function summary(Request $request, Farm $farm): JsonResponse
    {
        $this->authorizeFarmAccess($request, $farm);

        return response()->json([
            'data' => [
                'today' => $farm->tasks()->where('status', 'open')->whereDate('due_on', now()->toDateString())->count(),
                'overdue' => $farm->tasks()->where('status', 'open')->whereDate('due_on', '<', now()->toDateString())->count(),
                'open' => $farm->tasks()->where('status', 'open')->count(),
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

    private function isTerminalRabbitStatus(string $status): bool
    {
        return in_array($status, ['sold', 'retired', 'deceased', 'culled'], true);
    }

    private function taskPayload(Task $task): array
    {
        return [
            'id' => $task->id,
            'type' => $task->type,
            'title' => $task->title,
            'description' => $task->description,
            'due_on' => $task->due_on?->toDateString(),
            'due_time' => $task->due_time,
            'priority' => $task->priority,
            'status' => $task->status,
            'rabbit_id' => $task->rabbit_id,
            'rabbit_identifier' => $task->rabbit?->identifier,
            'location_id' => $task->location_id,
            'location_name' => $task->location?->name,
        ];
    }
}
