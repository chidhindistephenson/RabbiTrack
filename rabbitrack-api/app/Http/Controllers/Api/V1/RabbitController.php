<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Farm;
use App\Models\Litter;
use App\Models\Location;
use App\Models\Rabbit;
use Illuminate\Database\QueryException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

class RabbitController extends Controller
{
    public function index(Request $request, Farm $farm): JsonResponse
    {
        $this->authorizeFarmAccess($request, $farm);

        $validated = $request->validate([
            'search' => ['nullable', 'string', 'max:120'],
            'sex' => ['nullable', 'string', Rule::in(Rabbit::SEXES)],
            'status' => ['nullable', 'string', Rule::in(Rabbit::STATUSES)],
            'breed' => ['nullable', 'string', 'max:120'],
            'location_id' => ['nullable', 'uuid'],
        ]);

        $rabbits = $farm->rabbits()
            ->with('currentLocation')
            ->when($validated['search'] ?? null, function ($query, string $search): void {
                $normalizedSearch = strtolower($search);

                $query->where(function ($query) use ($normalizedSearch): void {
                    $query
                        ->whereRaw('LOWER(identifier) LIKE ?', ["%{$normalizedSearch}%"])
                        ->orWhereRaw('LOWER(name) LIKE ?', ["%{$normalizedSearch}%"])
                        ->orWhereRaw('LOWER(breed) LIKE ?', ["%{$normalizedSearch}%"])
                        ->orWhereRaw('LOWER(tag_or_tattoo) LIKE ?', ["%{$normalizedSearch}%"]);
                });
            })
            ->when($validated['sex'] ?? null, fn ($query, string $sex) => $query->where('sex', $sex))
            ->when($validated['status'] ?? null, fn ($query, string $status) => $query->where('status', $status))
            ->when($validated['breed'] ?? null, fn ($query, string $breed) => $query->where('breed', $breed))
            ->when($validated['location_id'] ?? null, fn ($query, string $locationId) => $query->where('current_location_id', $locationId))
            ->orderBy('identifier')
            ->limit(100)
            ->get()
            ->map(fn (Rabbit $rabbit) => $this->rabbitPayload($rabbit));

        return response()->json([
            'data' => $rabbits,
        ]);
    }

    public function store(Request $request, Farm $farm): JsonResponse
    {
        $this->authorizeFarmAccess($request, $farm);
        $this->normalizeStoreInput($request);

        $validated = $request->validate([
            'identifier' => [
                'nullable',
                'string',
                'max:60',
                Rule::unique('rabbits', 'identifier')->where('farm_id', $farm->id),
            ],
            'name' => ['nullable', 'string', 'max:120'],
            'sex' => ['required', 'string', Rule::in(Rabbit::SEXES)],
            'date_of_birth' => ['nullable', 'date'],
            'breed' => ['nullable', 'string', 'max:120'],
            'colour' => ['nullable', 'string', 'max:120'],
            'markings' => ['nullable', 'string', 'max:255'],
            'weight_value' => ['nullable', 'numeric', 'min:0', 'max:99999'],
            'weight_unit' => ['nullable', 'string', 'max:10'],
            'tag_or_tattoo' => ['nullable', 'string', 'max:120'],
            'status' => ['required', 'string', Rule::in(Rabbit::STATUSES)],
            'current_location_id' => ['nullable', 'uuid', 'exists:locations,id'],
            'mother_id' => ['nullable', 'uuid', 'exists:rabbits,id'],
            'father_id' => ['nullable', 'uuid', 'exists:rabbits,id'],
            'origin_type' => ['nullable', 'string', Rule::in(Rabbit::ORIGIN_TYPES)],
            'origin_litter_id' => ['nullable', 'uuid', 'exists:litters,id'],
            'is_farm_born' => ['nullable', 'boolean'],
            'supplier' => ['nullable', 'string', 'max:160'],
            'acquired_at' => ['nullable', 'date'],
            'acquisition_cost' => ['nullable', 'numeric', 'min:0', 'max:999999999'],
            'notes' => ['nullable', 'string', 'max:2000'],
        ]);

        $this->assertFarmOwnedReferences($farm, $validated);
        $this->assertParentReferences($farm, $validated);
        $this->normalizeOriginAttributes($farm, $validated);
        $this->assertStatusAllowedForSex($validated['sex'], $validated['status']);
        $this->assertSoldStatusUsesSaleFlow($validated['status']);

        $validated['weight_unit'] = $validated['weight_unit'] ?? 'kg';
        $shouldGenerateIdentifier = empty($validated['identifier']);

        $rabbit = $this->createRabbitWithRetry(
            request: $request,
            farm: $farm,
            attributes: $validated,
            shouldGenerateIdentifier: $shouldGenerateIdentifier,
        );

        return response()->json([
            'data' => $this->rabbitPayload($rabbit->load('currentLocation')),
        ], 201);
    }

