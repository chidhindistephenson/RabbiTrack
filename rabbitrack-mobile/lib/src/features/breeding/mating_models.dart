class MatingSummary {
  const MatingSummary({
    required this.id,
    required this.doeId,
    required this.doeIdentifier,
    required this.buckIdentifier,
    required this.pregnancyCheckDueOn,
    required this.expectedKindlingOn,
    required this.status,
  });

  factory MatingSummary.fromJson(Map<String, dynamic> json) {
    return MatingSummary(
      id: json['id'] as String,
      doeId: json['doe_id'] as String,
      doeIdentifier: json['doe_identifier'] as String? ?? 'Doe',
      buckIdentifier: json['buck_identifier'] as String? ?? 'Buck',
      pregnancyCheckDueOn: json['pregnancy_check_due_on'] as String,
      expectedKindlingOn: json['expected_kindling_on'] as String,
      status: json['status'] as String,
    );
  }

  final String id;
  final String doeId;
  final String doeIdentifier;
  final String buckIdentifier;
  final String pregnancyCheckDueOn;
  final String expectedKindlingOn;
  final String status;
}

class MatingDetail extends MatingSummary {
  const MatingDetail({
    required super.id,
    required super.doeId,
    required super.doeIdentifier,
    required super.buckIdentifier,
    required super.pregnancyCheckDueOn,
    required super.expectedKindlingOn,
    required super.status,
    required this.pregnancyChecks,
    required this.litters,
    this.matedAt,
    this.outcome,
    this.behaviorObserved,
    this.nestBoxDueOn,
    this.notes,
  });

  factory MatingDetail.fromJson(Map<String, dynamic> json) {
    return MatingDetail(
      id: json['id'] as String,
      doeId: json['doe_id'] as String,
      doeIdentifier: json['doe_identifier'] as String? ?? 'Doe',
      buckIdentifier: json['buck_identifier'] as String? ?? 'Buck',
      pregnancyCheckDueOn: json['pregnancy_check_due_on'] as String,
      expectedKindlingOn: json['expected_kindling_on'] as String,
      status: json['status'] as String,
      matedAt: json['mated_at'] as String?,
      outcome: json['outcome'] as String?,
      behaviorObserved: json['behavior_observed'] as String?,
      nestBoxDueOn: json['nest_box_due_on'] as String?,
      notes: json['notes'] as String?,
      pregnancyChecks: (json['pregnancy_checks'] as List<dynamic>? ?? [])
          .map(
            (check) =>
                PregnancyCheckSummary.fromJson(check as Map<String, dynamic>),
          )
          .toList(),
      litters: (json['litters'] as List<dynamic>? ?? [])
          .map(
            (litter) =>
                MatingLitterSummary.fromJson(litter as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  final String? matedAt;
  final String? outcome;
  final String? behaviorObserved;
  final String? nestBoxDueOn;
  final String? notes;
  final List<PregnancyCheckSummary> pregnancyChecks;
  final List<MatingLitterSummary> litters;
}

class PregnancyCheckSummary {
  const PregnancyCheckSummary({
    required this.id,
    required this.result,
    this.checkedOn,
    this.notes,
  });

  factory PregnancyCheckSummary.fromJson(Map<String, dynamic> json) {
    return PregnancyCheckSummary(
      id: json['id'] as String,
      checkedOn: json['checked_on'] as String?,
      result: json['result'] as String,
      notes: json['notes'] as String?,
    );
  }

  final String id;
  final String? checkedOn;
  final String result;
  final String? notes;
}

class MatingLitterSummary {
  const MatingLitterSummary({
    required this.id,
    required this.identifier,
    required this.status,
    this.kindledOn,
    this.bornAlive,
    this.bornDead,
  });

  factory MatingLitterSummary.fromJson(Map<String, dynamic> json) {
    return MatingLitterSummary(
      id: json['id'] as String,
      identifier: json['identifier'] as String,
      kindledOn: json['kindled_on'] as String?,
      bornAlive: json['born_alive'] as int?,
      bornDead: json['born_dead'] as int?,
      status: json['status'] as String,
    );
  }

  final String id;
  final String identifier;
  final String? kindledOn;
  final int? bornAlive;
  final int? bornDead;
  final String status;
}
