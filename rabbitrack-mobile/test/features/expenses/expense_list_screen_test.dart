import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/expenses/expense_controller.dart';
import 'package:rabbitrack_mobile/src/features/expenses/expense_list_screen.dart';
import 'package:rabbitrack_mobile/src/features/expenses/expense_models.dart';

void main() {
  testWidgets('ExpenseListScreen renders totals and expense details', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          expenseListProvider.overrideWith((ref) async => _expenses),
          expenseReportProvider.overrideWith((ref) async => _report),
        ],
        child: const MaterialApp(home: ExpenseListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(r'$ 18.75'), findsWidgets);
    expect(find.text('Feed'), findsWidgets);
    expect(find.text('Town Feed Store | 2026-07-30'), findsOneWidget);
  });
}

const _expenses = [
  ExpenseSummary(
    id: 'expense-1',
    category: 'feed',
    vendor: 'Town Feed Store',
    spentOn: '2026-07-30',
    amount: '18.75',
    currency: 'USD',
  ),
];

const _report = ExpenseReport(
  total: '18.75',
  currency: 'USD',
  byCategory: [
    ExpenseCategoryTotal(category: 'feed', total: '18.75', count: 1),
  ],
);
