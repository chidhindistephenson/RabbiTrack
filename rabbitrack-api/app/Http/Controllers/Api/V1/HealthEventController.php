<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Farm;
use App\Models\HealthEvent;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

class HealthEventController extends Controller
{
    public function index(Request $request, Farm $farm): JsonResponse
    {
        $this->authorizeFarmAccess($request, $farm);

        $validated = $request->validate([
            'rabbit_id' => ['nullable', 'uuid'],
        ]);

        $events = $farm->healthEvents()
            ->with(['rabbit', 'treatments'])
            ->when($validated['rabbit_id'] ?? null, fn ($query, string $rabbitId) => $query->where('rabbit_id', $rabbitId))
            ->orderByDesc('observed_on')
            ->limit(100)
            ->get()
            ->map(fn (HealthEvent $event) => $this->healthPayload($event));

        return response()->json(['data' => $events]);
    }

    public function store(Request $request, Farm $farm): JsonResponse
    {
        $this->authorizeFarmAccess($request, $farm);

        $validated = $request->validate([
            'rabbit_id' => ['required', 'uuid', 'exists:rabbits,id'],
            'observed_on' => ['required', 'date'],
            'symptoms' => ['required', 'string', 'max:255'],
            'diagnosis' => ['nullable', 'string', 'max:255'],
            'severity' => ['required', 'string', Rule::in(HealthEvent::SEVERITIES)],
            'body_system' => ['nullable', 'string', 'max:120'],
            'isolation_required' => ['nullable', 'boolean'],
            'notes' => ['nullable', 'string', 'max:2000'],
        ]);

        $rabbit = $farm->rabbits()->whereKey($validated['rabbit_id'])->first();
        if (! $rabbit) {
            throw ValidationException::withMessages([
                'rabbit_id' => ['The selected rabbit does not belong to this farm.'],
            ]);
        }

        if ($this->isTerminalRabbitStatus($rabbit->status)) {
            throw ValidationException::withMessages([
                'rabbit_id' => ['This rabbit is no longer active on the farm.'],
            ]);
        }

        $event = $farm->healthEvents()->create([
            'rabbit_id' => $rabbit->id,
            'recorded_by_id' => $request->user()->id,
            'observed_on' => $validated['observed_on'],
            'symptoms' => $validated['symptoms'],
            'diagnosis' => $validated['diagnosis'] ?? null,
            'severity' => $validated['severity'],
            'body_system' => $validated['body_system'] ?? null,
            'isolation_required' => (bool) ($validated['isolation_required'] ?? false),
            'status' => 'open',
            'notes' => $validated['notes'] ?? null,
        ]);

        $rabbit->update([
            'status' => $event->isolation_required ? 'quarantined' : 'under_treatment',
        ]);

        return response()->json([
            'data' => $this->healthPayload($event->load(['rabbit', 'treatments'])),
        ], 201);
    }

    public function storeTreatment(Request $request, Farm $farm, HealthEvent $healthEvent): JsonResponse
    {
        $this->authorizeFarmAccess($request, $farm);
        abort_unless($healthEvent->farm_id === $farm->id, 404);

        $validated = $request->validate([
            'medication' => ['required', 'string', 'max:160'],
            'dosage' => ['nullable', 'string', 'max:120'],
            'route' => ['nullable', 'string', 'max:120'],
            'frequency' => ['nullable', 'string', 'max:120'],
            'started_on' => ['required', 'date'],
            'ended_on' => ['nullable', 'date'],
            'withdrawal_days' => ['nullable', 'integer', 'min:0', 'max:365'],
            'notes' => ['nullable', 'string', 'max:2000'],
        ]);

        $startedOn = Carbon::parse($validated['started_on']);
        $withdrawalDays = (int) ($validated['withdrawal_days'] ?? 0);

        $treatment = $farm->treatments()->create([
            'health_event_id' => $healthEvent->id,
            'rabbit_id' => $healthEvent->rabbit_id,
            'prescribed_by_id' => $request->user()->id,
            'medication' => $validated['medication'],
            'dosage' => $validated['dosage'] ?? null,
            'route' => $validated['route'] ?? null,
            'frequency' => $validated['frequency'] ?? null,
            'started_on' => $startedOn->toDateString(),
            'ended_on' => $validated['ended_on'] ?? null,
            'withdrawal_days' => $withdrawalDays,
            'withdrawal_ends_on' => $withdrawalDays > 0
                ? $startedOn->copy()->addDays($withdrawalDays)->toDateString()
                : null,
            'status' => 'active',
            'notes' => $validated['notes'] ?? null,
        ]);

        $healthEvent->rabbit()->update(['status' => 'under_treatment']);

        return response()->json([
            'data' => [
                'id' => $treatment->id,
                'health_event_id' => $treatment->health_event_id,
                'rabbit_id' => $treatment->rabbit_id,
                'medication' => $treatment->medication,
                'dosage' => $treatment->dosage,
                'route' => $treatment->route,
                'frequency' => $treatment->frequency,
                'started_on' => $treatment->started_on->toDateString(),
                'withdrawal_days' => $treatment->withdrawal_days,
                'withdrawal_ends_on' => $treatment->withdrawal_ends_on?->toDateString(),
                'status' => $treatment->status,
            ],
        ], 201);
    }

    public function update(Request $request, Farm $farm, HealthEvent $healthEvent): JsonResponse
    {
        $this->authorizeFarmAccess($request, $farm);
        abort_unless($healthEvent->farm_id === $farm->id, 404);

        $validated = $request->validate([
            'action' => ['required', 'string', Rule::in(['monitor', 'resolve', 'close'])],
        ]);

        if ($validated['action'] === 'monitor') {
            $healthEvent->update(['status' => 'monitoring']);
        }

        if (in_array($validated['action'], ['resolve', 'close'], true)) {
            $healthEvent->update([
                'status' => $validated['action'] === 'resolve' ? 'resolved' : 'closed',
            ]);

            $healthEvent->treatments()
                ->where('status', 'active')
                ->update([
                    'status' => 'completed',
                    'ended_on' => now()->toDateString(),
                ]);

            $rabbit = $healthEvent->rabbit;
            if ($rabbit && in_array($rabbit->status, ['under_treatment', 'quarantined'], true)) {
                $rabbit->update(['status' => 'resting']);
            }
        }

        return response()->json([
            'data' => $this->healthPayload($healthEvent->fresh(['rabbit', 'treatments'])),
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

    private function healthPayload(HealthEvent $event): array
    {
        return [
            'id' => $event->id,
            'rabbit_id' => $event->rabbit_id,
            'rabbit_identifier' => $event->rabbit?->identifier,
            'observed_on' => $event->observed_on?->toDateString(),
            'symptoms' => $event->symptoms,
            'diagnosis' => $event->diagnosis,
            'severity' => $event->severity,
            'body_system' => $event->body_system,
            'isolation_required' => $event->isolation_required,
            'status' => $event->status,
            'treatments_count' => $event->treatments?->count() ?? 0,
            'notes' => $event->notes,
        ];
    }

    private function isTerminalRabbitStatus(string $status): bool
    {
        return in_array($status, ['sold', 'retired', 'deceased', 'culled'], true);
    }
}
