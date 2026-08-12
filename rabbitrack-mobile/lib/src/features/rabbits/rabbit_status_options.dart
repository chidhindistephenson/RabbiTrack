import 'rabbit_options.dart';

String rabbitStatusScreenTitle({required String identifier, String? name}) {
  final trimmedName = name?.trim();

  return trimmedName == null || trimmedName.isEmpty
      ? identifier
      : '$identifier - $trimmedName';
}

String rabbitStatusSexHint(String sex) {
  return switch (sex) {
    'male' => 'Pregnant and nursing are hidden because this rabbit is male.',
    'female' => 'Female reproductive statuses are available for this rabbit.',
    _ =>
      'Set the rabbit sex in Edit profile to unlock sex-specific status rules.',
  };
}

String rabbitCurrentStatusText(String status) {
  return 'Current status: ${rabbitStatusLabel(status)}';
}