    public function show(Request $request, Farm $farm, Rabbit $rabbit): JsonResponse
    {
        $this->authorizeFarmAccess($request, $farm);
        abort_unless($rabbit->farm_id === $farm->id, 404);

        $rabbit->load([
            'currentLocation',
            'mother:id,identifier,name',
            'father:id,identifier,name',
            'movements.fromLocation',
            'movements.toLocation',
        ]);

        return response()->json([
            'data' => $this->rabbitPayload($rabbit) + [
                'mother' => $rabbit->mother ? $this->parentPayload($rabbit->mother) : null,
                'father' => $rabbit->father ? $this->parentPayload($rabbit->father) : null,
                'movements' => $rabbit->movements
                    ->sortByDesc('moved_at')
                    ->values()
                    ->map(fn ($movement) => [
                        'id' => $movement->id,
                        'from_location' => $movement->fromLocation?->name,
                        'to_location' => $movement->toLocation?->name,
                        'moved_at' => $movement->moved_at?->toISOString(),
                        'reason' => $movement->reason,
                        'notes' => $movement->notes,
                    ]),
            ],
        ]);
    }

    public function move(Request $request, Farm $farm, Rabbit $rabbit): JsonResponse
    {
        $this->authorizeFarmAccess($request, $farm);
        abort_unless($rabbit->farm_id === $farm->id, 404);

        $validated = $request->validate([
            'to_location_id' => ['required', 'uuid', 'exists:locations,id'],
            'moved_at' => ['nullable', 'date'],
            'reason' => ['nullable', 'string', 'max:160'],
            'notes' => ['nullable', 'string', 'max:2000'],
        ]);

        $toLocation = $farm->locations()
            ->whereKey($validated['to_location_id'])
            ->first();

        if (! $toLocation) {
            throw ValidationException::withMessages([
                'to_location_id' => ['The selected location does not belong to this farm.'],
            ]);
        }

        if (! $toLocation->is_active) {
            throw ValidationException::withMessages([
                'to_location_id' => ['The selected location is inactive.'],
            ]);
        }

        if ($rabbit->current_location_id === $toLocation->id) {
            throw ValidationException::withMessages([
                'to_location_id' => ['The rabbit is already in this location.'],
            ]);
        }

        if ($this->isTerminalRabbitStatus($rabbit->status)) {
            throw ValidationException::withMessages([
                'rabbit_id' => ['This rabbit is no longer active on the farm.'],
            ]);
        }

        $movement = DB::transaction(function () use ($request, $farm, $rabbit, $validated) {
            $movement = $rabbit->movements()->create([
                'farm_id' => $farm->id,
                'from_location_id' => $rabbit->current_location_id,
                'to_location_id' => $validated['to_location_id'],
                'user_id' => $request->user()->id,
                'moved_at' => $validated['moved_at'] ?? now(),
                'reason' => $validated['reason'] ?? 'Location change',
                'notes' => $validated['notes'] ?? null,
            ]);

            $rabbit->update([
                'current_location_id' => $validated['to_location_id'],
            ]);

            return $movement;
        });

        return response()->json([
            'data' => [
                'id' => $movement->id,
                'rabbit_id' => $movement->rabbit_id,
                'from_location_id' => $movement->from_location_id,
                'to_location_id' => $movement->to_location_id,
                'moved_at' => $movement->moved_at?->toISOString(),
                'reason' => $movement->reason,
                'notes' => $movement->notes,
            ],
        ], 201);
    }

