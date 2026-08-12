<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Farm;
use Carbon\CarbonImmutable;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class FinanceReportController extends Controller
{
    public function monthly(Request $request, Farm $farm): JsonResponse
    {
        $this->authorizeFarmAccess($request, $farm);

        $start = CarbonImmutable::now()->startOfMonth()->subMonths(5);
        $end = CarbonImmutable::now()->endOfMonth();

        $sales = $farm->sales()
            ->whereBetween('sold_on', [$start->toDateString(), $end->toDateString()])
            ->get(['sold_on', 'sale_price'])
            ->groupBy(fn ($sale) => $sale->sold_on->format('Y-m'));

        $expenses = $farm->expenses()
            ->whereBetween('spent_on', [$start->toDateString(), $end->toDateString()])
            ->get(['spent_on', 'amount'])
            ->groupBy(fn ($expense) => $expense->spent_on->format('Y-m'));

        $months = collect(range(0, 5))->map(function (int $offset) use ($start, $sales, $expenses) {
            $month = $start->addMonths($offset);
            $key = $month->format('Y-m');
            $revenue = (float) ($sales->get($key)?->sum('sale_price') ?? 0);
            $expenseTotal = (float) ($expenses->get($key)?->sum('amount') ?? 0);

            return [
                'month' => $key,
                'label' => $month->format('M Y'),
                'revenue' => number_format($revenue, 2, '.', ''),
                'expenses' => number_format($expenseTotal, 2, '.', ''),
                'net_income' => number_format($revenue - $expenseTotal, 2, '.', ''),
            ];
        });

        return response()->json([
            'data' => [
                'currency' => $farm->currency,
                'months' => $months,
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
}
