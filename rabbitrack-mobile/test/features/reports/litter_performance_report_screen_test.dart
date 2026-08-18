import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/reports/litter_performance_report_controller.dart';
import 'package:rabbitrack_mobile/src/features/reports/litter_performance_report_models.dart';
import 'package:rabbitrack_mobile/src/features/reports/litter_performance_report_screen.dart';

void main() {
  testWidgets('LitterPerformanceReportScreen renders summary and litter rows', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          litterPerformanceReportProvider.overrideWith((ref) async => _report),
        ],
        child: const MaterialApp(home: LitterPerformanceReportScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Litter performance'), findsOneWidget);
    expect(find.text('75.0%'), findsOneWidget);
    expect(find.text('overall live-kit survival'), findsOneWidget);
    expect(find.text('LIT-PERF'), findsOneWidget);
    expect(
      find.textContaining('8 alive, 2 stillborn, 6 weaned'),
      findsOneWidget,
    );
    expect(find.textContaining('weaning avg 0.850 kg'), findsOneWidget);
  });

  testWidgets('LitterPerformanceReportScreen renders empty state', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          litterPerformanceReportProvider.overrideWith(
            (ref) async => const LitterPerformanceReport(
              litterCount: 0,
              bornAlive: 0,
              stillborn: 0,
              mortality: 0,
              currentLive: 0,
              weaned: 0,
              survivalRate: 0,
              litters: [],
            ),
          ),
        ],
        child: const MaterialApp(home: LitterPerformanceReportScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No litter history yet'), findsOneWidget);
  });
}

const _report = LitterPerformanceReport(
  litterCount: 1,
  bornAlive: 8,
  stillborn: 2,
  mortality: 2,
  currentLive: 6,
  weaned: 6,
  survivalRate: 75,
  litters: [
    LitterPerformanceRow(
      id: 'litter-1',
      identifier: 'LIT-PERF',
      kindledOn: '2026-08-10',
      bornAlive: 8,
      stillborn: 2,
      mortality: 2,
      currentLive: 6,
      weaned: 6,
      survivalRate: 75,
      birthAverageWeight: '0.080',
      weaningAverageWeight: '0.850',
      weightUnit: 'kg',
      status: 'weaned',
    ),
  ],
);
