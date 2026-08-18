import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/reports/buck_performance_report_controller.dart';
import 'package:rabbitrack_mobile/src/features/reports/buck_performance_report_models.dart';
import 'package:rabbitrack_mobile/src/features/reports/buck_performance_report_screen.dart';

void main() {
  testWidgets('BuckPerformanceReportScreen renders summary and buck rows', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          buckPerformanceReportForPeriodProvider.overrideWith(
            (ref, period) async => _report,
          ),
        ],
        child: const MaterialApp(home: BuckPerformanceReportScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Buck performance'), findsOneWidget);
    expect(find.text('All time'), findsOneWidget);
    expect(find.text('Last 30d'), findsOneWidget);
    expect(find.text('Last 90d'), findsOneWidget);
    expect(find.text('50.0%'), findsOneWidget);
    expect(find.text('confirmed pregnancies from matings'), findsOneWidget);
    expect(find.text('BUCK-PERF - Atlas'), findsOneWidget);
    expect(
      find.textContaining('2 matings, 1 pregnant, 1 litters'),
      findsOneWidget,
    );
    expect(find.textContaining('9 born, 8 weaned'), findsOneWidget);

    await tester.tap(find.text('Last 90d'));
    await tester.pumpAndSettle();

    expect(find.text('BUCK-PERF - Atlas'), findsOneWidget);
  });

  testWidgets('BuckPerformanceReportScreen renders empty state', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          buckPerformanceReportForPeriodProvider.overrideWith(
            (ref, period) async => const BuckPerformanceReport(
              buckCount: 0,
              totalMatings: 0,
              confirmedPregnancies: 0,
              conceptionRate: 0,
              litters: 0,
              kitsBornAlive: 0,
              kitsWeaned: 0,
              averageLitterSize: 0,
              weaningRate: 0,
              bucks: [],
            ),
          ),
        ],
        child: const MaterialApp(home: BuckPerformanceReportScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No bucks recorded yet'), findsOneWidget);
  });
}

const _report = BuckPerformanceReport(
  buckCount: 1,
  totalMatings: 2,
  confirmedPregnancies: 1,
  conceptionRate: 50,
  litters: 1,
  kitsBornAlive: 9,
  kitsWeaned: 8,
  averageLitterSize: 9,
  weaningRate: 88.9,
  bucks: [
    BuckPerformanceRow(
      id: 'buck-1',
      identifier: 'BUCK-PERF',
      name: 'Atlas',
      breed: 'New Zealand White',
      status: 'available_for_breeding',
      matings: 2,
      confirmedPregnancies: 1,
      conceptionRate: 50,
      litters: 1,
      kitsBornAlive: 9,
      kitsWeaned: 8,
      averageLitterSize: 9,
      weaningRate: 88.9,
    ),
  ],
);
