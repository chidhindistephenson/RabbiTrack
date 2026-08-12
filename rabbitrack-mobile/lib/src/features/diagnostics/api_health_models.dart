class ApiHealthStatus {
  const ApiHealthStatus({
    required this.status,
    required this.app,
    required this.checks,
  });

  factory ApiHealthStatus.fromJson(Map<String, dynamic> json) {
    final checksJson = json['checks'] as Map<String, dynamic>? ?? {};

    return ApiHealthStatus(
      status: json['status'] as String? ?? 'unknown',
      app: json['app'] as String? ?? 'RabbiTrack',
      checks: checksJson.map((key, value) => MapEntry(key, value == true)),
    );
  }

  final String status;
  final String app;
  final Map<String, bool> checks;

  bool get isHealthy => status == 'ok' && checks.values.every((check) => check);
}
