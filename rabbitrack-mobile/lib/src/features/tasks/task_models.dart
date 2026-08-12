class TaskSummary {
  const TaskSummary({
    required this.id,
    required this.type,
    required this.title,
    required this.dueOn,
    required this.priority,
    required this.status,
    this.description,
    this.dueTime,
    this.rabbitIdentifier,
    this.locationName,
  });

  factory TaskSummary.fromJson(Map<String, dynamic> json) {
    return TaskSummary(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      dueOn: json['due_on'] as String,
      dueTime: json['due_time'] as String?,
      priority: json['priority'] as String,
      status: json['status'] as String,
      rabbitIdentifier: json['rabbit_identifier'] as String?,
      locationName: json['location_name'] as String?,
    );
  }

  final String id;
  final String type;
  final String title;
  final String? description;
  final String dueOn;
  final String? dueTime;
  final String priority;
  final String status;
  final String? rabbitIdentifier;
  final String? locationName;
}

class TaskSummaryCounts {
  const TaskSummaryCounts({
    required this.today,
    required this.overdue,
    required this.open,
  });

  factory TaskSummaryCounts.fromJson(Map<String, dynamic> json) {
    return TaskSummaryCounts(
      today: json['today'] as int,
      overdue: json['overdue'] as int,
      open: json['open'] as int,
    );
  }

  final int today;
  final int overdue;
  final int open;
}
