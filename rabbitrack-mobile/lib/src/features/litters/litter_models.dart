import '../rabbits/rabbit_models.dart';

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
    this.convertedRabbitsCount = 0,
    this.unconvertedKitsCount = 0,
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
      convertedRabbitsCount: json['converted_rabbits_count'] as int? ?? 0,
      unconvertedKitsCount:
          json['unconverted_kits_count'] as int? ??
          json['current_live_count'] as int,
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
  final int convertedRabbitsCount;
  final int unconvertedKitsCount;
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
    required this.checks,
    required this.fostersOut,
    required this.fostersIn,
    required this.weights,
    this.notes,
    super.buckId,
    super.buckIdentifier,
    super.convertedRabbitsCount,
    super.unconvertedKitsCount,
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
      checks: (json['checks'] as List<dynamic>? ?? [])
          .map(
            (check) =>
                LitterCheckSummary.fromJson(check as Map<String, dynamic>),
          )
          .toList(),
      fostersOut: (json['fosters_out'] as List<dynamic>? ?? [])
          .map(
            (foster) =>
                LitterFosterSummary.fromJson(foster as Map<String, dynamic>),
          )
          .toList(),
      fostersIn: (json['fosters_in'] as List<dynamic>? ?? [])
          .map(
            (foster) =>
                LitterFosterSummary.fromJson(foster as Map<String, dynamic>),
          )
          .toList(),
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
  final List<LitterCheckSummary> checks;
  final List<LitterFosterSummary> fostersOut;
  final List<LitterFosterSummary> fostersIn;
  final List<LitterWeaningSummary> weanings;
  final List<LitterWeightSummary> weights;
}

class LitterFosterSummary {
  const LitterFosterSummary({
    required this.id,
    required this.kitCount,
    this.fosteredOn,
    this.reason,
    this.notes,
    this.fromLitterId,
    this.fromLitterIdentifier,
    this.toLitterId,
    this.toLitterIdentifier,
  });

  factory LitterFosterSummary.fromJson(Map<String, dynamic> json) {
    return LitterFosterSummary(
      id: json['id'] as String,
      fosteredOn: json['fostered_on'] as String?,
      kitCount: json['kit_count'] as int,
      reason: json['reason'] as String?,
      notes: json['notes'] as String?,
      fromLitterId: json['from_litter_id'] as String?,
      fromLitterIdentifier: json['from_litter_identifier'] as String?,
      toLitterId: json['to_litter_id'] as String?,
      toLitterIdentifier: json['to_litter_identifier'] as String?,
    );
  }

  final String id;
  final String? fosteredOn;
  final int kitCount;
  final String? reason;
  final String? notes;
  final String? fromLitterId;
  final String? fromLitterIdentifier;
  final String? toLitterId;
  final String? toLitterIdentifier;
}

class LitterCheckSummary {
  const LitterCheckSummary({
    required this.id,
    required this.liveCount,
    required this.deadCount,
    required this.weakCount,
    this.checkedOn,
    this.suspectedCause,
    this.nestObservation,
    this.correctiveAction,
    this.notes,
  });

  factory LitterCheckSummary.fromJson(Map<String, dynamic> json) {
    return LitterCheckSummary(
      id: json['id'] as String,
      checkedOn: json['checked_on'] as String?,
      liveCount: json['live_count'] as int,
      deadCount: json['dead_count'] as int? ?? 0,
      weakCount: json['weak_count'] as int? ?? 0,
      suspectedCause: json['suspected_cause'] as String?,
      nestObservation: json['nest_observation'] as String?,
      correctiveAction: json['corrective_action'] as String?,
      notes: json['notes'] as String?,
    );
  }

  final String id;
  final String? checkedOn;
  final int liveCount;
  final int deadCount;
  final int weakCount;
  final String? suspectedCause;
  final String? nestObservation;
  final String? correctiveAction;
  final String? notes;
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

class LitterConversionResult {
  const LitterConversionResult({
    required this.convertedCount,
    required this.remainingCount,
    required this.rabbits,
  });

  factory LitterConversionResult.fromJson(Map<String, dynamic> json) {
    return LitterConversionResult(
      convertedCount: json['converted_count'] as int? ?? 0,
      remainingCount: json['remaining_count'] as int? ?? 0,
      rabbits: (json['rabbits'] as List<dynamic>? ?? [])
          .map(
            (rabbit) => RabbitSummary.fromJson(rabbit as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  final int convertedCount;
  final int remainingCount;
  final List<RabbitSummary> rabbits;
}
