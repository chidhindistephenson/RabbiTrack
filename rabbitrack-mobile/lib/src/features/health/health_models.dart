class HealthEventSummary {
  const HealthEventSummary({
    required this.id,
    required this.rabbitIdentifier,
    required this.observedOn,
    required this.symptoms,
    required this.severity,
    required this.status,
    required this.isolationRequired,
    required this.treatmentsCount,
    this.diagnosis,
    this.bodySystem,
    this.notes,
  });

  factory HealthEventSummary.fromJson(Map<String, dynamic> json) {
    return HealthEventSummary(
      id: json['id'] as String,
      rabbitIdentifier: json['rabbit_identifier'] as String? ?? 'Rabbit',
      observedOn: json['observed_on'] as String,
      symptoms: json['symptoms'] as String,
      diagnosis: json['diagnosis'] as String?,
      bodySystem: json['body_system'] as String?,
      severity: json['severity'] as String,
      status: json['status'] as String,
      isolationRequired: json['isolation_required'] as bool,
      treatmentsCount: json['treatments_count'] as int? ?? 0,
      notes: json['notes'] as String?,
    );
  }

  final String id;
  final String rabbitIdentifier;
  final String observedOn;
  final String symptoms;
  final String? diagnosis;
  final String? bodySystem;
  final String severity;
  final String status;
  final bool isolationRequired;
  final int treatmentsCount;
  final String? notes;
}

class TreatmentSummary {
  const TreatmentSummary({
    required this.id,
    required this.healthEventId,
    required this.rabbitId,
    required this.medication,
    required this.startedOn,
    required this.withdrawalDays,
    required this.status,
    this.dosage,
    this.route,
    this.frequency,
    this.withdrawalEndsOn,
  });

  factory TreatmentSummary.fromJson(Map<String, dynamic> json) {
    return TreatmentSummary(
      id: json['id'] as String,
      healthEventId: json['health_event_id'] as String,
      rabbitId: json['rabbit_id'] as String,
      medication: json['medication'] as String,
      dosage: json['dosage'] as String?,
      route: json['route'] as String?,
      frequency: json['frequency'] as String?,
      startedOn: json['started_on'] as String,
      withdrawalDays: json['withdrawal_days'] as int? ?? 0,
      withdrawalEndsOn: json['withdrawal_ends_on'] as String?,
      status: json['status'] as String,
    );
  }

  final String id;
  final String healthEventId;
  final String rabbitId;
  final String medication;
  final String? dosage;
  final String? route;
  final String? frequency;
  final String startedOn;
  final int withdrawalDays;
  final String? withdrawalEndsOn;
  final String status;
}
