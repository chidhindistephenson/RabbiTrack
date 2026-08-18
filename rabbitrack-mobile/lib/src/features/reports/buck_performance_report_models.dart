class BuckPerformanceReport {
  const BuckPerformanceReport({
    required this.buckCount,
    required this.totalMatings,
    required this.confirmedPregnancies,
    required this.conceptionRate,
    required this.litters,
    required this.kitsBornAlive,
    required this.kitsWeaned,
    required this.averageLitterSize,
    required this.weaningRate,
    required this.bucks,
  });

  factory BuckPerformanceReport.fromJson(Map<String, dynamic> json) {
    return BuckPerformanceReport(
      buckCount: json['buck_count'] as int? ?? 0,
      totalMatings: json['total_matings'] as int? ?? 0,
      confirmedPregnancies: json['confirmed_pregnancies'] as int? ?? 0,
      conceptionRate: (json['conception_rate'] as num? ?? 0).toDouble(),
      litters: json['litters'] as int? ?? 0,
      kitsBornAlive: json['kits_born_alive'] as int? ?? 0,
      kitsWeaned: json['kits_weaned'] as int? ?? 0,
      averageLitterSize: (json['average_litter_size'] as num? ?? 0).toDouble(),
      weaningRate: (json['weaning_rate'] as num? ?? 0).toDouble(),
      bucks: (json['bucks'] as List<dynamic>? ?? [])
          .map(
            (item) => BuckPerformanceRow.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  final int buckCount;
  final int totalMatings;
  final int confirmedPregnancies;
  final double conceptionRate;
  final int litters;
  final int kitsBornAlive;
  final int kitsWeaned;
  final double averageLitterSize;
  final double weaningRate;
  final List<BuckPerformanceRow> bucks;
}

class BuckPerformanceRow {
  const BuckPerformanceRow({
    required this.id,
    required this.identifier,
    required this.status,
    required this.matings,
    required this.confirmedPregnancies,
    required this.conceptionRate,
    required this.litters,
    required this.kitsBornAlive,
    required this.kitsWeaned,
    required this.averageLitterSize,
    required this.weaningRate,
    this.name,
    this.breed,
  });

  factory BuckPerformanceRow.fromJson(Map<String, dynamic> json) {
    return BuckPerformanceRow(
      id: json['id'] as String,
      identifier: json['identifier'] as String,
      name: json['name'] as String?,
      breed: json['breed'] as String?,
      status: json['status'] as String? ?? 'unknown',
      matings: json['matings'] as int? ?? 0,
      confirmedPregnancies: json['confirmed_pregnancies'] as int? ?? 0,
      conceptionRate: (json['conception_rate'] as num? ?? 0).toDouble(),
      litters: json['litters'] as int? ?? 0,
      kitsBornAlive: json['kits_born_alive'] as int? ?? 0,
      kitsWeaned: json['kits_weaned'] as int? ?? 0,
      averageLitterSize: (json['average_litter_size'] as num? ?? 0).toDouble(),
      weaningRate: (json['weaning_rate'] as num? ?? 0).toDouble(),
    );
  }

  final String id;
  final String identifier;
  final String? name;
  final String? breed;
  final String status;
  final int matings;
  final int confirmedPregnancies;
  final double conceptionRate;
  final int litters;
  final int kitsBornAlive;
  final int kitsWeaned;
  final double averageLitterSize;
  final double weaningRate;
}
