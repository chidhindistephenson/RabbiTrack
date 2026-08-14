import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/breeding/mating_controller.dart';
import 'package:rabbitrack_mobile/src/features/breeding/mating_detail_screen.dart';
import 'package:rabbitrack_mobile/src/features/breeding/mating_models.dart';

void main() {
  testWidgets('MatingDetailScreen renders polished labels', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          matingDetailProvider('mating-1').overrideWith((ref) async => _mating),
        ],
        child: const MaterialApp(
          home: MatingDetailScreen(matingId: 'mating-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('DOE-0001 x BUCK-0001'), findsOneWidget);
    expect(find.text('Awaiting pregnancy check'), findsAtLeastNWidgets(1));
    expect(find.text('Breeding timeline'), findsOneWidget);
    expect(find.text('Observed'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -420));
    await tester.pumpAndSettle();

    expect(find.text('Not pregnant'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -420));
    await tester.pumpAndSettle();

    expect(
      find.text('2026-08-13 | Born alive 9 | Stillborn 2 | Current live 9'),
      findsOneWidget,
    );
  });

  testWidgets(
    'MatingDetailScreen exposes kindling action for pregnant mating',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matingDetailProvider(
              'mating-1',
            ).overrideWith((ref) async => _pregnantMating),
          ],
          child: const MaterialApp(
            home: MatingDetailScreen(matingId: 'mating-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Record kindling'), findsOneWidget);
      expect(find.byTooltip('Record kindling'), findsNothing);
    },
  );
}

const _mating = MatingDetail(
  id: 'mating-1',
  doeId: 'doe-1',
  doeIdentifier: 'DOE-0001',
  buckIdentifier: 'BUCK-0001',
  pregnancyCheckDueOn: '2026-08-10',
  expectedKindlingOn: '2026-08-27',
  status: 'awaiting_pregnancy_check',
  outcome: 'observed',
  pregnancyChecks: [
    PregnancyCheckSummary(
      id: 'check-1',
      result: 'not_pregnant',
      checkedOn: '2026-08-11',
    ),
  ],
  litters: [
    MatingLitterSummary(
      id: 'litter-1',
      identifier: 'LIT-260813-XYOS',
      kindledOn: '2026-08-13',
      kitsBornAlive: 9,
      kitsStillborn: 2,
      kitsWeak: 0,
      currentLiveCount: 9,
      status: 'nursing',
    ),
  ],
);

const _pregnantMating = MatingDetail(
  id: 'mating-1',
  doeId: 'doe-1',
  doeIdentifier: 'DOE-0001',
  buckIdentifier: 'BUCK-0001',
  pregnancyCheckDueOn: '2026-08-10',
  expectedKindlingOn: '2026-08-27',
  status: 'pregnant',
  outcome: 'observed',
  pregnancyChecks: [
    PregnancyCheckSummary(
      id: 'check-1',
      result: 'pregnant',
      checkedOn: '2026-08-11',
    ),
  ],
  litters: [],
);
