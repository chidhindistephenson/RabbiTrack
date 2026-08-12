import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/reports/finance_report_models.dart';
import 'package:rabbitrack_mobile/src/features/reports/finance_report_options.dart';

void main() {
  test('financeTotals calculates revenue, expenses, net, and margin', () {
    final totals = financeTotals(const [
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
    ]);

    expect(totals.revenue, 60);
    expect(totals.expenses, 17.5);
    expect(totals.net, 42.5);
    expect(totals.margin.toStringAsFixed(1), '70.8');
    expect(financeResultLabel(totals.net), 'Profit');
    expect(financeBarRatio('10.00', 20), 0.5);
  });

  test('finance helpers ignore non-finite values', () {
    final totals = financeTotals(const [
      MonthlyFinanceRow(
        month: '2026-08',
        label: 'Aug 2026',
        revenue: 'NaN',
        expenses: 'Infinity',
        netIncome: '-Infinity',
      ),
    ]);

    expect(totals.revenue, 0);
    expect(totals.expenses, 0);
    expect(totals.net, 0);
    expect(totals.margin, 0);
    expect(financeAmount('NaN'), 0);
    expect(financeBarRatio('Infinity', 100), 0);
    expect(financeBarRatio('10', double.infinity), 0);
  });
}
