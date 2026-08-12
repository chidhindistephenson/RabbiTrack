import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/locations/location_controller.dart';
import 'package:rabbitrack_mobile/src/features/locations/location_edit_screen.dart';
import 'package:rabbitrack_mobile/src/features/locations/location_models.dart';

void main() {
  testWidgets('LocationEditScreen renders prefilled location fields', (
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
          home: LocationEditScreen(locationId: 'location-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Edit location'), findsOneWidget);
    expect(find.text('Cage setup'), findsOneWidget);
    expect(find.text('Cage A'), findsOneWidget);
    expect(find.text('A1'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('Keep shaded in the afternoon.'), findsOneWidget);
    expect(
      find.text('Move assigned rabbits before deactivating.'),
      findsOneWidget,
    );
    expect(find.text('Save location'), findsOneWidget);
  });

  testWidgets('LocationEditScreen blocks capacity below current occupancy', (
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
          home: LocationEditScreen(locationId: 'location-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(2), '2');
    await tester.tap(find.text('Save location'));
    await tester.pumpAndSettle();

    expect(
      find.text('Capacity cannot be below current occupancy'),
      findsOneWidget,
    );
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
  rabbits: [],
);
