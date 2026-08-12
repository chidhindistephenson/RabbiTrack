const southernAfricaRabbitBreeds = [
  'Phendula',
  'New Zealand White',
  'Californian',
  'Chinchilla Rabbit',
  'Flemish Giant',
  'German Lop',
  'Netherland Dwarf',
  'Rex',
  'Dutch Rabbit',
  'Riverine Rabbit',
  "Hewitt's Red Rock Rabbit",
];

const rabbitStatuses = [
  'growing',
  'available_for_breeding',
  'mated',
  'awaiting_pregnancy_check',
  'pregnant',
  'nursing',
  'resting',
  'quarantined',
  'under_treatment',
  'ready_for_sale',
  'sold',
  'retired',
  'deceased',
  'culled',
];

const femaleOnlyRabbitStatuses = ['pregnant', 'nursing'];

const terminalRabbitStatuses = ['sold', 'retired', 'deceased', 'culled'];

bool isTerminalRabbitStatus(String status) {
  return terminalRabbitStatuses.contains(status);
}

String rabbitSexLabel(String sex) {
  return switch (sex) {
    'female' => 'Female',
    'male' => 'Male',
    _ => 'Unknown',
  };
}

String rabbitSexInitial(String sex) {
  return switch (sex) {
    'female' => 'D',
    'male' => 'B',
    _ => '?',
  };
}

List<String> rabbitStatusesForSex(String sex) {
  if (sex != 'male') {
    return rabbitStatuses;
  }

  return [
    for (final status in rabbitStatuses)
      if (!femaleOnlyRabbitStatuses.contains(status)) status,
  ];
}

List<String> editableRabbitStatusesForSex(String sex) {
  return [
    for (final status in rabbitStatusesForSex(sex))
      if (status != 'sold') status,
  ];
}

String rabbitStatusLabel(String status) {
  return switch (status) {
    'available_for_breeding' => 'Available for breeding',
    'awaiting_pregnancy_check' => 'Awaiting pregnancy check',
    'under_treatment' => 'Under treatment',
    'ready_for_sale' => 'Ready for sale',
    _ =>
      status
          .split('_')
          .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
          .join(' '),
  };
}

String compactRabbitStatusLabel(String status) {
  return switch (status) {
    'available_for_breeding' => 'breeding',
    'awaiting_pregnancy_check' => 'pregnancy check',
    'under_treatment' => 'treatment',
    'ready_for_sale' => 'ready for sale',
    _ => status.replaceAll('_', ' '),
  };
}
