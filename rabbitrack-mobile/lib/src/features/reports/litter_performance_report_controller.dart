import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/offline_demo_data.dart';
import '../auth/auth_controller.dart';
import 'litter_performance_report_models.dart';
import 'litter_performance_report_repository.dart';

final litterPerformanceReportProvider =
    FutureProvider.autoDispose<LitterPerformanceReport>((ref) async {
      final session = ref.watch(authControllerProvider).valueOrNull;
      final farm = session?.selectedFarm;

      if (farm == null) {
        return _emptyLitterPerformanceReport;
      }

      if (isOfflineDemoSession(session)) {
        if (isOfflineEmptyFarm(farm.id)) {
          return _emptyLitterPerformanceReport;
        }

        final rows = offlineDemoLitters().map((litter) {
          final detail = offlineDemoLitterDetail(litter.id);
          final bornAlive = detail?.kitsBornAlive ?? litter.currentLiveCount;
          final stillborn = detail?.kitsStillborn ?? 0;
          final mortality = (bornAlive - litter.currentLiveCount).clamp(
            0,
            bornAlive,
          );

          return LitterPerformanceRow(
            id: litter.id,
            identifier: litter.identifier,
            doeIdentifier: litter.doeIdentifier,
            buckIdentifier: litter.buckIdentifier,
            kindledOn: litter.kindledOn,
            bornAlive: bornAlive,
            stillborn: stillborn,
            mortality: mortality,
            currentLive: litter.currentLiveCount,
            weaned: litter.status == 'weaned' ? litter.currentLiveCount : 0,
            survivalRate: bornAlive == 0
                ? 0
                : (litter.currentLiveCount / bornAlive) * 100,
            birthAverageWeight: detail?.weights.isEmpty == false
                ? detail!.weights.first.averageWeightValue
                : null,
            weightUnit: 'kg',
            status: litter.status,
          );
        }).toList();

        final bornAlive = rows.fold<int>(0, (sum, row) => sum + row.bornAlive);
        final currentLive = rows.fold<int>(
          0,
          (sum, row) => sum + row.currentLive,
        );
        final stillborn = rows.fold<int>(0, (sum, row) => sum + row.stillborn);
        final mortality = rows.fold<int>(0, (sum, row) => sum + row.mortality);
        final weaned = rows.fold<int>(0, (sum, row) => sum + row.weaned);

        return LitterPerformanceReport(
          litterCount: rows.length,
          bornAlive: bornAlive,
          stillborn: stillborn,
          mortality: mortality,
          currentLive: currentLive,
          weaned: weaned,
          survivalRate: bornAlive == 0 ? 0 : (currentLive / bornAlive) * 100,
          litters: rows,
        );
      }

      return ref.watch(litterPerformanceReportRepositoryProvider).show(farm.id);
    });

const _emptyLitterPerformanceReport = LitterPerformanceReport(
  litterCount: 0,
  bornAlive: 0,
  stillborn: 0,
  mortality: 0,
  currentLive: 0,
  weaned: 0,
  survivalRate: 0,
  litters: [],
);
