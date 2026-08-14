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
        ]);

        $farm->update([
            'name' => $validated['name'],
            'currency' => Str::upper($validated['currency']),
            'timezone' => $validated['timezone'],
        ]);

        $farm->activityLogs()->create([
            'user_id' => $request->user()->id,
            'action' => 'farm.updated',
            'description' => 'Updated farm settings.',
            'metadata' => [
                'name' => $farm->name,
                'currency' => $farm->currency,
                'timezone' => $farm->timezone,
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
