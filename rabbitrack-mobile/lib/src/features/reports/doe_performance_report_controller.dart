import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        return const DoePerformanceReport(
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
      }

      return ref
          .watch(doePerformanceReportRepositoryProvider)
          .show(farm.id, start: period.start, end: period.end);
    });
