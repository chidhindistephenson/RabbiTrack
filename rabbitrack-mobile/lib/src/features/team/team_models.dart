class FarmMemberSummary {
  const FarmMemberSummary({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    this.joinedAt,
  });

  factory FarmMemberSummary.fromJson(Map<String, dynamic> json) {
    return FarmMemberSummary(
      id: json['id'] as String,
      userId: json['user_id'] as int?,
      name: json['name'] as String? ?? 'Team member',
      email: json['email'] as String? ?? '',
      role: json['role'] as String,
      status: json['status'] as String? ?? 'active',
      joinedAt: json['joined_at'] as String?,
    );
  }

  final String id;
  final int? userId;
  final String name;
  final String email;
  final String role;
  final String status;
  final String? joinedAt;

  bool get isPending => status == 'pending';
}
