class RabbitSummary {
  const RabbitSummary({
    required this.id,
    required this.identifier,
    required this.sex,
    required this.status,
    this.name,
    this.breed,
    this.dateOfBirth,
    this.currentLocationName,
    this.motherId,
    this.fatherId,
  });

  factory RabbitSummary.fromJson(Map<String, dynamic> json) {
    return RabbitSummary(
      id: json['id'] as String,
      identifier: json['identifier'] as String,
      name: json['name'] as String?,
      sex: json['sex'] as String,
      breed: json['breed'] as String?,
      dateOfBirth: json['date_of_birth'] as String?,
      status: json['status'] as String,
      currentLocationName: json['current_location_name'] as String?,
      motherId: json['mother_id'] as String?,
      fatherId: json['father_id'] as String?,
    );
  }

  final String id;
  final String identifier;
  final String? name;
  final String sex;
  final String? breed;
  final String? dateOfBirth;
  final String status;
  final String? currentLocationName;
  final String? motherId;
  final String? fatherId;
}

class RabbitDetail extends RabbitSummary {
  const RabbitDetail({
    required super.id,
    required super.identifier,
    required super.sex,
    required super.status,
    required this.movements,
    super.name,
    super.breed,
    super.dateOfBirth,
    this.currentLocationId,
    super.currentLocationName,
    this.colour,
    this.weightValue,
    this.weightUnit,
    this.tagOrTattoo,
    this.mother,
    this.father,
    this.notes,
  });

  factory RabbitDetail.fromJson(Map<String, dynamic> json) {
    return RabbitDetail(
      id: json['id'] as String,
      identifier: json['identifier'] as String,
      name: json['name'] as String?,
      sex: json['sex'] as String,
      dateOfBirth: json['date_of_birth'] as String?,
      breed: json['breed'] as String?,
      colour: json['colour'] as String?,
      weightValue: json['weight_value']?.toString(),
      weightUnit: json['weight_unit'] as String?,
      tagOrTattoo: json['tag_or_tattoo'] as String?,
      status: json['status'] as String,
      currentLocationId: json['current_location_id'] as String?,
      currentLocationName: json['current_location_name'] as String?,
      mother: json['mother'] == null
          ? null
          : RabbitParent.fromJson(json['mother'] as Map<String, dynamic>),
      father: json['father'] == null
          ? null
          : RabbitParent.fromJson(json['father'] as Map<String, dynamic>),
      movements: (json['movements'] as List<dynamic>? ?? [])
          .map(
            (movement) => RabbitMovementSummary.fromJson(
              movement as Map<String, dynamic>,
            ),
          )
          .toList(),
      notes: json['notes'] as String?,
    );
  }

  final String? colour;
  final String? currentLocationId;
  final String? weightValue;
  final String? weightUnit;
  final String? tagOrTattoo;
  final RabbitParent? mother;
  final RabbitParent? father;
  final List<RabbitMovementSummary> movements;
  final String? notes;
}

class RabbitParent {
  const RabbitParent({required this.id, required this.identifier, this.name});

  factory RabbitParent.fromJson(Map<String, dynamic> json) {
    return RabbitParent(
      id: json['id'] as String,
      identifier: json['identifier'] as String,
      name: json['name'] as String?,
    );
  }

  final String id;
  final String identifier;
  final String? name;
}

class RabbitMovementSummary {
  const RabbitMovementSummary({
    required this.id,
    this.fromLocation,
    this.toLocation,
    this.movedAt,
    this.reason,
    this.notes,
  });

  factory RabbitMovementSummary.fromJson(Map<String, dynamic> json) {
    return RabbitMovementSummary(
      id: json['id'] as String,
      fromLocation: json['from_location'] as String?,
      toLocation: json['to_location'] as String?,
      movedAt: json['moved_at'] as String?,
      reason: json['reason'] as String?,
      notes: json['notes'] as String?,
    );
  }

  final String id;
  final String? fromLocation;
  final String? toLocation;
  final String? movedAt;
  final String? reason;
  final String? notes;
}

class RabbitMovementResult {
  const RabbitMovementResult({
    required this.id,
    required this.rabbitId,
    required this.toLocationId,
    required this.movedAt,
    this.fromLocationId,
    this.reason,
    this.notes,
  });

  factory RabbitMovementResult.fromJson(Map<String, dynamic> json) {
    return RabbitMovementResult(
      id: json['id'] as String,
      rabbitId: json['rabbit_id'] as String,
      fromLocationId: json['from_location_id'] as String?,
      toLocationId: json['to_location_id'] as String,
      movedAt: json['moved_at'] as String,
      reason: json['reason'] as String?,
      notes: json['notes'] as String?,
    );
  }

  final String id;
  final String rabbitId;
  final String? fromLocationId;
  final String toLocationId;
  final String movedAt;
  final String? reason;
  final String? notes;
}
