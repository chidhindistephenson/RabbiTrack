import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/locations/location_controller.dart';
import 'package:rabbitrack_mobile/src/features/locations/location_detail_screen.dart';
import 'package:rabbitrack_mobile/src/features/locations/location_models.dart';

void main() {
  testWidgets('LocationDetailScreen renders capacity and rabbit labels', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          locationDetailProvider(
            'location-1',
          ).overrideWith((ref) async => _location),
        ],
        child: const MaterialApp(
          home: LocationDetailScreen(locationId: 'location-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cage A'), findsOneWidget);
    expect(find.text('3 / 5 occupied'), findsWidgets);
    expect(find.text('2 spaces available'), findsOneWidget);
    expect(find.text('Notes'), findsOneWidget);
    expect(find.text('Keep shaded in the afternoon.'), findsOneWidget);
    expect(find.text('DOE-0001 - Luna'), findsOneWidget);
    expect(find.text('Ready for sale'), findsOneWidget);
    expect(find.byTooltip('Edit location'), findsOneWidget);
  });

  testWidgets('LocationDetailScreen renders empty notes state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          locationDetailProvider(
            'location-1',
          ).overrideWith((ref) async => _locationWithoutNotes),
        ],
        child: const MaterialApp(
          home: LocationDetailScreen(locationId: 'location-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No notes recorded'), findsOneWidget);
    expect(find.text('Full'), findsOneWidget);
  });
}

const _location = FarmLocationDetail(
  id: 'location-1',
  type: 'cage',
  name: 'Cage A',
  code: 'A1',
  capacity: 5,
  occupiedCount: 3,
  isActive: true,
  notes: 'Keep shaded in the afternoon.',
  rabbits: [
    LocationRabbitSummary(
      id: 'rabbit-1',
      identifier: 'DOE-0001',
      name: 'Luna',
      sex: 'female',
      status: 'ready_for_sale',
    ),
  ],
);

const _locationWithoutNotes = FarmLocationDetail(
  id: 'location-1',
  type: 'cage',
  name: 'Cage B',
  capacity: 2,
  occupiedCount: 2,
  isActive: true,
  rabbits: [],
);
