class WeightSummary {
  const WeightSummary({
    required this.id,
    required this.weighedOn,
    required this.weightValue,
    required this.weightUnit,
    this.rabbitIdentifier,
    this.litterIdentifier,
    this.stage,
    this.kitCount,
    this.averageWeightValue,
    this.method,
    this.notes,
  });

  factory WeightSummary.fromJson(Map<String, dynamic> json) {
    return WeightSummary(
      id: json['id'] as String,
      rabbitIdentifier: json['rabbit_identifier'] as String?,
      litterIdentifier: json['litter_identifier'] as String?,
      stage: json['stage'] as String?,
      weighedOn: json['weighed_on'] as String,
      weightValue: json['weight_value'] as String,
      weightUnit: json['weight_unit'] as String,
      kitCount: json['kit_count'] as int?,
      averageWeightValue: json['average_weight_value']?.toString(),
      method: json['method'] as String?,
      notes: json['notes'] as String?,
    );
  }

  final String id;
  final String? rabbitIdentifier;
  final String? litterIdentifier;
  final String? stage;
  final String weighedOn;
  final String weightValue;
  final String weightUnit;
  final int? kitCount;
  final String? averageWeightValue;
  final String? method;
  final String? notes;
}
