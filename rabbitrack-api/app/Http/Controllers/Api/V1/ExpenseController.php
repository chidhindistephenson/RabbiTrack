<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Expense;
use App\Models\Farm;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class ExpenseController extends Controller
{
    public function index(Request $request, Farm $farm): JsonResponse
    {
        $this->authorizeFarmAccess($request, $farm);

        $expenses = $farm->expenses()
            ->orderByDesc('spent_on')
            ->limit(150)
            ->get()
            ->map(fn (Expense $expense) => $this->expensePayload($expense));

        return response()->json(['data' => $expenses]);
    }

    public function summary(Request $request, Farm $farm): JsonResponse
    {
        $this->authorizeFarmAccess($request, $farm);

        $byCategory = $farm->expenses()
            ->selectRaw('category, SUM(amount) as total, COUNT(*) as count')
            ->groupBy('category')
            ->orderByDesc('total')
            ->get()
            ->map(fn (Expense $expense) => [
                'category' => $expense->category,
                'total' => number_format((float) $expense->total, 2, '.', ''),
                'count' => (int) $expense->count,
            ]);

        return response()->json([
            'data' => [
                'total' => number_format((float) $farm->expenses()->sum('amount'), 2, '.', ''),
                'currency' => $farm->currency,
                'by_category' => $byCategory,
            ],
        ]);
    }

    public function store(Request $request, Farm $farm): JsonResponse
    {
        $this->authorizeFarmAccess($request, $farm);

        $validated = $request->validate([
            'category' => ['required', 'string', Rule::in(Expense::CATEGORIES)],
            'vendor' => ['nullable', 'string', 'max:160'],
            'spent_on' => ['required', 'date'],
            'amount' => ['required', 'numeric', 'min:0', 'max:999999999'],
            'currency' => ['nullable', 'string', 'size:3'],
            'notes' => ['nullable', 'string', 'max:2000'],
        ]);

        $expense = $farm->expenses()->create([
            'recorded_by_id' => $request->user()->id,
            'category' => $validated['category'],
            'vendor' => $validated['vendor'] ?? null,
            'spent_on' => $validated['spent_on'],
            'amount' => $validated['amount'],
            'currency' => $validated['currency'] ?? $farm->currency,
            'notes' => $validated['notes'] ?? null,
        ]);

        $farm->activityLogs()->create([
            'user_id' => $request->user()->id,
            'action' => 'expense.recorded',
            'description' => "Recorded {$expense->category} expense.",
            'metadata' => [
                'expense_id' => $expense->id,
                'amount' => $expense->amount,
                'currency' => $expense->currency,
                'category' => $expense->category,
            ],
        ]);

        return response()->json(['data' => $this->expensePayload($expense)], 201);
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

    private function expensePayload(Expense $expense): array
    {
        return [
            'id' => $expense->id,
            'category' => $expense->category,
            'vendor' => $expense->vendor,
            'spent_on' => $expense->spent_on?->toDateString(),
            'amount' => $expense->amount,
            'currency' => $expense->currency,
            'notes' => $expense->notes,
        ];
    }
}
