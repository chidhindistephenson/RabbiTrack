class FarmLocationSummary {
  const FarmLocationSummary({
    required this.id,
    required this.type,
    required this.name,
    required this.isActive,
    required this.occupiedCount,
    this.parentId,
    this.code,
    this.capacity,
    this.notes,
  });

  factory FarmLocationSummary.fromJson(Map<String, dynamic> json) {
    return FarmLocationSummary(
      id: json['id'] as String,
      parentId: json['parent_id'] as String?,
      type: json['type'] as String,
      name: json['name'] as String,
      code: json['code'] as String?,
      capacity: json['capacity'] as int?,
      occupiedCount: json['occupied_count'] as int? ?? 0,
      isActive: json['is_active'] as bool,
      notes: json['notes'] as String?,
    );
  }

  final String id;
  final String? parentId;
  final String type;
  final String name;
  final String? code;
  final int? capacity;
  final int occupiedCount;
  final bool isActive;
  final String? notes;
}

class FarmLocationDetail extends FarmLocationSummary {
  const FarmLocationDetail({
    required super.id,
    required super.type,
    required super.name,
    required super.isActive,
    required super.occupiedCount,
    required this.rabbits,
    super.parentId,
    super.code,
    super.capacity,
    super.notes,
  });

  factory FarmLocationDetail.fromJson(Map<String, dynamic> json) {
    return FarmLocationDetail(
      id: json['id'] as String,
      parentId: json['parent_id'] as String?,
      type: json['type'] as String,
      name: json['name'] as String,
      code: json['code'] as String?,
      capacity: json['capacity'] as int?,
      occupiedCount: json['occupied_count'] as int? ?? 0,
      isActive: json['is_active'] as bool,
      notes: json['notes'] as String?,
      rabbits: (json['rabbits'] as List<dynamic>? ?? [])
          .map(
            (rabbit) =>
                LocationRabbitSummary.fromJson(rabbit as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  final List<LocationRabbitSummary> rabbits;
}

class LocationRabbitSummary {
  const LocationRabbitSummary({
    required this.id,
    required this.identifier,
    required this.sex,
    required this.status,
    this.name,
    this.breed,
  });

  factory LocationRabbitSummary.fromJson(Map<String, dynamic> json) {
    return LocationRabbitSummary(
      id: json['id'] as String,
      identifier: json['identifier'] as String,
      name: json['name'] as String?,
      sex: json['sex'] as String,
      status: json['status'] as String,
      breed: json['breed'] as String?,
    );
  }

  final String id;
  final String identifier;
  final String? name;
  final String sex;
  final String status;
  final String? breed;
}
