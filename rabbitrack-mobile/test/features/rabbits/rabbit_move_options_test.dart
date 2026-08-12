import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/locations/location_models.dart';
import 'package:rabbitrack_mobile/src/features/rabbits/rabbit_models.dart';
import 'package:rabbitrack_mobile/src/features/rabbits/rabbit_move_options.dart';

void main() {
  test('rabbitMoveDestinations excludes inactive and current locations', () {
    final destinations = rabbitMoveDestinations(
      locations: _locations,
      rabbit: _rabbit,
    );

    expect(destinations.map((location) => location.id), ['location-2']);
  });

  test('rabbitMoveTitle includes name when available', () {
    expect(rabbitMoveTitle(_rabbit), 'DOE-0001 - Luna');
    expect(rabbitMoveTitle(_unnamedRabbit), 'BUCK-0001');
  });

  test('rabbitCurrentLocationText describes missing and present locations', () {
    expect(rabbitCurrentLocationText(_rabbit), 'Current location: Cage A');
    expect(
      rabbitCurrentLocationText(_unnamedRabbit),
      'Current location: No location',
    );
  });
}

const _rabbit = RabbitDetail(
  id: 'rabbit-1',
  identifier: 'DOE-0001',
  name: 'Luna',
  sex: 'female',
  status: 'growing',
  currentLocationId: 'location-1',
  currentLocationName: 'Cage A',
  movements: [],
);

const _unnamedRabbit = RabbitDetail(
  id: 'rabbit-2',
  identifier: 'BUCK-0001',
  sex: 'male',
  status: 'growing',
  movements: [],
);

const _locations = [
  FarmLocationSummary(
    id: 'location-1',
    type: 'cage',
    name: 'Cage A',
    isActive: true,
    occupiedCount: 1,
  ),
  FarmLocationSummary(
    id: 'location-2',
    type: 'cage',
    name: 'Cage B',
    isActive: true,
    occupiedCount: 0,
  ),
  FarmLocationSummary(
    id: 'location-3',
    type: 'cage',
    name: 'Inactive Cage',
    isActive: false,
    occupiedCount: 0,
  ),
];
