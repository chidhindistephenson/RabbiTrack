import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/offline_demo_data.dart';
import '../auth/auth_controller.dart';
import 'buck_performance_report_models.dart';
import 'buck_performance_report_repository.dart';
import 'performance_report_period.dart';

final buckPerformanceReportProvider =
    FutureProvider.autoDispose<BuckPerformanceReport>((ref) async {
      return ref.watch(
        buckPerformanceReportForPeriodProvider(
          const PerformanceReportPeriod(),
        ).future,
      );
    });

final buckPerformanceReportForPeriodProvider = FutureProvider.autoDispose
    .family<BuckPerformanceReport, PerformanceReportPeriod>((
      ref,
      period,
    ) async {
      final session = ref.watch(authControllerProvider).valueOrNull;
      final farm = session?.selectedFarm;

      if (farm == null) {
        return _emptyBuckPerformanceReport;
      }

      if (isOfflineDemoSession(session)) {
        if (isOfflineEmptyFarm(farm.id)) {
          return _emptyBuckPerformanceReport;
        }

        final bucks = offlineDemoRabbits(sex: 'male').map((rabbit) {
          final isDemoSire = rabbit.id == 'offline-buck-0003';
          return BuckPerformanceRow(
            id: rabbit.id,
            identifier: rabbit.identifier,
            name: rabbit.name,
            breed: rabbit.breed,
            status: rabbit.status,
            matings: isDemoSire ? 1 : 0,
            confirmedPregnancies: isDemoSire ? 1 : 0,
            conceptionRate: isDemoSire ? 100 : 0,
            litters: isDemoSire ? 1 : 0,
            kitsBornAlive: isDemoSire ? 9 : 0,
            kitsWeaned: 0,
            averageLitterSize: isDemoSire ? 9 : 0,
            weaningRate: 0,
          );
        }).toList();

        final totalMatings = bucks.fold<int>(
          0,
          (sum, row) => sum + row.matings,
        );
        final confirmedPregnancies = bucks.fold<int>(
          0,
          (sum, row) => sum + row.confirmedPregnancies,
        );
        final litters = bucks.fold<int>(0, (sum, row) => sum + row.litters);
        final kitsBornAlive = bucks.fold<int>(
          0,
          (sum, row) => sum + row.kitsBornAlive,
        );
        final kitsWeaned = bucks.fold<int>(
          0,
          (sum, row) => sum + row.kitsWeaned,
        );

        return BuckPerformanceReport(
          buckCount: bucks.length,
          totalMatings: totalMatings,
          confirmedPregnancies: confirmedPregnancies,
          conceptionRate: totalMatings == 0
              ? 0
              : (confirmedPregnancies / totalMatings) * 100,
          litters: litters,
          kitsBornAlive: kitsBornAlive,
          kitsWeaned: kitsWeaned,
          averageLitterSize: litters == 0 ? 0 : kitsBornAlive / litters,
          weaningRate: kitsBornAlive == 0
              ? 0
              : (kitsWeaned / kitsBornAlive) * 100,
          bucks: bucks,
        );
      }

      return ref
          .watch(buckPerformanceReportRepositoryProvider)
          .show(farm.id, start: period.start, end: period.end);
    });

const _emptyBuckPerformanceReport = BuckPerformanceReport(
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
);
