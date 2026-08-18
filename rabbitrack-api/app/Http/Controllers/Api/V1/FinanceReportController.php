<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Farm;
use Carbon\CarbonImmutable;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class FinanceReportController extends Controller
{
    public function monthly(Request $request, Farm $farm): JsonResponse|Response
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

        $payload = [
            'data' => [
                'currency' => $farm->currency,
                'months' => $months,
            ],
        ];

        if ($request->query('format') === 'csv') {
            return $this->csvResponse(
                'finance-report.csv',
                ['month', 'label', 'currency', 'revenue', 'expenses', 'net_income'],
                $months->map(fn (array $month) => [
                    $month['month'],
                    $month['label'],
                    $farm->currency,
                    $month['revenue'],
                    $month['expenses'],
                    $month['net_income'],
                ])->all(),
            );
        }

        return response()->json($payload);
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

    private function csvResponse(string $filename, array $header, array $rows): Response
    {
        $handle = fopen('php://temp', 'r+');
        fputcsv($handle, $header);

        foreach ($rows as $row) {
            fputcsv($handle, $row);
        }

        rewind($handle);
        $csv = stream_get_contents($handle);
        fclose($handle);

        return response($csv, 200, [
            'Content-Type' => 'text/csv; charset=UTF-8',
            'Content-Disposition' => "attachment; filename=\"{$filename}\"",
        ]);
    }
}
