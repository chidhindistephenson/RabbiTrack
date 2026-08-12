<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Farm;
use App\Models\WeightRecord;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;

class WeightRecordController extends Controller
{
    public function index(Request $request, Farm $farm): JsonResponse
    {
        $this->authorizeFarmAccess($request, $farm);

        $validated = $request->validate([
            'rabbit_id' => ['nullable', 'uuid'],
            'litter_id' => ['nullable', 'uuid'],
        ]);

        $records = $farm->weightRecords()
            ->with(['rabbit', 'litter'])
            ->when($validated['rabbit_id'] ?? null, fn ($query, string $rabbitId) => $query->where('rabbit_id', $rabbitId))
            ->when($validated['litter_id'] ?? null, fn ($query, string $litterId) => $query->where('litter_id', $litterId))
            ->orderByDesc('weighed_on')
            ->limit(100)
            ->get()
            ->map(fn (WeightRecord $record) => $this->weightPayload($record));

        return response()->json(['data' => $records]);
    }

    public function store(Request $request, Farm $farm): JsonResponse
    {
        $this->authorizeFarmAccess($request, $farm);
        $this->normalizeStoreInput($request);

        $validated = $request->validate([
            'rabbit_id' => ['nullable', 'uuid', 'exists:rabbits,id'],
            'litter_id' => ['nullable', 'uuid', 'exists:litters,id'],
            'weighed_on' => ['required', 'date'],
            'weight_value' => ['required', 'numeric', 'min:0.001', 'max:99999'],
            'weight_unit' => ['nullable', 'string', 'max:10'],
            'method' => ['nullable', 'string', 'max:120'],
            'notes' => ['nullable', 'string', 'max:2000'],
        ]);

        $targetCount = (int) isset($validated['rabbit_id']) + (int) isset($validated['litter_id']);
        if ($targetCount !== 1) {
            throw ValidationException::withMessages([
                'target' => ['Select exactly one rabbit or litter to weigh.'],
            ]);
        }

        if (isset($validated['rabbit_id'])) {
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
        }

        if (isset($validated['litter_id'])) {
            $litter = $farm->litters()->whereKey($validated['litter_id'])->first();
            if (! $litter) {
                throw ValidationException::withMessages([
                    'litter_id' => ['The selected litter does not belong to this farm.'],
                ]);
            }
        }

        $record = $farm->weightRecords()->create([
            'rabbit_id' => $validated['rabbit_id'] ?? null,
            'litter_id' => $validated['litter_id'] ?? null,
            'recorded_by_id' => $request->user()->id,
            'weighed_on' => $validated['weighed_on'],
            'weight_value' => $validated['weight_value'],
            'weight_unit' => $validated['weight_unit'] ?? 'kg',
            'method' => $validated['method'] ?? null,
            'notes' => $validated['notes'] ?? null,
        ]);

        if (isset($rabbit)) {
            $rabbit->update([
                'weight_value' => $validated['weight_value'],
                'weight_unit' => $validated['weight_unit'] ?? 'kg',
            ]);
        }

        return response()->json([
            'data' => $this->weightPayload($record->load(['rabbit', 'litter'])),
        ], 201);
    }

    private function normalizeStoreInput(Request $request): void
    {
        $normalized = [];

        foreach (['weight_unit', 'method', 'notes'] as $field) {
            if (! $request->has($field) || ! is_string($request->input($field))) {
                continue;
            }

            $value = trim($request->input($field));
            $normalized[$field] = $value === '' ? null : $value;
        }

        $request->merge($normalized);
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

    private function weightPayload(WeightRecord $record): array
    {
        return [
            'id' => $record->id,
            'rabbit_id' => $record->rabbit_id,
            'rabbit_identifier' => $record->rabbit?->identifier,
            'litter_id' => $record->litter_id,
            'litter_identifier' => $record->litter?->identifier,
            'weighed_on' => $record->weighed_on?->toDateString(),
            'weight_value' => $record->weight_value,
            'weight_unit' => $record->weight_unit,
            'method' => $record->method,
            'notes' => $record->notes,
        ];
    }

    private function isTerminalRabbitStatus(string $status): bool
    {
        return in_array($status, ['sold', 'retired', 'deceased', 'culled'], true);
    }
}
