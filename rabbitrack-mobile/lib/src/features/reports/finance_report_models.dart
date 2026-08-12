class MonthlyFinanceReport {
  const MonthlyFinanceReport({required this.currency, required this.months});

  factory MonthlyFinanceReport.fromJson(Map<String, dynamic> json) {
    final months = json['months'] as List<dynamic>? ?? [];

    return MonthlyFinanceReport(
      currency: json['currency'] as String? ?? 'USD',
      months: months
          .map(
            (month) =>
                MonthlyFinanceRow.fromJson(month as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  final String currency;
  final List<MonthlyFinanceRow> months;
}

class MonthlyFinanceRow {
  const MonthlyFinanceRow({
    required this.month,
    required this.label,
    required this.revenue,
    required this.expenses,
    required this.netIncome,
  });

  factory MonthlyFinanceRow.fromJson(Map<String, dynamic> json) {
    return MonthlyFinanceRow(
      month: json['month'] as String,
      label: json['label'] as String,
      revenue: json['revenue'] as String? ?? '0.00',
      expenses: json['expenses'] as String? ?? '0.00',
      netIncome: json['net_income'] as String? ?? '0.00',
    );
  }

  final String month;
  final String label;
  final String revenue;
  final String expenses;
  final String netIncome;
}
