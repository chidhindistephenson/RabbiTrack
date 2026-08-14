import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/breeding/mating_controller.dart';
import 'package:rabbitrack_mobile/src/features/breeding/mating_models.dart';
import 'package:rabbitrack_mobile/src/features/litters/kindling_create_screen.dart';
import 'package:rabbitrack_mobile/src/features/rabbits/rabbit_controller.dart';
import 'package:rabbitrack_mobile/src/features/rabbits/rabbit_models.dart';

void main() {
  testWidgets('KindlingCreateScreen allows doe selection without mating', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(matings: const [], rabbits: _rabbits));
    await tester.pumpAndSettle();

    expect(find.text('Doe'), findsOneWidget);
    expect(find.text('Birth litter weight kg'), findsOneWidget);
    expect(
      find.text(
        'Enter the total litter weight; average per kit is calculated.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Doe'));
    await tester.pumpAndSettle();
    expect(find.text('DOE-0001 - Luna'), findsOneWidget);
    expect(find.text('BUCK-0001 - Atlas'), findsNothing);
    expect(find.text('DOE-0002 - Hazel'), findsNothing);
  });

  testWidgets('KindlingCreateScreen shows empty state without eligible does', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(matings: const [], rabbits: const []));
    await tester.pumpAndSettle();

    expect(find.text('No doe ready for kindling'), findsOneWidget);
    expect(find.text('Add rabbit'), findsOneWidget);
    expect(find.text('Save kindling'), findsNothing);
  });

  testWidgets('KindlingCreateScreen preselects initial mating', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _testApp(
        matings: _matings,
        rabbits: _rabbits,
        initialMatingId: 'mating-1',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('DOE-0001 x BUCK-0001'), findsOneWidget);
    expect(find.text('Birth litter weight kg'), findsOneWidget);
    expect(find.text('Save kindling'), findsOneWidget);
  });
}

Widget _testApp({
  required List<MatingSummary> matings,
  required List<RabbitSummary> rabbits,
  String? initialMatingId,
}) {
  return ProviderScope(
    overrides: [
      matingListProvider.overrideWith((ref) async => matings),
      rabbitListProvider.overrideWith((ref) async => rabbits),
    ],
    child: MaterialApp(
      home: KindlingCreateScreen(initialMatingId: initialMatingId),
    ),
  );
}

const _matings = [
  MatingSummary(
    id: 'mating-1',
    doeId: 'doe-1',
    doeIdentifier: 'DOE-0001',
    buckIdentifier: 'BUCK-0001',
    pregnancyCheckDueOn: '2026-08-01',
    expectedKindlingOn: '2026-08-27',
    status: 'pregnant',
  ),
];

const _rabbits = [
  RabbitSummary(
    id: 'doe-1',
    identifier: 'DOE-0001',
    name: 'Luna',
    sex: 'female',
    status: 'pregnant',
  ),
  RabbitSummary(
    id: 'buck-1',
    identifier: 'BUCK-0001',
    name: 'Atlas',
    sex: 'male',
    status: 'available_for_breeding',
  ),
  RabbitSummary(
    id: 'doe-2',
    identifier: 'DOE-0002',
    name: 'Hazel',
    sex: 'female',
    status: 'retired',
  ),
];
