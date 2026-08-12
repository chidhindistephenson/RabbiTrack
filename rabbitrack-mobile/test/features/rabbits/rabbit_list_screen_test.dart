import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/rabbits/rabbit_controller.dart';
import 'package:rabbitrack_mobile/src/features/rabbits/rabbit_list_screen.dart';
import 'package:rabbitrack_mobile/src/features/rabbits/rabbit_models.dart';

void main() {
  testWidgets('RabbitListScreen renders filters on narrow Android width', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 780));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_testApp(_rabbits));
    await tester.pumpAndSettle();

    expect(find.text('Rabbits'), findsOneWidget);
    expect(find.text('Search ID, name, breed, or tag'), findsOneWidget);
    expect(find.text('2 total rabbits'), findsOneWidget);
    expect(find.text('All breeds'), findsOneWidget);
    expect(find.text('ready for sale'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('RabbitListScreen exposes breed filtering', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_testApp(_rabbits));
    await tester.pumpAndSettle();

    await tester.tap(find.text('All breeds'));
    await tester.pumpAndSettle();

    expect(find.text('Phendula'), findsOneWidget);
    expect(find.text('New Zealand White'), findsOneWidget);

    await tester.tap(find.text('New Zealand White').last);
    await tester.pumpAndSettle();

    expect(find.text('New Zealand White'), findsWidgets);
    expect(find.text('Filtered'), findsOneWidget);
    expect(find.text('2 matching rabbits'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('RabbitListScreen keeps filters usable on wider Android width', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(432, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_testApp(_rabbits));
    await tester.pumpAndSettle();

    expect(find.text('Sex'), findsOneWidget);
    expect(find.text('Status'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('RabbitListScreen keeps multi-character search input', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(_rabbits));
    await tester.pumpAndSettle();

    final searchField = find.byType(TextField);

    await tester.tap(searchField);
    await tester.enterText(searchField, 'Atlas');
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Atlas'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Widget _testApp(List<RabbitSummary> rabbits) {
  return ProviderScope(
    overrides: [rabbitListProvider.overrideWith((ref) async => rabbits)],
    child: const MaterialApp(home: RabbitListScreen()),
  );
}

const _rabbits = [
  RabbitSummary(
    id: 'rabbit-1',
    identifier: 'BUCK-0003',
    name: 'Atlas',
    sex: 'male',
    breed: 'New Zealand White',
    status: 'ready_for_sale',
    currentLocationName: 'Cage 1495',
  ),
  RabbitSummary(
    id: 'rabbit-2',
    identifier: 'DOE-SMOKE-8116',
    sex: 'female',
    status: 'awaiting_pregnancy_check',
  ),
];
