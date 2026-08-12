import 'finance_report_models.dart';

class FinanceTotals {
  const FinanceTotals({
    required this.revenue,
    required this.expenses,
    required this.net,
    required this.margin,
  });

  final double revenue;
  final double expenses;
  final double net;
  final double margin;
}

FinanceTotals financeTotals(List<MonthlyFinanceRow> months) {
  final revenue = months.fold<double>(
    0,
    (total, month) => total + financeAmount(month.revenue),
  );
  final expenses = months.fold<double>(
    0,
    (total, month) => total + financeAmount(month.expenses),
  );
  final net = revenue - expenses;
  final margin = revenue <= 0 ? 0.0 : (net / revenue) * 100;

  return FinanceTotals(
    revenue: revenue,
    expenses: expenses,
    net: net,
    margin: margin,
  );
}

String financeResultLabel(double net) {
  if (net > 0) {
    return 'Profit';
  }
  if (net < 0) {
    return 'Loss';
  }

  return 'Break even';
}

double financeBarRatio(String value, double maxValue) {
  final amount = financeAmount(value);
  if (!maxValue.isFinite || maxValue <= 0 || amount <= 0) {
    return 0;
  }

  return (amount / maxValue).clamp(0, 1);
}

double financeAmount(String value) {
  final amount = double.tryParse(value);
  if (amount == null || !amount.isFinite) {
    return 0;
  }

  return amount;
}
