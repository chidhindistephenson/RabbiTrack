import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/expenses/expense_controller.dart';
import 'package:rabbitrack_mobile/src/features/expenses/expense_models.dart';
import 'package:rabbitrack_mobile/src/features/reports/finance_report_controller.dart';
import 'package:rabbitrack_mobile/src/features/reports/finance_report_models.dart';
import 'package:rabbitrack_mobile/src/features/reports/finance_report_screen.dart';
import 'package:rabbitrack_mobile/src/features/sales/sale_controller.dart';
import 'package:rabbitrack_mobile/src/features/sales/sale_models.dart';

void main() {
  testWidgets('FinanceReportScreen renders profit summary and month rows', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _overrides(_report),
        child: const MaterialApp(home: FinanceReportScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(r'$ 42.50'), findsOneWidget);
    expect(find.text('Profit | Margin 70.8%'), findsOneWidget);
    expect(find.text(r'Revenue $ 60.00'), findsOneWidget);
    expect(find.text(r'Expenses $ 17.50'), findsOneWidget);
    expect(find.text('Jul 2026'), findsOneWidget);
    expect(find.widgetWithText(Tab, 'Overview'), findsOneWidget);
    expect(find.widgetWithText(Tab, 'Sales'), findsOneWidget);
    expect(find.widgetWithText(Tab, 'Expenses'), findsOneWidget);
  });

  testWidgets('FinanceReportScreen tolerates non-finite finance values', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _overrides(_oddReport),
        child: const MaterialApp(home: FinanceReportScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(r'$ 0.00'), findsOneWidget);
    expect(find.text('Break even | Margin 0.0%'), findsOneWidget);
    expect(find.text('Aug 2026'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('FinanceReportScreen includes sales and expenses tabs', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _overrides(_report),
        child: const MaterialApp(home: FinanceReportScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sales'));
    await tester.pumpAndSettle();
    expect(find.text('SALE-001'), findsOneWidget);
    expect(find.text(r'$ 25.50'), findsWidgets);

    await tester.tap(find.text('Expenses'));
    await tester.pumpAndSettle();
    expect(find.text('Town Feed Store | 2026-07-30'), findsOneWidget);
    expect(find.text('Feed'), findsWidgets);
  });
}

List<Override> _overrides(MonthlyFinanceReport report) {
  return [
    monthlyFinanceReportProvider.overrideWith((ref) async => report),
    saleListProvider.overrideWith((ref) async => _sales),
    saleReportProvider.overrideWith((ref) async => _saleReport),
    expenseListProvider.overrideWith((ref) async => _expenses),
    expenseReportProvider.overrideWith((ref) async => _expenseReport),
  ];
}

const _report = MonthlyFinanceReport(
  currency: 'USD',
  months: [
    MonthlyFinanceRow(
      month: '2026-06',
      label: 'Jun 2026',
      revenue: '20.00',
      expenses: '5.00',
      netIncome: '15.00',
    ),
    MonthlyFinanceRow(
      month: '2026-07',
      label: 'Jul 2026',
      revenue: '40.00',
      expenses: '12.50',
      netIncome: '27.50',
    ),
  ],
);

const _oddReport = MonthlyFinanceReport(
  currency: 'USD',
  months: [
    MonthlyFinanceRow(
      month: '2026-08',
      label: 'Aug 2026',
      revenue: 'NaN',
      expenses: 'Infinity',
      netIncome: '-Infinity',
    ),
  ],
);

const _sales = [
  SaleSummary(
    id: 'sale-1',
    rabbitId: 'rabbit-1',
    rabbitIdentifier: 'SALE-001',
    buyerName: 'Local buyer',
    buyerPhone: '555-0100',
    soldOn: '2026-07-30',
    salePrice: '25.50',
    currency: 'USD',
  ),
];

const _saleReport = SaleReport(
  totalRevenue: '25.50',
  saleCount: 1,
  averageSale: '25.50',
  currency: 'USD',
);

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

const _expenseReport = ExpenseReport(
  total: '18.75',
  currency: 'USD',
  byCategory: [
    ExpenseCategoryTotal(category: 'feed', total: '18.75', count: 1),
  ],
);
