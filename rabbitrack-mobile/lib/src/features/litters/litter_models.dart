class LitterSummary {
  const LitterSummary({
    required this.id,
    required this.identifier,
    required this.doeId,
    required this.doeIdentifier,
    required this.kindledOn,
    required this.currentLiveCount,
    required this.plannedWeaningOn,
    required this.status,
    this.buckId,
    this.buckIdentifier,
  });

  factory LitterSummary.fromJson(Map<String, dynamic> json) {
    return LitterSummary(
      id: json['id'] as String,
      identifier: json['identifier'] as String,
      doeId: json['doe_id'] as String,
      doeIdentifier: json['doe_identifier'] as String? ?? 'Doe',
      buckId: json['buck_id'] as String?,
      buckIdentifier: json['buck_identifier'] as String?,
      kindledOn: json['kindled_on'] as String,
      currentLiveCount: json['current_live_count'] as int,
      plannedWeaningOn: json['planned_weaning_on'] as String,
      status: json['status'] as String,
    );
  }

  final String id;
  final String identifier;
  final String doeId;
  final String doeIdentifier;
  final String? buckId;
  final String? buckIdentifier;
  final String kindledOn;
  final int currentLiveCount;
  final String plannedWeaningOn;
  final String status;
}

class LitterDetail extends LitterSummary {
  const LitterDetail({
    required super.id,
    required super.identifier,
    required super.doeId,
    required super.doeIdentifier,
    required super.kindledOn,
    required super.currentLiveCount,
    required super.plannedWeaningOn,
    required super.status,
    required this.kitsBornAlive,
    required this.kitsStillborn,
    required this.kitsWeak,
    required this.weanings,
    required this.weights,
    this.notes,
    super.buckId,
    super.buckIdentifier,
  });

  factory LitterDetail.fromJson(Map<String, dynamic> json) {
    return LitterDetail(
      id: json['id'] as String,
      identifier: json['identifier'] as String,
      doeId: json['doe_id'] as String,
      doeIdentifier: json['doe_identifier'] as String? ?? 'Doe',
      buckId: json['buck_id'] as String?,
      buckIdentifier: json['buck_identifier'] as String?,
      kindledOn: json['kindled_on'] as String,
      kitsBornAlive: json['kits_born_alive'] as int,
      kitsStillborn: json['kits_stillborn'] as int,
      kitsWeak: json['kits_weak'] as int,
      currentLiveCount: json['current_live_count'] as int,
      plannedWeaningOn: json['planned_weaning_on'] as String,
      status: json['status'] as String,
      notes: json['notes'] as String?,
      weanings: (json['weanings'] as List<dynamic>? ?? [])
          .map(
            (weaning) =>
                LitterWeaningSummary.fromJson(weaning as Map<String, dynamic>),
          )
          .toList(),
      weights: (json['weights'] as List<dynamic>? ?? [])
          .map(
            (weight) =>
                LitterWeightSummary.fromJson(weight as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  final int kitsBornAlive;
  final int kitsStillborn;
  final int kitsWeak;
  final String? notes;
  final List<LitterWeaningSummary> weanings;
  final List<LitterWeightSummary> weights;
}

class LitterWeaningSummary {
  const LitterWeaningSummary({
    required this.id,
    required this.numberWeaned,
    this.weanedOn,
    this.averageWeightValue,
    this.weightUnit,
    this.destination,
    this.notes,
  });

  factory LitterWeaningSummary.fromJson(Map<String, dynamic> json) {
    return LitterWeaningSummary(
      id: json['id'] as String,
      weanedOn: json['weaned_on'] as String?,
      numberWeaned: json['number_weaned'] as int,
      averageWeightValue: json['average_weight_value']?.toString(),
      weightUnit: json['weight_unit'] as String?,
      destination: json['destination'] as String?,
      notes: json['notes'] as String?,
    );
  }

  final String id;
  final String? weanedOn;
  final int numberWeaned;
  final String? averageWeightValue;
  final String? weightUnit;
  final String? destination;
  final String? notes;
}

class LitterWeightSummary {
  const LitterWeightSummary({
    required this.id,
    required this.weightValue,
    required this.weightUnit,
    this.stage,
    this.kitCount,
    this.averageWeightValue,
    this.weighedOn,
    this.method,
    this.notes,
  });

  factory LitterWeightSummary.fromJson(Map<String, dynamic> json) {
    return LitterWeightSummary(
      id: json['id'] as String,
      weighedOn: json['weighed_on'] as String?,
      weightValue: json['weight_value'].toString(),
      weightUnit: json['weight_unit'] as String,
      stage: json['stage'] as String?,
      kitCount: json['kit_count'] as int?,
      averageWeightValue: json['average_weight_value']?.toString(),
      method: json['method'] as String?,
      notes: json['notes'] as String?,
    );
  }

  final String id;
  final String? weighedOn;
  final String weightValue;
  final String weightUnit;
  final String? stage;
  final int? kitCount;
  final String? averageWeightValue;
  final String? method;
  final String? notes;
}
