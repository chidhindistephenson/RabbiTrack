String breedingStatusLabel(String status) {
  return switch (status) {
    'awaiting_pregnancy_check' => 'Awaiting pregnancy check',
    'pregnant' => 'Pregnant',
    'confirmed_pregnant' => 'Confirmed pregnant',
    'not_pregnant' => 'Not pregnant',
    'kindled' => 'Kindled',
    'closed' => 'Closed',
    _ => _titleCase(status),
  };
}

bool canRecordPregnancyCheck(String status) {
  return status == 'awaiting_pregnancy_check' || status == 'uncertain';
}

bool isPregnancyCheckDue({
  required String status,
  required String dueOn,
  DateTime? today,
}) {
  if (!canRecordPregnancyCheck(status)) {
    return false;
  }

  final dueDate = DateTime.tryParse(dueOn);
  if (dueDate == null) {
    return false;
  }

  final current = today ?? DateTime.now();
  final currentDate = DateTime(current.year, current.month, current.day);
  final dueDateOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);

  return !currentDate.isBefore(dueDateOnly);
}

bool canSelectDoeForMating(String status) {
  return status == 'available_for_breeding';
}

bool canSelectBuckForMating(String status) {
  return status == 'available_for_breeding';
}

bool canRevisePregnancyDecision(String status) {
  return status == 'pregnant' ||
      status == 'not_pregnant' ||
      status == 'uncertain';
}

bool canRecordKindling(String status) {
  return status == 'pregnant';
}

String pregnancyCheckResultLabel(String result) {
  return switch (result) {
    'not_pregnant' => 'Not pregnant',
    'not_checked' => 'Not checked',
    _ => _titleCase(result),
  };
}

String matingOutcomeLabel(String? outcome) {
  if (outcome == null) {
    return '-';
  }

  return _titleCase(outcome);
}

String _titleCase(String value) {
  return value
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}
