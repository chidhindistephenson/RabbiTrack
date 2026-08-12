import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/breeding/mating_controller.dart';
import 'package:rabbitrack_mobile/src/features/breeding/mating_models.dart';
import 'package:rabbitrack_mobile/src/features/breeding/pregnancy_check_screen.dart';

void main() {
  testWidgets('PregnancyCheckScreen renders mating context and notes', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(_matings));
    await tester.pumpAndSettle();

    expect(find.text('DOE-0001'), findsOneWidget);
    expect(find.text('Mated with BUCK-0001'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Notes'), findsOneWidget);
    expect(find.text('Save result'), findsOneWidget);
  });

  testWidgets('PregnancyCheckScreen shows missing mating state', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(const []));
    await tester.pumpAndSettle();

    expect(find.text('Mating record not found'), findsOneWidget);
    expect(find.text('Back to breeding'), findsOneWidget);
  });

  testWidgets('PregnancyCheckScreen blocks completed mating checks', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp([_completedMating]));
    await tester.pumpAndSettle();

    expect(find.text('Pregnancy check already recorded'), findsOneWidget);
    expect(find.text('Save result'), findsNothing);
  });

  testWidgets('PregnancyCheckScreen blocks checks before due date', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp([_earlyMating]));
    await tester.pumpAndSettle();

    expect(find.text('Pregnancy check not due yet'), findsOneWidget);
    expect(
      find.text('This mating can be checked on 2099-08-10.'),
      findsOneWidget,
    );
    expect(find.text('Save result'), findsNothing);
  });
}

Widget _testApp(List<MatingSummary> matings) {
  return ProviderScope(
    overrides: [matingListProvider.overrideWith((ref) async => matings)],
    child: const MaterialApp(home: PregnancyCheckScreen(matingId: 'mating-1')),
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
    status: 'awaiting_pregnancy_check',
  ),
];

const _completedMating = MatingSummary(
  id: 'mating-1',
  doeId: 'doe-1',
  doeIdentifier: 'DOE-0001',
  buckIdentifier: 'BUCK-0001',
  pregnancyCheckDueOn: '2026-08-10',
  expectedKindlingOn: '2026-08-27',
  status: 'pregnant',
);

const _earlyMating = MatingSummary(
  id: 'mating-1',
  doeId: 'doe-1',
  doeIdentifier: 'DOE-0001',
  buckIdentifier: 'BUCK-0001',
  pregnancyCheckDueOn: '2099-08-10',
  expectedKindlingOn: '2099-08-27',
  status: 'awaiting_pregnancy_check',
);
