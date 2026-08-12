class FarmSummary {
  const FarmSummary({
    required this.id,
    required this.name,
    required this.code,
    required this.role,
    required this.timezone,
    required this.currency,
  });

  factory FarmSummary.fromJson(Map<String, dynamic> json) {
    return FarmSummary(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      role: json['role'] as String,
      timezone: json['timezone'] as String? ?? 'Africa/Johannesburg',
      currency: json['currency'] as String? ?? 'USD',
    );
  }

  final String id;
  final String name;
  final String code;
  final String role;
  final String timezone;
  final String currency;
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
}
