class LitterPerformanceReport {
  const LitterPerformanceReport({
    required this.litterCount,
    required this.bornAlive,
    required this.stillborn,
    required this.mortality,
    required this.currentLive,
    required this.weaned,
    required this.survivalRate,
    required this.litters,
  });

  factory LitterPerformanceReport.fromJson(Map<String, dynamic> json) {
    return LitterPerformanceReport(
      litterCount: json['litter_count'] as int? ?? 0,
      bornAlive: json['born_alive'] as int? ?? 0,
      stillborn: json['stillborn'] as int? ?? 0,
      mortality: json['mortality'] as int? ?? 0,
      currentLive: json['current_live'] as int? ?? 0,
      weaned: json['weaned'] as int? ?? 0,
      survivalRate: (json['survival_rate'] as num? ?? 0).toDouble(),
      litters: (json['litters'] as List<dynamic>? ?? [])
          .map(
            (item) =>
                LitterPerformanceRow.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  final int litterCount;
  final int bornAlive;
  final int stillborn;
  final int mortality;
  final int currentLive;
  final int weaned;
  final double survivalRate;
  final List<LitterPerformanceRow> litters;
}

class LitterPerformanceRow {
  const LitterPerformanceRow({
    required this.id,
    required this.identifier,
    required this.bornAlive,
    required this.stillborn,
    required this.mortality,
    required this.currentLive,
    required this.weaned,
    required this.survivalRate,
    required this.weightUnit,
    required this.status,
    this.doeIdentifier,
    this.buckIdentifier,
    this.kindledOn,
    this.birthAverageWeight,
    this.weaningAverageWeight,
  });

  factory LitterPerformanceRow.fromJson(Map<String, dynamic> json) {
    return LitterPerformanceRow(
      id: json['id'] as String,
      identifier: json['identifier'] as String,
      doeIdentifier: json['doe_identifier'] as String?,
      buckIdentifier: json['buck_identifier'] as String?,
      kindledOn: json['kindled_on'] as String?,
      bornAlive: json['born_alive'] as int? ?? 0,
      stillborn: json['stillborn'] as int? ?? 0,
      mortality: json['mortality'] as int? ?? 0,
      currentLive: json['current_live'] as int? ?? 0,
      weaned: json['weaned'] as int? ?? 0,
      survivalRate: (json['survival_rate'] as num? ?? 0).toDouble(),
      birthAverageWeight: json['birth_average_weight']?.toString(),
      weaningAverageWeight: json['weaning_average_weight']?.toString(),
      weightUnit: json['weight_unit'] as String? ?? 'kg',
      status: json['status'] as String? ?? 'newborn',
    );
  }

  final String id;
  final String identifier;
  final String? doeIdentifier;
  final String? buckIdentifier;
  final String? kindledOn;
  final int bornAlive;
  final int stillborn;
  final int mortality;
  final int currentLive;
  final int weaned;
  final double survivalRate;
  final String? birthAverageWeight;
  final String? weaningAverageWeight;
  final String weightUnit;
  final String status;
}
