import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/offline_demo_data.dart';
import '../auth/auth_controller.dart';
import 'doe_performance_report_models.dart';
import 'doe_performance_report_repository.dart';
import 'performance_report_period.dart';

final doePerformanceReportProvider =
    FutureProvider.autoDispose<DoePerformanceReport>((ref) async {
      return ref.watch(
        doePerformanceReportForPeriodProvider(
          const PerformanceReportPeriod(),
        ).future,
      );
    });

final doePerformanceReportForPeriodProvider = FutureProvider.autoDispose
    .family<DoePerformanceReport, PerformanceReportPeriod>((ref, period) async {
      final session = ref.watch(authControllerProvider).valueOrNull;
      final farm = session?.selectedFarm;

      if (farm == null) {
        return _emptyDoePerformanceReport;
      }

      if (isOfflineDemoSession(session)) {
        if (isOfflineEmptyFarm(farm.id)) {
          return _emptyDoePerformanceReport;
        }

        final does = offlineDemoRabbits(sex: 'female')
            .map(
              (rabbit) => DoePerformanceRow(
                id: rabbit.id,
                identifier: rabbit.identifier,
                name: rabbit.name,
                breed: rabbit.breed,
                status: rabbit.status,
                matings: rabbit.id == 'offline-doe-0047' ? 1 : 0,
                confirmedPregnancies:
                    rabbit.status == 'pregnant' || rabbit.status == 'nursing'
                    ? 1
                    : 0,
                kindlings: rabbit.status == 'nursing' ? 1 : 0,
                completedLitters: 0,
                kitsBornAlive: rabbit.status == 'nursing' ? 9 : 0,
                kitsWeaned: 0,
                averageLitterSize: rabbit.status == 'nursing' ? 9 : 0,
                survivalRate: rabbit.status == 'nursing' ? 100 : 0,
              ),
            )
            .toList();

        final totalMatings = does.fold<int>(0, (sum, row) => sum + row.matings);
        final confirmedPregnancies = does.fold<int>(
          0,
          (sum, row) => sum + row.confirmedPregnancies,
        );
        final kindlings = does.fold<int>(0, (sum, row) => sum + row.kindlings);
        final kitsBornAlive = does.fold<int>(
          0,
          (sum, row) => sum + row.kitsBornAlive,
        );
        final kitsWeaned = does.fold<int>(
          0,
          (sum, row) => sum + row.kitsWeaned,
        );

        return DoePerformanceReport(
          doeCount: does.length,
          totalMatings: totalMatings,
          confirmedPregnancies: confirmedPregnancies,
          kindlings: kindlings,
          completedLitters: 0,
          kitsBornAlive: kitsBornAlive,
          kitsWeaned: kitsWeaned,
          averageLitterSize: kindlings == 0 ? 0 : kitsBornAlive / kindlings,
          survivalRate: kitsBornAlive == 0
              ? 0
              : (kitsWeaned / kitsBornAlive) * 100,
          does: does,
        );
      }

      return ref
          .watch(doePerformanceReportRepositoryProvider)
          .show(farm.id, start: period.start, end: period.end);
    });

const _emptyDoePerformanceReport = DoePerformanceReport(
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
);
