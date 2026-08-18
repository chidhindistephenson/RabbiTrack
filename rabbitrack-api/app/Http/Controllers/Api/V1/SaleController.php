<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Farm;
use App\Models\Rabbit;
use App\Models\Sale;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class SaleController extends Controller
{
    public function index(Request $request, Farm $farm): JsonResponse
    {
        $this->authorizeFarmAccess($request, $farm);

        $validated = $request->validate([
            'rabbit_id' => ['nullable', 'uuid'],
        ]);

        $sales = $farm->sales()
            ->with('rabbit')
            ->when($validated['rabbit_id'] ?? null, fn ($query, string $rabbitId) => $query->where('rabbit_id', $rabbitId))
            ->orderByDesc('sold_on')
            ->limit(100)
            ->get()
            ->map(fn (Sale $sale) => $this->salePayload($sale));

        return response()->json(['data' => $sales]);
    }

    public function summary(Request $request, Farm $farm): JsonResponse
    {
        $this->authorizeFarmAccess($request, $farm);

        $totalRevenue = (float) $farm->sales()->sum('sale_price');
        $saleCount = $farm->sales()->count();

        return response()->json([
            'data' => [
                'total_revenue' => number_format($totalRevenue, 2, '.', ''),
                'sale_count' => $saleCount,
                'average_sale' => number_format($saleCount === 0 ? 0 : $totalRevenue / $saleCount, 2, '.', ''),
                'currency' => $farm->currency,
            ],
        ]);
    }

    public function store(Request $request, Farm $farm): JsonResponse
    {
        $this->authorizeFarmAccess($request, $farm);
        $this->normalizeStoreInput($request);

        $validated = $request->validate([
            'rabbit_id' => ['required', 'uuid', 'exists:rabbits,id'],
            'buyer_name' => ['nullable', 'string', 'max:160'],
            'buyer_phone' => ['nullable', 'string', 'max:80'],
            'sold_on' => ['required', 'date'],
            'sale_price' => ['required', 'numeric', 'min:0.01', 'max:999999999'],
            'currency' => ['nullable', 'string', 'size:3'],
            'notes' => ['nullable', 'string', 'max:2000'],
        ]);

        $rabbit = $farm->rabbits()->whereKey($validated['rabbit_id'])->first();
        if (! $rabbit) {
            throw ValidationException::withMessages([
                'rabbit_id' => ['The selected rabbit does not belong to this farm.'],
            ]);
        }

        if (in_array($rabbit->status, ['sold', 'retired', 'deceased', 'culled'], true)) {
            throw ValidationException::withMessages([
                'rabbit_id' => ['The selected rabbit is not eligible for sale.'],
            ]);
        }

        $this->assertSaleAllowed($rabbit, Carbon::parse($validated['sold_on']));

        $sale = DB::transaction(function () use ($request, $farm, $rabbit, $validated) {
            $sale = $farm->sales()->create([
                'rabbit_id' => $rabbit->id,
                'sold_by_id' => $request->user()->id,
                'buyer_name' => $validated['buyer_name'] ?? null,
                'buyer_phone' => $validated['buyer_phone'] ?? null,
                'sold_on' => $validated['sold_on'],
                'sale_price' => $validated['sale_price'],
                'currency' => $validated['currency'] ?? $farm->currency,
                'notes' => $validated['notes'] ?? null,
            ]);

            $rabbit->update([
                'status' => 'sold',
                'current_location_id' => null,
            ]);

            $farm->activityLogs()->create([
                'user_id' => $request->user()->id,
                'action' => 'sale.recorded',
                'description' => "Recorded sale for {$rabbit->identifier}.",
                'metadata' => [
                    'sale_id' => $sale->id,
                    'rabbit_id' => $rabbit->id,
                    'amount' => $sale->sale_price,
                    'currency' => $sale->currency,
                ],
            ]);

            return $sale;
        });

        return response()->json([
            'data' => $this->salePayload($sale->load('rabbit')),
        ], 201);
    }

    private function normalizeStoreInput(Request $request): void
    {
        $normalized = [];

        foreach (['buyer_name', 'buyer_phone', 'currency', 'notes'] as $field) {
            if (! $request->has($field) || ! is_string($request->input($field))) {
                continue;
            }

            $value = trim($request->input($field));
            $normalized[$field] = $value === '' ? null : $value;
        }

        if (isset($normalized['currency'])) {
            $normalized['currency'] = strtoupper($normalized['currency']);
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

    private function assertSaleAllowed(Rabbit $rabbit, Carbon $soldOn): void
    {
        if (in_array($rabbit->status, ['under_treatment', 'quarantined'], true)) {
            throw ValidationException::withMessages([
                'rabbit_id' => ['Resolve treatment or quarantine before recording this sale.'],
            ]);
        }

        if (
            $rabbit->healthEvents()
                ->whereIn('status', ['open', 'monitoring'])
                ->exists()
        ) {
            throw ValidationException::withMessages([
                'rabbit_id' => ['Resolve active health events before recording this sale.'],
            ]);
        }

        $settings = $rabbit->farm?->settings ?? [];
        $minAgeDays = (int) ($settings['sale_ready_min_age_days'] ?? 0);
        if ($minAgeDays > 0) {
            if ($rabbit->date_of_birth === null) {
                throw ValidationException::withMessages([
                    'rabbit_id' => ['Record date of birth before recording this sale.'],
                ]);
            }

            if ($rabbit->date_of_birth->diffInDays($soldOn) < $minAgeDays) {
                throw ValidationException::withMessages([
                    'rabbit_id' => ["Rabbit must be at least {$minAgeDays} days old before sale."],
                ]);
            }
        }

        $minWeightKg = $settings['sale_ready_min_weight_kg'] ?? null;
        if ($minWeightKg !== null && (float) $minWeightKg > 0) {
            if ($rabbit->weight_value === null) {
                throw ValidationException::withMessages([
                    'rabbit_id' => ['Record current weight before recording this sale.'],
                ]);
            }

            if ((float) $rabbit->weight_value < (float) $minWeightKg) {
                throw ValidationException::withMessages([
                    'rabbit_id' => ["Rabbit must weigh at least {$minWeightKg} kg before sale."],
                ]);
            }
        }

        $withdrawal = $rabbit->treatments()
            ->whereNotNull('withdrawal_ends_on')
            ->whereDate('withdrawal_ends_on', '>=', $soldOn->toDateString())
            ->orderByDesc('withdrawal_ends_on')
            ->first();

        if ($withdrawal) {
            throw ValidationException::withMessages([
                'rabbit_id' => [
                    "This rabbit is under medicine withdrawal until {$withdrawal->withdrawal_ends_on->toDateString()}.",
                ],
            ]);
        }
    }

    private function salePayload(Sale $sale): array
    {
        return [
            'id' => $sale->id,
            'rabbit_id' => $sale->rabbit_id,
            'rabbit_identifier' => $sale->rabbit?->identifier,
            'buyer_name' => $sale->buyer_name,
            'buyer_phone' => $sale->buyer_phone,
            'sold_on' => $sale->sold_on?->toDateString(),
            'sale_price' => $sale->sale_price,
            'currency' => $sale->currency,
            'notes' => $sale->notes,
        ];
    }
}
