import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import 'litter_performance_report_models.dart';
import 'litter_performance_report_repository.dart';

final litterPerformanceReportProvider =
    FutureProvider.autoDispose<LitterPerformanceReport>((ref) async {
      final session = ref.watch(authControllerProvider).valueOrNull;
      final farm = session?.selectedFarm;

      if (farm == null) {
        return const LitterPerformanceReport(
          litterCount: 0,
          bornAlive: 0,
          stillborn: 0,
          mortality: 0,
          currentLive: 0,
          weaned: 0,
          survivalRate: 0,
          litters: [],
        );
      }

      return ref.watch(litterPerformanceReportRepositoryProvider).show(farm.id);
    });
