class BreedingCalendarEvent {
  const BreedingCalendarEvent({
    required this.date,
    required this.type,
    required this.title,
    required this.relatedType,
    required this.relatedId,
    this.subtitle,
    this.rabbitId,
    this.rabbitIdentifier,
  });

  factory BreedingCalendarEvent.fromJson(Map<String, dynamic> json) {
    return BreedingCalendarEvent(
      date: json['date'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String?,
      relatedType: json['related_type'] as String,
      relatedId: json['related_id'] as String,
      rabbitId: json['rabbit_id'] as String?,
      rabbitIdentifier: json['rabbit_identifier'] as String?,
    );
  }

  final String date;
  final String type;
  final String title;
  final String? subtitle;
  final String relatedType;
  final String relatedId;
  final String? rabbitId;
  final String? rabbitIdentifier;
}
