class DoePerformanceReport {
  const DoePerformanceReport({
    required this.doeCount,
    required this.totalMatings,
    required this.confirmedPregnancies,
    required this.kindlings,
    required this.completedLitters,
    required this.kitsBornAlive,
    required this.kitsWeaned,
    required this.averageLitterSize,
    required this.survivalRate,
    required this.does,
  });

  factory DoePerformanceReport.fromJson(Map<String, dynamic> json) {
    return DoePerformanceReport(
      doeCount: json['doe_count'] as int? ?? 0,
      totalMatings: json['total_matings'] as int? ?? 0,
      confirmedPregnancies: json['confirmed_pregnancies'] as int? ?? 0,
      kindlings: json['kindlings'] as int? ?? 0,
      completedLitters: json['completed_litters'] as int? ?? 0,
      kitsBornAlive: json['kits_born_alive'] as int? ?? 0,
      kitsWeaned: json['kits_weaned'] as int? ?? 0,
      averageLitterSize: (json['average_litter_size'] as num? ?? 0).toDouble(),
      survivalRate: (json['survival_rate'] as num? ?? 0).toDouble(),
      does: (json['does'] as List<dynamic>? ?? [])
          .map(
            (item) => DoePerformanceRow.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  final int doeCount;
  final int totalMatings;
  final int confirmedPregnancies;
  final int kindlings;
  final int completedLitters;
  final int kitsBornAlive;
  final int kitsWeaned;
  final double averageLitterSize;
  final double survivalRate;
  final List<DoePerformanceRow> does;
}

class DoePerformanceRow {
  const DoePerformanceRow({
    required this.id,
    required this.identifier,
    required this.status,
    required this.matings,
    required this.confirmedPregnancies,
    required this.kindlings,
    required this.completedLitters,
    required this.kitsBornAlive,
    required this.kitsWeaned,
    required this.averageLitterSize,
    required this.survivalRate,
    this.name,
    this.breed,
    this.averageLitterIntervalDays,
  });

  factory DoePerformanceRow.fromJson(Map<String, dynamic> json) {
    return DoePerformanceRow(
      id: json['id'] as String,
      identifier: json['identifier'] as String,
      name: json['name'] as String?,
      breed: json['breed'] as String?,
      status: json['status'] as String? ?? 'unknown',
      matings: json['matings'] as int? ?? 0,
      confirmedPregnancies: json['confirmed_pregnancies'] as int? ?? 0,
      kindlings: json['kindlings'] as int? ?? 0,
      completedLitters: json['completed_litters'] as int? ?? 0,
      kitsBornAlive: json['kits_born_alive'] as int? ?? 0,
      kitsWeaned: json['kits_weaned'] as int? ?? 0,
      averageLitterSize: (json['average_litter_size'] as num? ?? 0).toDouble(),
      survivalRate: (json['survival_rate'] as num? ?? 0).toDouble(),
      averageLitterIntervalDays: (json['average_litter_interval_days'] as num?)
          ?.toDouble(),
    );
  }

  final String id;
  final String identifier;
  final String? name;
  final String? breed;
  final String status;
  final int matings;
  final int confirmedPregnancies;
  final int kindlings;
  final int completedLitters;
  final int kitsBornAlive;
  final int kitsWeaned;
  final double averageLitterSize;
  final double survivalRate;
  final double? averageLitterIntervalDays;
}
