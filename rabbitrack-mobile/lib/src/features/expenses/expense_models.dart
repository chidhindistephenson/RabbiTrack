class ExpenseSummary {
  const ExpenseSummary({
    required this.id,
    required this.category,
    required this.spentOn,
    required this.amount,
    required this.currency,
    this.vendor,
    this.notes,
  });

  factory ExpenseSummary.fromJson(Map<String, dynamic> json) {
    return ExpenseSummary(
      id: json['id'] as String,
      category: json['category'] as String,
      vendor: json['vendor'] as String?,
      spentOn: json['spent_on'] as String,
      amount: json['amount'].toString(),
      currency: json['currency'] as String,
      notes: json['notes'] as String?,
    );
  }

  final String id;
  final String category;
  final String? vendor;
  final String spentOn;
  final String amount;
  final String currency;
  final String? notes;
}

class ExpenseReport {
  const ExpenseReport({
    required this.total,
    required this.currency,
    required this.byCategory,
  });

  factory ExpenseReport.fromJson(Map<String, dynamic> json) {
    final categories = json['by_category'] as List<dynamic>? ?? [];

    return ExpenseReport(
      total: json['total'] as String? ?? '0.00',
      currency: json['currency'] as String? ?? 'USD',
      byCategory: categories
          .map(
            (category) =>
                ExpenseCategoryTotal.fromJson(category as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  final String total;
  final String currency;
  final List<ExpenseCategoryTotal> byCategory;
}

class ExpenseCategoryTotal {
  const ExpenseCategoryTotal({
    required this.category,
    required this.total,
    required this.count,
  });

  factory ExpenseCategoryTotal.fromJson(Map<String, dynamic> json) {
    return ExpenseCategoryTotal(
      category: json['category'] as String,
      total: json['total'] as String? ?? '0.00',
      count: json['count'] as int? ?? 0,
    );
  }

  final String category;
  final String total;
  final int count;
}