    public function update(Request $request, Farm $farm, Rabbit $rabbit): JsonResponse
    {
        $this->authorizeFarmAccess($request, $farm);
        abort_unless($rabbit->farm_id === $farm->id, 404);
        $this->normalizeStoreInput($request);

        $validated = $request->validate([
            'status' => ['required', 'string', Rule::in(Rabbit::STATUSES)],
            'name' => ['nullable', 'string', 'max:120'],
            'sex' => ['nullable', 'string', Rule::in(Rabbit::SEXES)],
            'date_of_birth' => ['nullable', 'date'],
            'breed' => ['nullable', 'string', 'max:120'],
            'colour' => ['nullable', 'string', 'max:120'],
            'markings' => ['nullable', 'string', 'max:255'],
            'weight_value' => ['nullable', 'numeric', 'min:0', 'max:99999'],
            'weight_unit' => ['nullable', 'string', 'max:10'],
            'tag_or_tattoo' => ['nullable', 'string', 'max:120'],
            'current_location_id' => ['nullable', 'uuid', 'exists:locations,id'],
            'mother_id' => ['nullable', 'uuid', 'exists:rabbits,id'],
            'father_id' => ['nullable', 'uuid', 'exists:rabbits,id'],
            'notes' => ['nullable', 'string', 'max:2000'],
        ]);

        $this->assertFarmOwnedReferences($farm, $validated);
        $this->assertParentReferences($farm, $validated, $rabbit);
        $this->assertStatusAllowedForSex($validated['sex'] ?? $rabbit->sex, $validated['status']);
        $this->assertTerminalRabbitProfileIsLocked($rabbit);
        $this->assertSoldStatusUsesSaleFlow($validated['status']);
        $this->assertSaleReadinessAllowed($rabbit, $validated['status']);
        $this->assertSexChangeKeepsExistingParentLinksValid($farm, $rabbit, $validated['sex'] ?? $rabbit->sex);

        $editableFields = [
            'name',
            'sex',
            'date_of_birth',
            'breed',
            'colour',
            'markings',
            'weight_value',
            'weight_unit',
            'tag_or_tattoo',
            'status',
            'current_location_id',
            'mother_id',
            'father_id',
            'notes',
        ];
        $updates = array_intersect_key($validated, array_flip($editableFields));

        if (array_key_exists('weight_value', $updates) && $updates['weight_value'] === null) {
            $updates['weight_unit'] = $rabbit->weight_unit ?? 'kg';
        } elseif (array_key_exists('weight_value', $updates) && ! array_key_exists('weight_unit', $updates)) {
            $updates['weight_unit'] = $rabbit->weight_unit ?? 'kg';
        }

        $rabbit->update($updates);

        return response()->json([
            'data' => $this->rabbitPayload($rabbit->fresh('currentLocation')),
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

    private function assertFarmOwnedReferences(Farm $farm, array $validated): void
    {
        foreach ([
            'current_location_id' => Location::class,
            'mother_id' => Rabbit::class,
            'father_id' => Rabbit::class,
            'origin_litter_id' => Litter::class,
        ] as $field => $model) {
            if (! isset($validated[$field])) {
                continue;
            }

            $belongsToFarm = $model::query()
                ->whereKey($validated[$field])
                ->where('farm_id', $farm->id)
                ->exists();

            if (! $belongsToFarm) {
                throw ValidationException::withMessages([
                    $field => ['The selected record does not belong to this farm.'],
                ]);
            }
        }
    }

    private function assertParentReferences(Farm $farm, array $validated, ?Rabbit $rabbit = null): void
    {
        $errors = [];
        $motherId = $validated['mother_id'] ?? null;
        $fatherId = $validated['father_id'] ?? null;

        if ($motherId !== null && $motherId === $rabbit?->id) {
            $errors['mother_id'][] = 'A rabbit cannot be its own mother.';
        }

        if ($fatherId !== null && $fatherId === $rabbit?->id) {
            $errors['father_id'][] = 'A rabbit cannot be its own father.';
        }

        if ($motherId !== null && $fatherId !== null && $motherId === $fatherId) {
            $errors['father_id'][] = 'Mother and father must be different rabbits.';
        }

        if ($motherId !== null && ! $this->farmRabbitHasSex($farm, $motherId, 'female')) {
            $errors['mother_id'][] = 'The selected mother must be a female rabbit.';
        }

        if ($fatherId !== null && ! $this->farmRabbitHasSex($farm, $fatherId, 'male')) {
            $errors['father_id'][] = 'The selected father must be a male rabbit.';
        }

        if (
            $motherId !== null
            && $motherId !== $rabbit?->mother_id
            && ! $this->farmRabbitIsActive($farm, $motherId)
        ) {
            $errors['mother_id'][] = 'The selected mother is no longer active on the farm.';
        }

        if (
            $fatherId !== null
            && $fatherId !== $rabbit?->father_id
            && ! $this->farmRabbitIsActive($farm, $fatherId)
        ) {
            $errors['father_id'][] = 'The selected father is no longer active on the farm.';
        }

        if ($errors !== []) {
            throw ValidationException::withMessages($errors);
        }
    }

    private function farmRabbitHasSex(Farm $farm, string $rabbitId, string $sex): bool
    {
        return $farm->rabbits()
            ->whereKey($rabbitId)
            ->where('sex', $sex)
            ->exists();
    }

    private function farmRabbitIsActive(Farm $farm, string $rabbitId): bool
    {
        return $farm->rabbits()
            ->whereKey($rabbitId)
            ->whereNotIn('status', ['sold', 'retired', 'deceased', 'culled'])
            ->exists();
    }

    private function assertSexChangeKeepsExistingParentLinksValid(Farm $farm, Rabbit $rabbit, string $sex): void
    {
        $errors = [];

        if (
            $sex !== 'female'
            && $farm->rabbits()->where('mother_id', $rabbit->id)->exists()
        ) {
            $errors['sex'][] = 'This rabbit is already recorded as a mother and must remain female.';
        }

        if (
            $sex !== 'male'
            && $farm->rabbits()->where('father_id', $rabbit->id)->exists()
        ) {
            $errors['sex'][] = 'This rabbit is already recorded as a father and must remain male.';
        }

        if ($errors !== []) {
            throw ValidationException::withMessages($errors);
        }
    }

    private function normalizeStoreInput(Request $request): void
    {
        $fields = [
            'identifier',
            'name',
            'breed',
            'colour',
            'markings',
            'weight_unit',
            'tag_or_tattoo',
            'origin_type',
            'supplier',
            'notes',
        ];

        $normalized = [];

        foreach ($fields as $field) {
            if (! $request->has($field) || ! is_string($request->input($field))) {
                continue;
            }

            $value = trim($request->input($field));
            $normalized[$field] = $value === '' ? null : $value;
        }

        if (isset($normalized['identifier'])) {
            $normalized['identifier'] = strtoupper($normalized['identifier']);
        }

        $request->merge($normalized);
    }

    private function assertStatusAllowedForSex(string $sex, string $status): void
    {
        if ($sex !== 'male' || ! in_array($status, ['pregnant', 'nursing'], true)) {
            return;
        }

        throw ValidationException::withMessages([
            'status' => ['Male rabbits cannot be marked as pregnant or nursing.'],
        ]);
    }

    private function assertSoldStatusUsesSaleFlow(string $status): void
    {
        if ($status !== 'sold') {
            return;
        }

        throw ValidationException::withMessages([
            'status' => ['Record a sale to mark this rabbit as sold.'],
        ]);
    }

    private function assertSaleReadinessAllowed(Rabbit $rabbit, string $status): void
    {
        if ($status !== 'ready_for_sale') {
            return;
        }

        if (in_array($rabbit->status, ['under_treatment', 'quarantined'], true)) {
            throw ValidationException::withMessages([
                'status' => ['Resolve treatment or quarantine before marking this rabbit ready for sale.'],
            ]);
        }

        if (
            $rabbit->healthEvents()
                ->whereIn('status', ['open', 'monitoring'])
                ->exists()
        ) {
            throw ValidationException::withMessages([
                'status' => ['Resolve active health events before marking this rabbit ready for sale.'],
            ]);
        }

        $settings = $rabbit->farm?->settings ?? [];
        $minAgeDays = (int) ($settings['sale_ready_min_age_days'] ?? 0);
        if ($minAgeDays > 0) {
            if ($rabbit->date_of_birth === null) {
                throw ValidationException::withMessages([
                    'status' => ['Record date of birth before marking this rabbit ready for sale.'],
                ]);
            }

            if ($rabbit->date_of_birth->diffInDays(Carbon::today()) < $minAgeDays) {
                throw ValidationException::withMessages([
                    'status' => ["Rabbit must be at least {$minAgeDays} days old before sale readiness."],
                ]);
            }
        }

        $minWeightKg = $settings['sale_ready_min_weight_kg'] ?? null;
        if ($minWeightKg !== null && (float) $minWeightKg > 0) {
            if ($rabbit->weight_value === null) {
                throw ValidationException::withMessages([
                    'status' => ['Record current weight before marking this rabbit ready for sale.'],
                ]);
            }

            if ((float) $rabbit->weight_value < (float) $minWeightKg) {
                throw ValidationException::withMessages([
                    'status' => ["Rabbit must weigh at least {$minWeightKg} kg before sale readiness."],
                ]);
            }
        }

        $withdrawal = $rabbit->treatments()
            ->whereNotNull('withdrawal_ends_on')
            ->whereDate('withdrawal_ends_on', '>=', Carbon::today()->toDateString())
            ->orderByDesc('withdrawal_ends_on')
            ->first();

        if ($withdrawal) {
            throw ValidationException::withMessages([
                'status' => [
                    "This rabbit is under medicine withdrawal until {$withdrawal->withdrawal_ends_on->toDateString()}.",
                ],
            ]);
        }
    }

    private function normalizeOriginAttributes(Farm $farm, array &$validated): void
    {
        $originType = $validated['origin_type'] ?? null;

        if ($originType === null) {
            $originType = array_key_exists('is_farm_born', $validated)
                ? ($validated['is_farm_born'] ? 'born_on_farm' : 'purchased')
                : 'existing_stock';
        }

        if ($originType === 'born_on_farm') {
            if (empty($validated['origin_litter_id'])) {
                throw ValidationException::withMessages([
                    'origin_litter_id' => ['Select the litter this rabbit came from.'],
                ]);
            }

            $litter = $farm->litters()
                ->whereKey($validated['origin_litter_id'])
                ->firstOrFail();

            if (! in_array($litter->status, ['partially_weaned', 'weaned'], true)) {
                throw ValidationException::withMessages([
                    'origin_litter_id' => ['Kits can be converted after the litter has been weaned.'],
                ]);
            }

            $validated['mother_id'] = $litter->doe_id;
            $validated['father_id'] = $litter->buck_id;
            $validated['date_of_birth'] = $validated['date_of_birth'] ?? $litter->kindled_on?->toDateString();
            $validated['is_farm_born'] = true;
            $validated['supplier'] = null;
            $validated['acquisition_cost'] = null;
            $validated['acquired_at'] = $validated['acquired_at'] ?? now()->toDateString();
        } else {
            $validated['origin_litter_id'] = null;
            $validated['is_farm_born'] = false;
        }

        if ($originType === 'existing_stock') {
            $validated['is_farm_born'] = $validated['is_farm_born'] ?? false;
        }

        $validated['origin_type'] = $originType;
    }

    private function assertTerminalRabbitProfileIsLocked(Rabbit $rabbit): void
    {
        if (! $this->isTerminalRabbitStatus($rabbit->status)) {
            return;
        }

        throw ValidationException::withMessages([
            'status' => ['This rabbit is no longer active on the farm.'],
        ]);
    }

    private function isTerminalRabbitStatus(string $status): bool
    {
        return in_array($status, ['sold', 'retired', 'deceased', 'culled'], true);
    }

    private function rabbitPayload(Rabbit $rabbit): array
    {
        return [
            'id' => $rabbit->id,
            'farm_id' => $rabbit->farm_id,
            'identifier' => $rabbit->identifier,
            'name' => $rabbit->name,
            'sex' => $rabbit->sex,
            'date_of_birth' => $rabbit->date_of_birth?->toDateString(),
            'breed' => $rabbit->breed,
            'colour' => $rabbit->colour,
            'markings' => $rabbit->markings,
            'weight_value' => $rabbit->weight_value,
            'weight_unit' => $rabbit->weight_unit,
            'tag_or_tattoo' => $rabbit->tag_or_tattoo,
            'status' => $rabbit->status,
            'current_location_id' => $rabbit->current_location_id,
            'current_location_name' => $rabbit->currentLocation?->name,
            'mother_id' => $rabbit->mother_id,
            'father_id' => $rabbit->father_id,
            'origin_type' => $rabbit->origin_type,
            'origin_litter_id' => $rabbit->origin_litter_id,
            'is_farm_born' => $rabbit->is_farm_born,
            'supplier' => $rabbit->supplier,
            'acquired_at' => $rabbit->acquired_at?->toDateString(),
            'acquisition_cost' => $rabbit->acquisition_cost,
            'notes' => $rabbit->notes,
        ];
    }

    private function createRabbitWithRetry(
        Request $request,
        Farm $farm,
        array $attributes,
        bool $shouldGenerateIdentifier,
    ): Rabbit {
        $attempts = $shouldGenerateIdentifier ? 5 : 1;

        for ($attempt = 1; $attempt <= $attempts; $attempt++) {
            if ($shouldGenerateIdentifier) {
                $attributes['identifier'] = $this->nextRabbitIdentifier($farm, $attributes['sex']);
            }

            $attributes['tag_or_tattoo'] ??= $attributes['identifier'];

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
                            'reason' => 'Initial registration',
                        ]);
                    }

                    return $rabbit;
                });
            } catch (QueryException $exception) {
                if (
                    ! $shouldGenerateIdentifier ||
                    ! $this->isUniqueIdentifierCollision($exception) ||
                    $attempt === $attempts
                ) {
                    throw $exception;
                }
            }
        }

        throw ValidationException::withMessages([
            'identifier' => ['A rabbit identifier could not be assigned. Try again.'],
        ]);
    }

    private function parentPayload(Rabbit $rabbit): array
    {
        return [
            'id' => $rabbit->id,
            'identifier' => $rabbit->identifier,
            'name' => $rabbit->name,
        ];
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
