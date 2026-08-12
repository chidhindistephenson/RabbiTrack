class ActivityLogSummary {
  const ActivityLogSummary({
    required this.id,
    required this.action,
    required this.description,
    required this.createdAt,
    this.actorName,
  });

  factory ActivityLogSummary.fromJson(Map<String, dynamic> json) {
    return ActivityLogSummary(
      id: json['id'] as String,
      action: json['action'] as String,
      description: json['description'] as String,
      actorName: json['actor_name'] as String?,
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  final String id;
  final String action;
  final String description;
  final String? actorName;
  final String createdAt;
}
