import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/reports/population_report_controller.dart';
import 'package:rabbitrack_mobile/src/features/reports/population_report_models.dart';
import 'package:rabbitrack_mobile/src/features/reports/population_report_screen.dart';

void main() {
  testWidgets('PopulationReportScreen renders population groups', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          populationReportProvider.overrideWith((ref) async => _report),
        ],
        child: const MaterialApp(home: PopulationReportScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Population report'), findsOneWidget);
    expect(find.text('3'), findsWidgets);
    expect(find.text('active rabbits in the herd'), findsOneWidget);
    expect(find.text('Sex'), findsOneWidget);
    expect(find.text('Female'), findsOneWidget);
    expect(find.text('Status'), findsOneWidget);
    expect(find.text('Available For Breeding'), findsOneWidget);
    expect(find.text('Breed'), findsOneWidget);
    expect(find.text('Rex'), findsOneWidget);
    expect(find.text('Location'), findsOneWidget);
    expect(find.text('Cage A'), findsOneWidget);
  });

  testWidgets('PopulationReportScreen renders empty state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          populationReportProvider.overrideWith(
            (ref) async => const PopulationReport(
              total: 0,
              bySex: [],
              byStatus: [],
              byBreed: [],
              byLocation: [],
            ),
          ),
        ],
        child: const MaterialApp(home: PopulationReportScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No active rabbits yet'), findsOneWidget);
  });
}

const _report = PopulationReport(
  total: 3,
  bySex: [
    PopulationReportRow(label: 'female', count: 2),
    PopulationReportRow(label: 'male', count: 1),
  ],
  byStatus: [PopulationReportRow(label: 'available_for_breeding', count: 2)],
  byBreed: [PopulationReportRow(label: 'Rex', count: 2)],
  byLocation: [PopulationReportRow(label: 'Cage A', count: 2)],
);
