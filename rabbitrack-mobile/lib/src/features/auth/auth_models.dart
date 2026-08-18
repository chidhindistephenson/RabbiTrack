class FarmSummary {
  const FarmSummary({
    required this.id,
    required this.name,
    required this.code,
    required this.role,
    required this.timezone,
    required this.currency,
    this.saleReadyMinAgeDays = 0,
    this.saleReadyMinWeightKg,
    this.retirementReviewLitterThreshold = 0,
    this.breedingMinDoeAgeDays = 0,
    this.breedingMinBuckAgeDays = 0,
  });

  factory FarmSummary.fromJson(Map<String, dynamic> json) {
    final settings = json['settings'] as Map<String, dynamic>? ?? {};

    return FarmSummary(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      role: json['role'] as String,
      timezone: json['timezone'] as String? ?? 'Africa/Johannesburg',
      currency: json['currency'] as String? ?? 'USD',
      saleReadyMinAgeDays:
          _intSetting(settings['sale_ready_min_age_days']) ?? 0,
      saleReadyMinWeightKg: _doubleSetting(
        settings['sale_ready_min_weight_kg'],
      ),
      retirementReviewLitterThreshold:
          _intSetting(settings['retirement_review_litter_threshold']) ?? 0,
      breedingMinDoeAgeDays:
          _intSetting(settings['breeding_min_doe_age_days']) ?? 0,
      breedingMinBuckAgeDays:
          _intSetting(settings['breeding_min_buck_age_days']) ?? 0,
    );
  }

  final String id;
  final String name;
  final String code;
  final String role;
  final String timezone;
  final String currency;
  final int saleReadyMinAgeDays;
  final double? saleReadyMinWeightKg;
  final int retirementReviewLitterThreshold;
  final int breedingMinDoeAgeDays;
  final int breedingMinBuckAgeDays;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'role': role,
      'timezone': timezone,
      'currency': currency,
      'settings': {
        'sale_ready_min_age_days': saleReadyMinAgeDays,
        'sale_ready_min_weight_kg': saleReadyMinWeightKg,
        'retirement_review_litter_threshold': retirementReviewLitterThreshold,
        'breeding_min_doe_age_days': breedingMinDoeAgeDays,
        'breeding_min_buck_age_days': breedingMinBuckAgeDays,
      },
    };
  }
}

int? _intSetting(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value);
  }

  return null;
}

double? _doubleSetting(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value);
  }

  return null;
}

class AuthSession {
  const AuthSession({
    required this.token,
    required this.userName,
    required this.email,
    required this.farms,
    this.username,
    this.phone,
    this.selectedFarm,
  });

  final String token;
  final String userName;
  final String email;
  final String? username;
  final String? phone;
  final List<FarmSummary> farms;
  final FarmSummary? selectedFarm;

  AuthSession copyWith({List<FarmSummary>? farms, FarmSummary? selectedFarm}) {
    return AuthSession(
      token: token,
      userName: userName,
      email: email,
      username: username,
      phone: phone,
      farms: farms ?? this.farms,
      selectedFarm: selectedFarm ?? this.selectedFarm,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'user_name': userName,
      'email': email,
      'username': username,
      'phone': phone,
      'farms': farms.map((farm) => farm.toJson()).toList(),
      'selected_farm_id': selectedFarm?.id,
    };
  }

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final farms = (json['farms'] as List<dynamic>? ?? [])
        .map((farm) => FarmSummary.fromJson(farm as Map<String, dynamic>))
        .toList();
    final selectedFarmId = json['selected_farm_id'] as String?;

    return AuthSession(
      token: json['token'] as String,
      userName: json['user_name'] as String,
      email: json['email'] as String,
      username: json['username'] as String?,
      phone: json['phone'] as String?,
      farms: farms,
      selectedFarm: selectedFarmId == null
          ? null
          : selectedFarmFromJsonList(farms, selectedFarmId),
    );
  }
}

FarmSummary? selectedFarmFromJsonList(
  List<FarmSummary> farms,
  String selectedFarmId,
) {
  for (final farm in farms) {
    if (farm.id == selectedFarmId) {
      return farm;
    }
  }

  return null;
}
