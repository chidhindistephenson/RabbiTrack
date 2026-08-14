class FarmSummaryCounts {
  const FarmSummaryCounts({
    required this.activeRabbits,
    required this.readyForSale,
    required this.healthAlerts,
    required this.quarantined,
    required this.pregnantDoes,
    required this.nursingDoes,
    required this.openTasks,
    required this.totalSales,
    required this.salesRevenue,
    required this.totalExpenses,
    required this.netIncome,
    required this.currency,
  });

  factory FarmSummaryCounts.fromJson(Map<String, dynamic> json) {
    return FarmSummaryCounts(
      activeRabbits: json['active_rabbits'] as int? ?? 0,
      readyForSale: json['ready_for_sale'] as int? ?? 0,
      healthAlerts: json['health_alerts'] as int? ?? 0,
      quarantined: json['quarantined'] as int? ?? 0,
      pregnantDoes: json['pregnant_does'] as int? ?? 0,
      nursingDoes: json['nursing_does'] as int? ?? 0,
      openTasks: json['open_tasks'] as int? ?? 0,
      totalSales: json['total_sales'] as int? ?? 0,
      salesRevenue: json['sales_revenue'] as String? ?? '0.00',
      totalExpenses: json['total_expenses'] as String? ?? '0.00',
      netIncome: json['net_income'] as String? ?? '0.00',
      currency: json['currency'] as String? ?? 'USD',
    );
  }

  final int activeRabbits;
  final int readyForSale;
  final int healthAlerts;
  final int quarantined;
  final int pregnantDoes;
  final int nursingDoes;
  final int openTasks;
  final int totalSales;
  final String salesRevenue;
  final String totalExpenses;
  final String netIncome;
  final String currency;
}
