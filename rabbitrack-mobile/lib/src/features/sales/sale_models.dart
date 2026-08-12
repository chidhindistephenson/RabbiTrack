class SaleSummary {
  const SaleSummary({
    required this.id,
    required this.rabbitId,
    required this.soldOn,
    required this.salePrice,
    required this.currency,
    this.rabbitIdentifier,
    this.buyerName,
    this.buyerPhone,
    this.notes,
  });

  factory SaleSummary.fromJson(Map<String, dynamic> json) {
    return SaleSummary(
      id: json['id'] as String,
      rabbitId: json['rabbit_id'] as String,
      rabbitIdentifier: json['rabbit_identifier'] as String?,
      buyerName: json['buyer_name'] as String?,
      buyerPhone: json['buyer_phone'] as String?,
      soldOn: json['sold_on'] as String,
      salePrice: json['sale_price'].toString(),
      currency: json['currency'] as String,
      notes: json['notes'] as String?,
    );
  }

  final String id;
  final String rabbitId;
  final String? rabbitIdentifier;
  final String? buyerName;
  final String? buyerPhone;
  final String soldOn;
  final String salePrice;
  final String currency;
  final String? notes;
}

class SaleReport {
  const SaleReport({
    required this.totalRevenue,
    required this.saleCount,
    required this.averageSale,
    required this.currency,
  });

  factory SaleReport.fromJson(Map<String, dynamic> json) {
    return SaleReport(
      totalRevenue: json['total_revenue'] as String? ?? '0.00',
      saleCount: json['sale_count'] as int? ?? 0,
      averageSale: json['average_sale'] as String? ?? '0.00',
      currency: json['currency'] as String? ?? 'USD',
    );
  }

  final String totalRevenue;
  final int saleCount;
  final String averageSale;
  final String currency;
}
