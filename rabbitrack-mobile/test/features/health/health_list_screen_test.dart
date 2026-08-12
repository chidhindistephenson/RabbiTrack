import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/health/health_controller.dart';
import 'package:rabbitrack_mobile/src/features/health/health_list_screen.dart';
import 'package:rabbitrack_mobile/src/features/health/health_models.dart';

void main() {
  testWidgets('HealthListScreen renders polished health row labels', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          healthEventListProvider.overrideWith((ref) async => _events),
        ],
        child: const MaterialApp(home: HealthListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('DOE-0001 - Nasal discharge'), findsOneWidget);
    expect(
      find.text('Respiratory | Severe | Open | Isolation | 2 treatments'),
      findsOneWidget,
    );
  });
}

const _events = [
  HealthEventSummary(
    id: 'health-1',
    rabbitIdentifier: 'DOE-0001',
    observedOn: '2026-08-03',
    symptoms: 'Nasal discharge',
    severity: 'severe',
    status: 'open',
    isolationRequired: true,
    treatmentsCount: 2,
    bodySystem: 'respiratory',
  ),
];
