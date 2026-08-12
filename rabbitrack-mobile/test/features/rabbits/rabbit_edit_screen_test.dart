import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/rabbits/rabbit_controller.dart';
import 'package:rabbitrack_mobile/src/features/rabbits/rabbit_edit_screen.dart';
import 'package:rabbitrack_mobile/src/features/rabbits/rabbit_models.dart';

void main() {
  testWidgets('RabbitEditScreen pre-fills existing rabbit profile', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          rabbitDetailProvider('rabbit-1').overrideWith((ref) async => _rabbit),
          rabbitParentOptionsProvider.overrideWith((ref) async => []),
        ],
        child: const MaterialApp(home: RabbitEditScreen(rabbitId: 'rabbit-1')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Edit rabbit'), findsOneWidget);
    expect(find.text('BUCK-0003'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Atlas'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '2025-01-14'), findsOneWidget);
    expect(find.text('Male'), findsOneWidget);
    expect(find.text('Ready for sale'), findsOneWidget);
    expect(find.text('New Zealand White'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'White'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '3.4'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'TAG-42'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Strong buck'), findsOneWidget);
    expect(find.text('Save changes'), findsOneWidget);
  });

  testWidgets('RabbitEditScreen keeps pregnancy statuses hidden for males', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          rabbitDetailProvider('rabbit-1').overrideWith((ref) async => _rabbit),
          rabbitParentOptionsProvider.overrideWith((ref) async => []),
        ],
        child: const MaterialApp(home: RabbitEditScreen(rabbitId: 'rabbit-1')),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ready for sale'));
    await tester.pumpAndSettle();

    expect(find.text('Pregnant'), findsNothing);
    expect(find.text('Nursing'), findsNothing);
    expect(find.text('Available for breeding'), findsOneWidget);
  });

  testWidgets('RabbitEditScreen shows sex-filtered editable parents', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          rabbitDetailProvider(
            'rabbit-1',
          ).overrideWith((ref) async => _rabbitWithParents),
          rabbitParentOptionsProvider.overrideWith(
            (ref) async => _parentOptions,
          ),
        ],
        child: const MaterialApp(home: RabbitEditScreen(rabbitId: 'rabbit-1')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('DOE-0001 - Luna'), findsOneWidget);
    expect(find.text('BUCK-0001 - Odin'), findsOneWidget);

    await tester.tap(find.text('DOE-0001 - Luna'));
    await tester.pumpAndSettle();
    expect(find.text('DOE-0002 - Freya'), findsOneWidget);
    expect(find.text('DOE-0003 - Retired Doe'), findsNothing);
    expect(find.text('BUCK-0001 - Odin'), findsOneWidget);
    await tester.tap(find.text('DOE-0002 - Freya'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('BUCK-0001 - Odin'));
    await tester.pumpAndSettle();
    expect(find.text('BUCK-0003 - Atlas'), findsNothing);
    expect(find.text('BUCK-0004 - Sold Buck'), findsNothing);
    expect(find.text('RAB-0001 - Mystery'), findsNothing);
  });
}

const _rabbit = RabbitDetail(
  id: 'rabbit-1',
  identifier: 'BUCK-0003',
  name: 'Atlas',
  sex: 'male',
  status: 'ready_for_sale',
  movements: [],
  breed: 'New Zealand White',
  colour: 'White',
  dateOfBirth: '2025-01-14',
  weightValue: '3.4',
  weightUnit: 'kg',
  tagOrTattoo: 'TAG-42',
  notes: 'Strong buck',
);

const _rabbitWithParents = RabbitDetail(
  id: 'rabbit-1',
  identifier: 'BUCK-0003',
  name: 'Atlas',
  sex: 'male',
  status: 'ready_for_sale',
  movements: [],
  mother: RabbitParent(id: 'doe-1', identifier: 'DOE-0001', name: 'Luna'),
  father: RabbitParent(id: 'buck-1', identifier: 'BUCK-0001', name: 'Odin'),
);

const _parentOptions = [
  RabbitSummary(
    id: 'rabbit-1',
    identifier: 'BUCK-0003',
    name: 'Atlas',
    sex: 'male',
    status: 'ready_for_sale',
  ),
  RabbitSummary(
    id: 'doe-1',
    identifier: 'DOE-0001',
    name: 'Luna',
    sex: 'female',
    status: 'growing',
  ),
  RabbitSummary(
    id: 'doe-2',
    identifier: 'DOE-0002',
    name: 'Freya',
    sex: 'female',
    status: 'growing',
  ),
  RabbitSummary(
    id: 'doe-3',
    identifier: 'DOE-0003',
    name: 'Retired Doe',
    sex: 'female',
    status: 'retired',
  ),
  RabbitSummary(
    id: 'buck-1',
    identifier: 'BUCK-0001',
    name: 'Odin',
    sex: 'male',
    status: 'growing',
  ),
  RabbitSummary(
    id: 'buck-4',
    identifier: 'BUCK-0004',
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
