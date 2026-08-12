const expenseCategories = [
  'feed',
  'medicine',
  'equipment',
  'housing',
  'labour',
  'utilities',
  'transport',
  'other',
];

String expenseCategoryLabel(String category) {
  return switch (category) {
    'feed' => 'Feed',
    'medicine' => 'Medicine',
    'equipment' => 'Equipment',
    'housing' => 'Housing',
    'labour' => 'Labour',
    'utilities' => 'Utilities',
    'transport' => 'Transport',
    'other' => 'Other',
    _ => _sentenceCase(category),
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
