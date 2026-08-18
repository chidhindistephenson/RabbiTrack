class HealthReport {
  const HealthReport({
    required this.activeHealthEvents,
    required this.activeTreatments,
    required this.withdrawalRestrictions,
    required this.mortalityCount,
    required this.eventsBySeverity,
    required this.eventsByBodySystem,
    required this.eventsByDiagnosis,
    required this.medicineUse,
    required this.withdrawals,
  });

  factory HealthReport.fromJson(Map<String, dynamic> json) {
    return HealthReport(
      activeHealthEvents: json['active_health_events'] as int? ?? 0,
      activeTreatments: json['active_treatments'] as int? ?? 0,
      withdrawalRestrictions: json['withdrawal_restrictions'] as int? ?? 0,
      mortalityCount: json['mortality_count'] as int? ?? 0,
      eventsBySeverity: _rows(json['events_by_severity']),
      eventsByBodySystem: _rows(json['events_by_body_system']),
      eventsByDiagnosis: _rows(json['events_by_diagnosis']),
      medicineUse: _rows(json['medicine_use']),
      withdrawals: (json['withdrawals'] as List<dynamic>? ?? [])
          .map(
            (item) => WithdrawalSummary.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  final int activeHealthEvents;
  final int activeTreatments;
  final int withdrawalRestrictions;
  final int mortalityCount;
  final List<HealthReportRow> eventsBySeverity;
  final List<HealthReportRow> eventsByBodySystem;
  final List<HealthReportRow> eventsByDiagnosis;
  final List<HealthReportRow> medicineUse;
  final List<WithdrawalSummary> withdrawals;
}

class HealthReportRow {
  const HealthReportRow({required this.label, required this.count});

  factory HealthReportRow.fromJson(Map<String, dynamic> json) {
    return HealthReportRow(
      label: json['label'] as String? ?? 'Unknown',
      count: json['count'] as int? ?? 0,
    );
  }

  final String label;
  final int count;
}

class WithdrawalSummary {
  const WithdrawalSummary({
    required this.id,
    required this.rabbitId,
    required this.medication,
    required this.withdrawalEndsOn,
    this.rabbitIdentifier,
  });

  factory WithdrawalSummary.fromJson(Map<String, dynamic> json) {
    return WithdrawalSummary(
      id: json['id'] as String,
      rabbitId: json['rabbit_id'] as String,
      rabbitIdentifier: json['rabbit_identifier'] as String?,
      medication: json['medication'] as String,
      withdrawalEndsOn: json['withdrawal_ends_on'] as String,
    );
  }

  final String id;
  final String rabbitId;
  final String? rabbitIdentifier;
  final String medication;
  final String withdrawalEndsOn;
}

List<HealthReportRow> _rows(Object? value) {
  final items = value as List<dynamic>? ?? [];

  return items
      .map((item) => HealthReportRow.fromJson(item as Map<String, dynamic>))
      .toList();
}
