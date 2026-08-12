const healthBodySystems = [
  'Digestive',
  'Respiratory',
  'Skin / coat',
  'Eyes',
  'Ears',
  'Teeth',
  'Reproductive',
  'Injury',
  'Parasites',
  'General',
];

String healthStatusLabel(String status) {
  return switch (status) {
    'open' => 'Open',
    'monitoring' => 'Monitoring',
    'resolved' => 'Resolved',
    'closed' => 'Closed',
    _ => _sentenceCase(status),
  };
}

String healthSeverityLabel(String severity) {
  return switch (severity) {
    'mild' => 'Mild',
    'moderate' => 'Moderate',
    'severe' => 'Severe',
    'critical' => 'Critical',
    _ => _sentenceCase(severity),
  };
}

String healthBodySystemValue(String label) {
  return label.toLowerCase().replaceAll(' / ', '_').replaceAll(' ', '_');
}

String healthBodySystemLabel(String? value) {
  if (value == null || value.isEmpty) {
    return 'General';
  }

  for (final label in healthBodySystems) {
    if (healthBodySystemValue(label) == value) {
      return label;
    }
  }

  return _sentenceCase(value);
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
