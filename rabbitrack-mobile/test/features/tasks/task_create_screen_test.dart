import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/locations/location_controller.dart';
import 'package:rabbitrack_mobile/src/features/locations/location_models.dart';
import 'package:rabbitrack_mobile/src/features/rabbits/rabbit_controller.dart';
import 'package:rabbitrack_mobile/src/features/rabbits/rabbit_models.dart';
import 'package:rabbitrack_mobile/src/features/tasks/task_create_screen.dart';

void main() {
  testWidgets('TaskCreateScreen exposes due time and optional targets', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          rabbitListProvider.overrideWith((ref) async => _rabbits),
          locationListProvider.overrideWith((ref) async => _locations),
        ],
        child: const MaterialApp(home: TaskCreateScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Due time'), findsOneWidget);
    expect(find.text('Any time'), findsOneWidget);
    expect(find.text('Rabbit'), findsOneWidget);
    expect(find.text('Location'), findsOneWidget);

    await tester.tap(find.byType(DropdownButtonFormField<String>).at(1));
    await tester.pumpAndSettle();
    expect(find.text('No rabbit'), findsOneWidget);
    expect(find.text('DOE-0001 - Luna'), findsOneWidget);
    expect(find.text('DOE-0002 - Hazel'), findsNothing);
  });
}

const _rabbits = [
  RabbitSummary(
    id: 'rabbit-1',
    identifier: 'DOE-0001',
    name: 'Luna',
    sex: 'female',
    status: 'growing',
  ),
  RabbitSummary(
    id: 'rabbit-2',
    identifier: 'DOE-0002',
    name: 'Hazel',
    sex: 'female',
    status: 'sold',
  ),
];

const _locations = [
  FarmLocationSummary(
    id: 'location-1',
    type: 'cage',
    name: 'Cage A',
    code: 'A1',
    isActive: true,
    occupiedCount: 1,
  ),
];
