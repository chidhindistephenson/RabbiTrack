import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/reports/finance_report_controller.dart';
import 'package:rabbitrack_mobile/src/features/reports/finance_report_models.dart';
import 'package:rabbitrack_mobile/src/features/reports/finance_report_screen.dart';

void main() {
  testWidgets('FinanceReportScreen renders profit summary and month rows', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          monthlyFinanceReportProvider.overrideWith((ref) async => _report),
        ],
        child: const MaterialApp(home: FinanceReportScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(r'$ 42.50'), findsOneWidget);
    expect(find.text('Profit | Margin 70.8%'), findsOneWidget);
    expect(find.text(r'Revenue $ 60.00'), findsOneWidget);
    expect(find.text(r'Expenses $ 17.50'), findsOneWidget);
    expect(find.text('Jul 2026'), findsOneWidget);
  });

  testWidgets('FinanceReportScreen tolerates non-finite finance values', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          monthlyFinanceReportProvider.overrideWith((ref) async => _oddReport),
        ],
        child: const MaterialApp(home: FinanceReportScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(r'$ 0.00'), findsOneWidget);
    expect(find.text('Break even | Margin 0.0%'), findsOneWidget);
    expect(find.text('Aug 2026'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
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
