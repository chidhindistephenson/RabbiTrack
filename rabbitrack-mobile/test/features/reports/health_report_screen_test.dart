import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/reports/health_report_controller.dart';
import 'package:rabbitrack_mobile/src/features/reports/health_report_models.dart';
import 'package:rabbitrack_mobile/src/features/reports/health_report_screen.dart';

void main() {
  testWidgets('HealthReportScreen renders health report sections', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [healthReportProvider.overrideWith((ref) async => _report)],
        child: const MaterialApp(home: HealthReportScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Health report'), findsOneWidget);
    expect(find.text('Active events'), findsOneWidget);
    expect(find.text('Treatments'), findsOneWidget);
    expect(find.text('Withdrawals'), findsOneWidget);
    expect(find.text('Mortality'), findsOneWidget);
    expect(find.text('Severity'), findsOneWidget);
    expect(find.text('Severe'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Medicine use'),
      260,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Medicine use'), findsOneWidget);
    expect(find.text('Oxytet'), findsOneWidget);
    expect(find.text('Withdrawal restrictions'), findsOneWidget);
    expect(find.text('DOE-HEALTH'), findsOneWidget);
  });

  testWidgets('HealthReportScreen renders empty grouped states', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          healthReportProvider.overrideWith(
            (ref) async => const HealthReport(
              activeHealthEvents: 0,
              activeTreatments: 0,
              withdrawalRestrictions: 0,
              mortalityCount: 0,
              eventsBySeverity: [],
              eventsByBodySystem: [],
              eventsByDiagnosis: [],
              medicineUse: [],
              withdrawals: [],
            ),
          ),
        ],
        child: const MaterialApp(home: HealthReportScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No active health events'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('No active withdrawal restrictions'),
      260,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('No active withdrawal restrictions'), findsOneWidget);
  });
}

const _report = HealthReport(
  activeHealthEvents: 1,
  activeTreatments: 1,
  withdrawalRestrictions: 1,
  mortalityCount: 2,
  eventsBySeverity: [HealthReportRow(label: 'severe', count: 1)],
  eventsByBodySystem: [HealthReportRow(label: 'respiratory', count: 1)],
  eventsByDiagnosis: [HealthReportRow(label: 'Snuffles', count: 1)],
  medicineUse: [HealthReportRow(label: 'Oxytet', count: 1)],
  withdrawals: [
    WithdrawalSummary(
      id: 'treatment-1',
      rabbitId: 'rabbit-1',
      rabbitIdentifier: 'DOE-HEALTH',
      medication: 'Oxytet',
      withdrawalEndsOn: '2026-08-22',
    ),
  ],
);
