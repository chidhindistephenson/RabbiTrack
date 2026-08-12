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
    expect(find.text('Awaiting pregnancy check'), findsOneWidget);
    expect(find.text('Observed'), findsOneWidget);
    expect(find.text('Not pregnant'), findsOneWidget);
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

      expect(find.text('Actions'), findsOneWidget);
      expect(find.text('Record kindling'), findsOneWidget);
      expect(find.byTooltip('Record kindling'), findsOneWidget);
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
  litters: [],
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
