String taskTypeLabel(String type) {
  return switch (type) {
    'manual' => 'Manual',
    'pregnancy_check' => 'Pregnancy check',
    'nest_box_preparation' => 'Nest box',
    'expected_kindling' => 'Kindling',
    'weaning' => 'Weaning',
    'kit_identification' => 'Identify/tag kits',
    'retirement_review' => 'Retirement review',
    _ => _sentenceCase(type),
  };
}

String taskPriorityLabel(String priority) {
  return switch (priority) {
    'low' => 'Low',
    'normal' => 'Normal',
    'high' => 'High',
    'critical' => 'Critical',
    _ => _sentenceCase(priority),
  };
}

String taskStatusLabel(String status) {
  return switch (status) {
    'open' => 'Open',
    'completed' => 'Completed',
    'cancelled' => 'Cancelled',
    'snoozed' => 'Snoozed',
    _ => _sentenceCase(status),
  };
}

String taskDueLabel(String dueOn, String? dueTime) {
  if (dueTime == null || dueTime.isEmpty) {
    return dueOn;
  }

  return '$dueOn at $dueTime';
}

String taskDueFilterTitle(String filter) {
  return switch (filter) {
    'today' => 'Today',
    'overdue' => 'Overdue',
    'upcoming' => 'Upcoming',
    _ => 'All',
  };
}

String _sentenceCase(String value) {
  final words = value.split('_').where((part) => part.isNotEmpty).toList();

  if (words.isEmpty) {
    return value;
  }

  return [
    '${words.first[0].toUpperCase()}${words.first.substring(1)}',
    ...words.skip(1),
  ].join(' ');
}
