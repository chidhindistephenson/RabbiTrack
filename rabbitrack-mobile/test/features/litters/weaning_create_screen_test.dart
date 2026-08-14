import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/litters/litter_controller.dart';
import 'package:rabbitrack_mobile/src/features/litters/litter_models.dart';
import 'package:rabbitrack_mobile/src/features/litters/weaning_create_screen.dart';

void main() {
  testWidgets('WeaningCreateScreen rejects counts above live count', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [litterListProvider.overrideWith((ref) async => _litters)],
        child: const MaterialApp(
          home: WeaningCreateScreen(litterId: 'litter-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Average weaning weight kg'), findsOneWidget);
    expect(
      find.text('This becomes the litter weaning weight record.'),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextFormField).first, '9');
    await tester.tap(find.text('Save weaning'));
    await tester.pumpAndSettle();

    expect(find.text('Cannot exceed current live count'), findsOneWidget);
  });
}

const _litters = [
  LitterSummary(
    id: 'litter-1',
    identifier: 'LIT-260803-TEST',
    doeId: 'doe-1',
    doeIdentifier: 'DOE-0001',
    kindledOn: '2026-08-03',
    currentLiveCount: 8,
    plannedWeaningOn: '2026-09-07',
    status: 'nursing',
  ),
];
