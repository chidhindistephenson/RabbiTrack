import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/breeding/mating_create_screen.dart';
import 'package:rabbitrack_mobile/src/features/rabbits/rabbit_controller.dart';
import 'package:rabbitrack_mobile/src/features/rabbits/rabbit_models.dart';

void main() {
  testWidgets('MatingCreateScreen shows empty state without a breeding pair', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(const []));
    await tester.pumpAndSettle();

    expect(find.text('Available breeding pair needed'), findsOneWidget);
    expect(find.text('Add rabbit'), findsOneWidget);
    expect(find.text('Save mating'), findsNothing);
  });

  testWidgets('MatingCreateScreen exposes doe and buck choices', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(_rabbits));
    await tester.pumpAndSettle();

    expect(find.text('Doe'), findsOneWidget);
    expect(find.text('Buck'), findsOneWidget);
    expect(find.text('Mating date'), findsOneWidget);
    expect(find.text('Observed'), findsOneWidget);
    expect(find.text('Attempted'), findsOneWidget);
    expect(find.text('Uncertain'), findsOneWidget);
    expect(
      find.widgetWithText(TextFormField, 'Behavior observed'),
      findsOneWidget,
    );
    expect(find.widgetWithText(TextFormField, 'Notes'), findsOneWidget);

    await tester.tap(find.text('Doe'));
    await tester.pumpAndSettle();
    expect(find.text('DOE-0001 - Luna'), findsOneWidget);
    expect(find.text('BUCK-0001 - Atlas'), findsNothing);
    await tester.tap(find.text('DOE-0001 - Luna'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Buck'));
    await tester.pumpAndSettle();
    expect(find.text('BUCK-0001 - Atlas'), findsOneWidget);
    expect(find.text('RAB-0001 - Mystery'), findsNothing);
  });

  testWidgets('MatingCreateScreen hides does with unresolved breeding status', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(_rabbitsWithOpenDoe));
    await tester.pumpAndSettle();

    expect(find.text('Available breeding pair needed'), findsOneWidget);
    expect(find.text('DOE-0002 - Busy'), findsNothing);
    expect(find.text('Save mating'), findsNothing);
  });
}

Widget _testApp(List<RabbitSummary> rabbits) {
  return ProviderScope(
    overrides: [rabbitListProvider.overrideWith((ref) async => rabbits)],
    child: const MaterialApp(home: MatingCreateScreen()),
  );
}

const _rabbits = [
  RabbitSummary(
    id: 'doe-1',
    identifier: 'DOE-0001',
    name: 'Luna',
    sex: 'female',
    status: 'available_for_breeding',
  ),
  RabbitSummary(
    id: 'buck-1',
    identifier: 'BUCK-0001',
    name: 'Atlas',
    sex: 'male',
    status: 'available_for_breeding',
  ),
  RabbitSummary(
    id: 'unknown-1',
    identifier: 'RAB-0001',
    name: 'Mystery',
    sex: 'unknown',
    status: 'growing',
  ),
];

const _rabbitsWithOpenDoe = [
  RabbitSummary(
    id: 'doe-2',
    identifier: 'DOE-0002',
    name: 'Busy',
    sex: 'female',
    status: 'awaiting_pregnancy_check',
  ),
  RabbitSummary(
    id: 'buck-1',
    identifier: 'BUCK-0001',
    name: 'Atlas',
    sex: 'male',
    status: 'available_for_breeding',
  ),
];
