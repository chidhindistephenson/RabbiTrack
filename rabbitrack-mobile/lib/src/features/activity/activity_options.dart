String activityActionLabel(String action) {
  final area = action.split('.').first;

  return switch (area) {
    'sale' => 'Sale',
    'expense' => 'Expense',
    'team' => 'Team',
    'farm' => 'Farm',
    _ => _sentenceCase(area),
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
