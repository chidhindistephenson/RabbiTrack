import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/locations/location_controller.dart';
import 'package:rabbitrack_mobile/src/features/locations/location_models.dart';
import 'package:rabbitrack_mobile/src/features/rabbits/rabbit_controller.dart';
import 'package:rabbitrack_mobile/src/features/rabbits/rabbit_create_screen.dart';
import 'package:rabbitrack_mobile/src/features/rabbits/rabbit_models.dart';

void main() {
  testWidgets('RabbitCreateScreen explains automatic ID assignment', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [locationListProvider.overrideWith((ref) async => [])],
        child: const MaterialApp(home: RabbitCreateScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Rabbit ID will be assigned automatically after saving.'),
      findsOneWidget,
    );
    expect(find.widgetWithText(TextFormField, 'Rabbit ID'), findsNothing);
    expect(find.widgetWithText(TextFormField, 'Name'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Date of birth'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Weight'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Tag or tattoo'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Notes'), findsOneWidget);
    expect(find.text('No location'), findsOneWidget);
    expect(find.text('No breed selected'), findsOneWidget);
  });

  testWidgets(
    'RabbitCreateScreen keeps dropdowns usable on narrow Android width',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 780));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            locationListProvider.overrideWith((ref) async => _locations),
            rabbitParentOptionsProvider.overrideWith(
              (ref) async => _parentRabbits,
            ),
          ],
          child: const MaterialApp(home: RabbitCreateScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Growing'));
      await tester.pumpAndSettle();
      expect(find.text('Available for breeding'), findsOneWidget);
      await tester.tap(find.text('Available for breeding'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('No location'));
      await tester.pumpAndSettle();
      expect(
        find.text('Grow-out cage with a very long label - GROW-001'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('RabbitCreateScreen supports listed and custom breeds', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [locationListProvider.overrideWith((ref) async => [])],
        child: const MaterialApp(home: RabbitCreateScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('No breed selected'));
    await tester.pumpAndSettle();

    expect(find.text('Phendula'), findsOneWidget);
    expect(find.text('New Zealand White'), findsOneWidget);

    await tester.tap(find.text('Custom').last);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextFormField, 'Custom breed'), findsOneWidget);
  });

  testWidgets('RabbitCreateScreen hides pregnancy statuses for male rabbits', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [locationListProvider.overrideWith((ref) async => [])],
        child: const MaterialApp(home: RabbitCreateScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Female'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Male').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Growing'));
    await tester.pumpAndSettle();

    expect(find.text('Pregnant'), findsNothing);
    expect(find.text('Nursing'), findsNothing);
    expect(find.text('Ready for sale'), findsOneWidget);
  });

  testWidgets('RabbitCreateScreen shows sex-filtered parent choices', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          locationListProvider.overrideWith((ref) async => []),
          rabbitParentOptionsProvider.overrideWith(
            (ref) async => _parentRabbits,
          ),
        ],
        child: const MaterialApp(home: RabbitCreateScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No mother selected'), findsOneWidget);
    expect(find.text('No father selected'), findsOneWidget);

    await tester.tap(find.text('No mother selected'));
    await tester.pumpAndSettle();
    expect(find.text('DOE-0001 - Luna'), findsOneWidget);
    expect(find.text('DOE-0002 - Archived'), findsNothing);
    expect(find.text('BUCK-0001 - Atlas'), findsNothing);
    await tester.tap(find.text('DOE-0001 - Luna'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('No father selected'));
    await tester.pumpAndSettle();
    expect(find.text('BUCK-0001 - Atlas'), findsOneWidget);
    expect(find.text('BUCK-0002 - Sold Buck'), findsNothing);
    expect(find.text('RAB-0001 - Mystery'), findsNothing);
  });
}

const _locations = [
  FarmLocationSummary(
    id: 'location-1',
    type: 'cage',
    name: 'Grow-out cage with a very long label',
    code: 'GROW-001',
    isActive: true,
    occupiedCount: 0,
  ),
];

const _parentRabbits = [
  RabbitSummary(
    id: 'doe-1',
    identifier: 'DOE-0001',
    name: 'Luna',
    sex: 'female',
    status: 'growing',
  ),
  RabbitSummary(
    id: 'buck-1',
    identifier: 'BUCK-0001',
    name: 'Atlas',
    sex: 'male',
    status: 'growing',
  ),
  RabbitSummary(
    id: 'doe-2',
    identifier: 'DOE-0002',
    name: 'Archived',
    sex: 'female',
    status: 'deceased',
  ),
  RabbitSummary(
    id: 'buck-2',
    identifier: 'BUCK-0002',
    name: 'Sold Buck',
    sex: 'male',
    status: 'sold',
  ),
  RabbitSummary(
    id: 'unknown-1',
    identifier: 'RAB-0001',
    name: 'Mystery',
    sex: 'unknown',
    status: 'growing',
  ),
];
