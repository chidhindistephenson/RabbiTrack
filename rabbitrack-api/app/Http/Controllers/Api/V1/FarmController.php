<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Farm;
use App\Models\FarmMembership;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class FarmController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $farms = $request->user()
            ->memberships()
            ->with('farm')
            ->where('is_active', true)
            ->get()
            ->map(fn ($membership) => $this->farmPayload($membership));

        return response()->json([
            'data' => $farms,
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:120'],
            'currency' => ['nullable', 'string', 'size:3'],
            'timezone' => ['nullable', 'string', 'max:80', 'timezone'],
        ]);

        $farm = Farm::query()->create([
            'name' => $validated['name'],
            'code' => $this->uniqueFarmCode($validated['name']),
            'timezone' => $validated['timezone'] ?? 'Africa/Johannesburg',
            'currency' => Str::upper($validated['currency'] ?? 'USD'),
            'settings' => [
                'gestation_days' => 31,
                'pregnancy_check_start_days' => 10,
                'pregnancy_check_end_days' => 14,
                'nest_box_lead_days' => 3,
                'weaning_days' => 35,
                'sale_ready_min_age_days' => 70,
                'sale_ready_min_weight_kg' => 2.0,
                'retirement_review_litter_threshold' => 0,
                'breeding_min_doe_age_days' => 0,
                'breeding_min_buck_age_days' => 0,
            ],
        ]);

        $membership = FarmMembership::query()->create([
            'farm_id' => $farm->id,
            'user_id' => $request->user()->id,
            'role' => 'owner',
            'is_active' => true,
            'joined_at' => now(),
        ])->setRelation('farm', $farm);

        return response()->json([
            'data' => $this->farmPayload($membership),
        ], 201);
    }

    public function update(Request $request, Farm $farm): JsonResponse
    {
        $membership = $this->authorizeFarmOwner($request, $farm);

        $validated = $request->validate([
            'name' => ['required', 'string', 'max:120'],
            'currency' => ['required', 'string', 'size:3'],
            'timezone' => ['required', 'string', 'max:80', 'timezone'],
            'sale_ready_min_age_days' => ['nullable', 'integer', 'min:0', 'max:3650'],
            'sale_ready_min_weight_kg' => ['nullable', 'numeric', 'min:0', 'max:99999'],
            'retirement_review_litter_threshold' => ['nullable', 'integer', 'min:0', 'max:100'],
            'breeding_min_doe_age_days' => ['nullable', 'integer', 'min:0', 'max:3650'],
            'breeding_min_buck_age_days' => ['nullable', 'integer', 'min:0', 'max:3650'],
        ]);

        $settings = $farm->settings ?? [];
        $settings['sale_ready_min_age_days'] = (int) ($validated['sale_ready_min_age_days'] ?? 0);
        $settings['sale_ready_min_weight_kg'] = isset($validated['sale_ready_min_weight_kg'])
            ? (float) $validated['sale_ready_min_weight_kg']
            : null;
        $settings['retirement_review_litter_threshold'] = (int) ($validated['retirement_review_litter_threshold'] ?? 0);
        $settings['breeding_min_doe_age_days'] = (int) ($validated['breeding_min_doe_age_days'] ?? 0);
        $settings['breeding_min_buck_age_days'] = (int) ($validated['breeding_min_buck_age_days'] ?? 0);

        $farm->update([
            'name' => $validated['name'],
            'currency' => Str::upper($validated['currency']),
            'timezone' => $validated['timezone'],
            'settings' => $settings,
        ]);

        $farm->activityLogs()->create([
            'user_id' => $request->user()->id,
            'action' => 'farm.updated',
            'description' => 'Updated farm settings.',
            'metadata' => [
                'name' => $farm->name,
                'currency' => $farm->currency,
                'timezone' => $farm->timezone,
                'sale_ready_min_age_days' => $settings['sale_ready_min_age_days'],
                'sale_ready_min_weight_kg' => $settings['sale_ready_min_weight_kg'],
                'retirement_review_litter_threshold' => $settings['retirement_review_litter_threshold'],
                'breeding_min_doe_age_days' => $settings['breeding_min_doe_age_days'],
                'breeding_min_buck_age_days' => $settings['breeding_min_buck_age_days'],
            ],
        ]);

        return response()->json([
            'data' => $this->farmPayload(
                $membership->setRelation('farm', $farm->fresh())
            ),
        ]);
    }

    public function summary(Request $request, Farm $farm): JsonResponse
    {
        $this->authorizeFarmAccess($request, $farm);
        $salesRevenue = (float) $farm->sales()->sum('sale_price');
        $expenseTotal = (float) $farm->expenses()->sum('amount');

        return response()->json([
            'data' => [
                'active_rabbits' => $farm->rabbits()
                    ->whereNotIn('status', ['sold', 'retired', 'deceased', 'culled'])
                    ->count(),
                'does' => $farm->rabbits()
                    ->where('sex', 'female')
                    ->whereNotIn('status', ['sold', 'retired', 'deceased', 'culled'])
                    ->count(),
                'bucks' => $farm->rabbits()
                    ->where('sex', 'male')
                    ->whereNotIn('status', ['sold', 'retired', 'deceased', 'culled'])
                    ->count(),
                'live_kits' => $farm->litters()
                    ->whereIn('status', ['newborn', 'nursing', 'partially_weaned'])
                    ->sum('current_live_count'),
                'ready_for_sale' => $farm->rabbits()
                    ->where('status', 'ready_for_sale')
                    ->count(),
                'health_alerts' => $farm->healthEvents()
                    ->whereIn('status', ['open', 'monitoring'])
                    ->count(),
                'quarantined' => $farm->rabbits()
                    ->where('status', 'quarantined')
                    ->count(),
                'pregnant_does' => $farm->rabbits()
                    ->where('sex', 'female')
                    ->where('status', 'pregnant')
                    ->count(),
                'nursing_does' => $farm->rabbits()
                    ->where('sex', 'female')
                    ->where('status', 'nursing')
                    ->count(),
                'open_tasks' => $farm->tasks()
                    ->where('status', 'open')
                    ->count(),
                'overdue_tasks' => $farm->tasks()
                    ->where('status', 'open')
                    ->whereDate('due_on', '<', now($farm->timezone)->toDateString())
                    ->count(),
                'expected_kindlings' => $farm->matings()
                    ->whereIn('status', ['awaiting_pregnancy_check', 'uncertain', 'pregnant'])
                    ->whereDate('expected_kindling_on', '>=', now($farm->timezone)->toDateString())
                    ->count(),
                'total_sales' => $farm->sales()->count(),
                'sales_revenue' => number_format($salesRevenue, 2, '.', ''),
                'total_expenses' => number_format($expenseTotal, 2, '.', ''),
                'net_income' => number_format($salesRevenue - $expenseTotal, 2, '.', ''),
                'currency' => $farm->currency,
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

    private function authorizeFarmOwner(Request $request, Farm $farm): FarmMembership
    {
        $membership = $request->user()
            ->memberships()
            ->where('farm_id', $farm->id)
            ->where('is_active', true)
            ->where('role', 'owner')
            ->first();

        abort_unless($membership, 404);

        return $membership;
    }

    private function farmPayload(FarmMembership $membership): array
    {
        return [
            'id' => $membership->farm->id,
            'name' => $membership->farm->name,
            'code' => $membership->farm->code,
            'timezone' => $membership->farm->timezone,
            'currency' => $membership->farm->currency,
            'role' => $membership->role,
            'settings' => $membership->farm->settings ?? [],
        ];
    }

    private function uniqueFarmCode(string $seed): string
    {
        $prefix = Str::of($seed)
            ->upper()
            ->replaceMatches('/[^A-Z0-9]+/', '-')
            ->trim('-')
            ->substr(0, 12);

        $prefix = $prefix->isEmpty() ? 'FARM' : $prefix->toString();

        do {
            $code = "{$prefix}-".Str::upper(Str::random(4));
        } while (Farm::query()->where('code', $code)->exists());

        return $code;
    }
}
