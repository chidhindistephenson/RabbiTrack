import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/locations/location_controller.dart';
import 'package:rabbitrack_mobile/src/features/locations/location_list_screen.dart';
import 'package:rabbitrack_mobile/src/features/locations/location_models.dart';

void main() {
  testWidgets('LocationListScreen renders polished location row labels', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          locationListProvider.overrideWith((ref) async => _locations),
        ],
        child: const MaterialApp(home: LocationListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cage A'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);
    expect(find.text('2 locations'), findsOneWidget);
    expect(find.text('Status'), findsOneWidget);
    expect(find.text('1 active'), findsOneWidget);
    expect(find.text('Capacity'), findsOneWidget);
    expect(find.text('4 / 7 occupied'), findsOneWidget);
    expect(find.text('Cage | A1 | 3 / 5 occupied'), findsOneWidget);
  });
}

const _locations = [
  FarmLocationSummary(
    id: 'location-1',
    type: 'cage',
    name: 'Cage A',
    code: 'A1',
    capacity: 5,
    occupiedCount: 3,
    isActive: true,
  ),
  FarmLocationSummary(
    id: 'location-2',
    type: 'cage',
    name: 'Cage B',
    code: 'B1',
    capacity: 2,
    occupiedCount: 1,
    isActive: false,
  ),
];
