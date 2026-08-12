const farmRoles = [
  'owner',
  'administrator',
  'manager',
  'worker',
  'veterinarian',
  'viewer',
];

const assignableFarmRoles = [
  'administrator',
  'manager',
  'worker',
  'veterinarian',
  'viewer',
];

String farmRoleLabel(String role) {
  return switch (role) {
    'owner' => 'Owner',
    'administrator' => 'Administrator',
    'manager' => 'Manager',
    'worker' => 'Worker',
    'veterinarian' => 'Veterinarian',
    'viewer' => 'Viewer',
    _ => _sentenceCase(role),
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
