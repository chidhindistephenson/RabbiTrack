String litterStatusLabel(String status) {
  return switch (status) {
    'nursing' => 'Nursing',
    'weaned' => 'Weaned',
    'closed' => 'Closed',
    _ => _titleCase(status),
  };
}

String _titleCase(String value) {
  final words = value.split('_').where((part) => part.isNotEmpty).toList();

  if (words.isEmpty) {
    return value;
  }

  return [
    '${words.first[0].toUpperCase()}${words.first.substring(1)}',
    ...words.skip(1),
  ].join(' ');
}
