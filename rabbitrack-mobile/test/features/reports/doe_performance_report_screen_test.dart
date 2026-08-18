import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/reports/doe_performance_report_controller.dart';
import 'package:rabbitrack_mobile/src/features/reports/doe_performance_report_models.dart';
import 'package:rabbitrack_mobile/src/features/reports/doe_performance_report_screen.dart';

void main() {
  testWidgets('DoePerformanceReportScreen renders summary and doe rows', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          doePerformanceReportForPeriodProvider.overrideWith(
            (ref, period) async => _report,
          ),
        ],
        child: const MaterialApp(home: DoePerformanceReportScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Doe performance'), findsOneWidget);
    expect(find.text('All time'), findsOneWidget);
    expect(find.text('Last 30d'), findsOneWidget);
    expect(find.text('Last 90d'), findsOneWidget);
    expect(find.text('50.0%'), findsOneWidget);
    expect(find.text('kits weaned from live births'), findsOneWidget);
    expect(find.text('DOE-PERF - Athena'), findsOneWidget);
    expect(
      find.textContaining('2 matings, 2 pregnant, 2 kindlings'),
      findsOneWidget,
    );
    expect(find.textContaining('14 born, 7 weaned'), findsOneWidget);

    await tester.tap(find.text('Last 30d'));
    await tester.pumpAndSettle();

    expect(find.text('DOE-PERF - Athena'), findsOneWidget);
  });

  testWidgets('DoePerformanceReportScreen renders empty state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          doePerformanceReportForPeriodProvider.overrideWith(
            (ref, period) async => const DoePerformanceReport(
              doeCount: 0,
              totalMatings: 0,
              confirmedPregnancies: 0,
              kindlings: 0,
              completedLitters: 0,
              kitsBornAlive: 0,
              kitsWeaned: 0,
              averageLitterSize: 0,
              survivalRate: 0,
              does: [],
            ),
          ),
        ],
        child: const MaterialApp(home: DoePerformanceReportScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No does recorded yet'), findsOneWidget);
  });
}

const _report = DoePerformanceReport(
  doeCount: 1,
  totalMatings: 2,
  confirmedPregnancies: 2,
  kindlings: 2,
  completedLitters: 1,
  kitsBornAlive: 14,
  kitsWeaned: 7,
  averageLitterSize: 7,
  survivalRate: 50,
  does: [
    DoePerformanceRow(
      id: 'doe-1',
      identifier: 'DOE-PERF',
      name: 'Athena',
      breed: 'New Zealand White',
      status: 'nursing',
      matings: 2,
      confirmedPregnancies: 2,
      kindlings: 2,
      completedLitters: 1,
      kitsBornAlive: 14,
      kitsWeaned: 7,
      averageLitterSize: 7,
      survivalRate: 50,
      averageLitterIntervalDays: 31,
    ),
  ],
);
