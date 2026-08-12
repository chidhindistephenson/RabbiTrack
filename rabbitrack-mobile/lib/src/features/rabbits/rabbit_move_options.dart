import '../locations/location_models.dart';
import 'rabbit_models.dart';

List<FarmLocationSummary> rabbitMoveDestinations({
  required List<FarmLocationSummary> locations,
  required RabbitDetail rabbit,
}) {
  return [
    for (final location in locations)
      if (location.isActive && location.id != rabbit.currentLocationId)
        location,
  ];
}

String rabbitMoveTitle(RabbitDetail rabbit) {
  final name = rabbit.name?.trim();

  return name == null || name.isEmpty
      ? rabbit.identifier
      : '${rabbit.identifier} - $name';
}

String rabbitCurrentLocationText(RabbitDetail rabbit) {
  return 'Current location: ${rabbit.currentLocationName ?? 'No location'}';
}
