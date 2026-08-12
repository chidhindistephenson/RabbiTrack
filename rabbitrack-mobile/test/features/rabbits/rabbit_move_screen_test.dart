import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/locations/location_controller.dart';
import 'package:rabbitrack_mobile/src/features/locations/location_models.dart';
import 'package:rabbitrack_mobile/src/features/rabbits/rabbit_controller.dart';
import 'package:rabbitrack_mobile/src/features/rabbits/rabbit_models.dart';
import 'package:rabbitrack_mobile/src/features/rabbits/rabbit_move_screen.dart';

void main() {
  testWidgets('RabbitMoveScreen shows an empty state when no locations exist', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          locationListProvider.overrideWith((ref) async => []),
          rabbitDetailProvider('rabbit-1').overrideWith((ref) async => _rabbit),
        ],
        child: const MaterialApp(home: RabbitMoveScreen(rabbitId: 'rabbit-1')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No locations yet'), findsOneWidget);
    expect(find.text('Add location'), findsOneWidget);
    expect(find.text('Save movement'), findsNothing);
  });

  testWidgets('RabbitMoveScreen shows rabbit context and destination choices', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          locationListProvider.overrideWith((ref) async => _locations),
          rabbitDetailProvider('rabbit-1').overrideWith((ref) async => _rabbit),
        ],
        child: const MaterialApp(home: RabbitMoveScreen(rabbitId: 'rabbit-1')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('DOE-0001 - Luna'), findsOneWidget);
    expect(find.text('Current location: Cage A'), findsOneWidget);
    expect(find.text('Save movement'), findsOneWidget);

    await tester.tap(find.text('New location'));
    await tester.pumpAndSettle();

    expect(find.text('Cage B - B'), findsOneWidget);
    expect(find.text('Cage A - A'), findsNothing);
    expect(find.text('Inactive Cage'), findsNothing);
  });

  testWidgets(
    'RabbitMoveScreen blocks moves when only current location exists',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            locationListProvider.overrideWith(
              (ref) async => [_locations.first],
            ),
            rabbitDetailProvider(
              'rabbit-1',
            ).overrideWith((ref) async => _rabbit),
          ],
          child: const MaterialApp(
            home: RabbitMoveScreen(rabbitId: 'rabbit-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No destination available'), findsOneWidget);
      expect(find.text('Save movement'), findsNothing);
    },
  );

  testWidgets('RabbitMoveScreen locks terminal rabbits', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          locationListProvider.overrideWith((ref) async => _locations),
          rabbitDetailProvider(
            'rabbit-1',
          ).overrideWith((ref) async => _soldRabbit),
        ],
        child: const MaterialApp(home: RabbitMoveScreen(rabbitId: 'rabbit-1')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Movement locked'), findsOneWidget);
    expect(
      find.text('This rabbit is sold, so its movement history is read-only.'),
      findsOneWidget,
    );
    expect(find.text('Save movement'), findsNothing);
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

const _soldRabbit = RabbitDetail(
  id: 'rabbit-1',
  identifier: 'DOE-0001',
  name: 'Luna',
  sex: 'female',
  status: 'sold',
  currentLocationId: 'location-1',
  currentLocationName: 'Cage A',
  movements: [],
);

const _locations = [
  FarmLocationSummary(
    id: 'location-1',
    type: 'cage',
    name: 'Cage A',
    code: 'A',
    isActive: true,
    occupiedCount: 1,
  ),
  FarmLocationSummary(
    id: 'location-2',
    type: 'cage',
    name: 'Cage B',
    code: 'B',
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
