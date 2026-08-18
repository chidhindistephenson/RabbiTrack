import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/litters/litter_controller.dart';
import 'package:rabbitrack_mobile/src/features/litters/litter_detail_screen.dart';
import 'package:rabbitrack_mobile/src/features/litters/litter_models.dart';

void main() {
  testWidgets('LitterDetailScreen renders polished status and sections', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          litterDetailProvider('litter-1').overrideWith((ref) async => _litter),
        ],
        child: const MaterialApp(
          home: LitterDetailScreen(litterId: 'litter-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('LIT-260803-TEST'), findsOneWidget);
    expect(find.text('DOE-0001 x BUCK-0001 | Nursing'), findsOneWidget);
    expect(find.byTooltip('Record litter weight'), findsNothing);
    expect(find.byTooltip('Record weaning'), findsNothing);
    expect(find.text('Record check'), findsOneWidget);
    expect(find.text('Record foster'), findsOneWidget);
    expect(find.text('Record weaning'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -420));
    await tester.pumpAndSettle();

    expect(find.text('7 live, 1 dead, 2 weak'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -260));
    await tester.pumpAndSettle();

    expect(find.text('2 kits fostered out'), findsOneWidget);
    expect(
      find.text('To LIT-DEST | Reason: Balance litter sizes'),
      findsOneWidget,
    );

    await tester.drag(find.byType(ListView), const Offset(0, -260));
    await tester.pumpAndSettle();

    expect(
      find.text('7 weaned | avg 0.85 kg/kit | Grow-out cages'),
      findsOneWidget,
    );

    await tester.drag(find.byType(ListView), const Offset(0, -260));
    await tester.pumpAndSettle();

    expect(
      find.text('7.28 kg total | avg 0.91 kg/kit | 8 kits'),
      findsOneWidget,
    );
  });

  testWidgets('LitterDetailScreen shows identify kits for weaned litter', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          litterDetailProvider(
            'litter-1',
          ).overrideWith((ref) async => _weanedLitter),
        ],
        child: const MaterialApp(
          home: LitterDetailScreen(litterId: 'litter-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Record weaning'), findsNothing);
    expect(find.text('Identify kits'), findsOneWidget);
  });
}

const _litter = LitterDetail(
  id: 'litter-1',
  identifier: 'LIT-260803-TEST',
  doeId: 'doe-1',
  doeIdentifier: 'DOE-0001',
  buckId: 'buck-1',
  buckIdentifier: 'BUCK-0001',
  kindledOn: '2026-08-03',
  kitsBornAlive: 8,
  kitsStillborn: 1,
  kitsWeak: 2,
  currentLiveCount: 8,
  plannedWeaningOn: '2026-09-07',
  status: 'nursing',
  weanings: [
    LitterWeaningSummary(
      id: 'weaning-1',
      weanedOn: '2026-09-07',
      numberWeaned: 7,
      averageWeightValue: '0.85',
      weightUnit: 'kg',
      destination: 'Grow-out cages',
    ),
  ],
  checks: [
    LitterCheckSummary(
      id: 'check-1',
      checkedOn: '2026-08-20',
      liveCount: 7,
      deadCount: 1,
      weakCount: 2,
      suspectedCause: 'Chilling',
      nestObservation: 'Nest damp',
      correctiveAction: 'Changed bedding',
    ),
  ],
  fostersOut: [
    LitterFosterSummary(
      id: 'foster-1',
      fosteredOn: '2026-08-18',
      kitCount: 2,
      reason: 'Balance litter sizes',
      fromLitterId: 'litter-1',
      fromLitterIdentifier: 'LIT-260803-TEST',
      toLitterId: 'litter-2',
      toLitterIdentifier: 'LIT-DEST',
    ),
  ],
  fostersIn: [],
  weights: [
    LitterWeightSummary(
      id: 'weight-1',
      weighedOn: '2026-08-20',
      weightValue: '7.28',
      weightUnit: 'kg',
      stage: 'birth',
      kitCount: 8,
      averageWeightValue: '0.91',
    ),
  ],
);

const _weanedLitter = LitterDetail(
  id: 'litter-1',
  identifier: 'LIT-260803-TEST',
  doeId: 'doe-1',
  doeIdentifier: 'DOE-0001',
  buckId: 'buck-1',
  buckIdentifier: 'BUCK-0001',
  kindledOn: '2026-08-03',
  kitsBornAlive: 8,
  kitsStillborn: 1,
  kitsWeak: 2,
  currentLiveCount: 7,
  convertedRabbitsCount: 4,
  unconvertedKitsCount: 3,
  plannedWeaningOn: '2026-09-07',
  status: 'weaned',
  weanings: [],
  checks: [],
  fostersOut: [],
  fostersIn: [],
  weights: [],
);
