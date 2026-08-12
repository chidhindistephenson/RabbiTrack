import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/activity/activity_controller.dart';
import 'package:rabbitrack_mobile/src/features/activity/activity_list_screen.dart';
import 'package:rabbitrack_mobile/src/features/activity/activity_models.dart';

void main() {
  testWidgets('ActivityListScreen renders clean action labels', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [activityListProvider.overrideWith((ref) async => _logs)],
        child: const MaterialApp(home: ActivityListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Recorded sale for SALE-001.'), findsOneWidget);
    expect(find.text('Sale'), findsOneWidget);
    expect(find.text('Farm Manager | 2026-08-03 10:00:00'), findsOneWidget);
  });
}

const _logs = [
  ActivityLogSummary(
    id: 'log-1',
    action: 'sale.recorded',
    description: 'Recorded sale for SALE-001.',
    actorName: 'Farm Manager',
    createdAt: '2026-08-03 10:00:00',
  ),
];
