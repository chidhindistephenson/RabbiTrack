import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        return const BuckPerformanceReport(
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
      }

      return ref
          .watch(buckPerformanceReportRepositoryProvider)
          .show(farm.id, start: period.start, end: period.end);
    });
