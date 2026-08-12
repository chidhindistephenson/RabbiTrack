<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Farm;
use App\Models\Location;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

class LocationController extends Controller
{
    public function index(Request $request, Farm $farm): JsonResponse
    {
        $this->authorizeFarmAccess($request, $farm);

        $locations = $farm->locations()
            ->withCount('currentRabbits')
            ->orderBy('type')
            ->orderBy('name')
            ->get()
            ->map(fn (Location $location) => $this->locationPayload($location));

        return response()->json([
            'data' => $locations,
        ]);
    }

    public function store(Request $request, Farm $farm): JsonResponse
    {
        $this->authorizeFarmAccess($request, $farm);
        $this->normalizeStoreInput($request);

        $validated = $request->validate([
            'parent_id' => ['nullable', 'uuid', 'exists:locations,id'],
            'type' => ['required', 'string', Rule::in(Location::TYPES)],
            'name' => ['required', 'string', 'max:120'],
            'code' => [
                'nullable',
                'string',
                'max:60',
                Rule::unique('locations', 'code')->where('farm_id', $farm->id),
            ],
            'capacity' => ['nullable', 'integer', 'min:1', 'max:100000'],
            'is_active' => ['nullable', 'boolean'],
            'notes' => ['nullable', 'string', 'max:2000'],
        ]);

        if (isset($validated['parent_id'])) {
            $parentBelongsToFarm = Location::query()
                ->whereKey($validated['parent_id'])
                ->where('farm_id', $farm->id)
                ->exists();

            if (! $parentBelongsToFarm) {
                throw ValidationException::withMessages([
                    'parent_id' => ['The selected parent location does not belong to this farm.'],
                ]);
            }
        }

        $validated['is_active'] = $validated['is_active'] ?? true;
        $location = $farm->locations()->create($validated);

        return response()->json([
            'data' => $this->locationPayload($location),
        ], 201);
    }

    private function normalizeStoreInput(Request $request): void
    {
        $normalized = [];

        foreach (['name', 'code', 'notes'] as $field) {
            if (! $request->has($field) || ! is_string($request->input($field))) {
                continue;
            }

            $value = trim($request->input($field));
            $normalized[$field] = $value === '' ? null : $value;
        }

        if (isset($normalized['code'])) {
            $normalized['code'] = strtoupper($normalized['code']);
        }

        $request->merge($normalized);
    }

    public function show(Request $request, Farm $farm, Location $location): JsonResponse
    {
        $this->authorizeFarmAccess($request, $farm);
        abort_unless($location->farm_id === $farm->id, 404);

        $location->load([
            'currentRabbits' => fn ($query) => $query->orderBy('identifier'),
        ])->loadCount('currentRabbits');

        return response()->json([
            'data' => $this->locationPayload($location) + [
                'rabbits' => $location->currentRabbits->map(fn ($rabbit) => [
                    'id' => $rabbit->id,
                    'identifier' => $rabbit->identifier,
                    'name' => $rabbit->name,
                    'sex' => $rabbit->sex,
                    'status' => $rabbit->status,
                    'breed' => $rabbit->breed,
                ]),
            ],
        ]);
    }

    public function update(Request $request, Farm $farm, Location $location): JsonResponse
    {
        $this->authorizeFarmAccess($request, $farm);
        abort_unless($location->farm_id === $farm->id, 404);
        $this->normalizeStoreInput($request);

        $validated = $request->validate([
            'type' => ['required', 'string', Rule::in(Location::TYPES)],
            'name' => ['required', 'string', 'max:120'],
            'code' => [
                'nullable',
                'string',
                'max:60',
                Rule::unique('locations', 'code')
                    ->where('farm_id', $farm->id)
                    ->ignore($location->id),
            ],
            'capacity' => ['nullable', 'integer', 'min:1', 'max:100000'],
            'is_active' => ['required', 'boolean'],
            'notes' => ['nullable', 'string', 'max:2000'],
        ]);

        $occupiedCount = $location->currentRabbits()->count();

        if (
            isset($validated['capacity'])
            && $validated['capacity'] < $occupiedCount
        ) {
            throw ValidationException::withMessages([
                'capacity' => ['Capacity cannot be lower than the current occupancy.'],
            ]);
        }

        if (! $validated['is_active'] && $occupiedCount > 0) {
            throw ValidationException::withMessages([
                'is_active' => ['Move assigned rabbits before deactivating this location.'],
            ]);
        }

        $location->update($validated);

        return response()->json([
            'data' => $this->locationPayload($location->fresh()->loadCount('currentRabbits')),
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

    private function locationPayload(Location $location): array
    {
        return [
            'id' => $location->id,
            'farm_id' => $location->farm_id,
            'parent_id' => $location->parent_id,
            'type' => $location->type,
            'name' => $location->name,
            'code' => $location->code,
            'capacity' => $location->capacity,
            'occupied_count' => $location->current_rabbits_count
                ?? $location->currentRabbits()->count(),
            'is_active' => $location->is_active,
            'notes' => $location->notes,
        ];
    }
}
