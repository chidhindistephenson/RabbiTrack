import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/reports/breeding_calendar_controller.dart';
import 'package:rabbitrack_mobile/src/features/reports/breeding_calendar_models.dart';
import 'package:rabbitrack_mobile/src/features/reports/breeding_calendar_screen.dart';

void main() {
  testWidgets('BreedingCalendarScreen renders grouped breeding events', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          breedingCalendarProvider.overrideWith((ref) async => _events),
        ],
        child: const MaterialApp(home: BreedingCalendarScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Breeding calendar'), findsOneWidget);
    expect(find.text('1 Aug 2026'), findsOneWidget);
    expect(find.text('Mating: DOE-CAL x BUCK-CAL'), findsOneWidget);
    expect(find.text('15 Aug 2026'), findsOneWidget);
    expect(find.text('Pregnancy check: DOE-CAL'), findsOneWidget);
    expect(find.text('Planned weaning: LIT-CAL'), findsOneWidget);
  });

  testWidgets('BreedingCalendarScreen renders empty state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          breedingCalendarProvider.overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(home: BreedingCalendarScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No breeding dates yet'), findsOneWidget);
  });
}

const _events = [
  BreedingCalendarEvent(
    date: '2026-08-01',
    type: 'mating',
    title: 'Mating: DOE-CAL x BUCK-CAL',
    subtitle: 'observed',
    relatedType: 'mating',
    relatedId: 'mating-1',
    rabbitId: 'doe-1',
    rabbitIdentifier: 'DOE-CAL',
  ),
  BreedingCalendarEvent(
    date: '2026-08-15',
    type: 'pregnancy_check',
    title: 'Pregnancy check: DOE-CAL',
    subtitle: 'Mated with BUCK-CAL',
    relatedType: 'mating',
    relatedId: 'mating-1',
    rabbitId: 'doe-1',
    rabbitIdentifier: 'DOE-CAL',
  ),
  BreedingCalendarEvent(
    date: '2026-09-14',
    type: 'weaning',
    title: 'Planned weaning: LIT-CAL',
    subtitle: '7 live kits',
    relatedType: 'litter',
    relatedId: 'litter-1',
    rabbitId: 'doe-1',
    rabbitIdentifier: 'DOE-CAL',
  ),
];
