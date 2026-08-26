import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/offline_demo_data.dart';
import '../auth/auth_controller.dart';
import 'population_report_models.dart';
import 'population_report_repository.dart';

final populationReportProvider = FutureProvider.autoDispose<PopulationReport>((
  ref,
) async {
  final session = ref.watch(authControllerProvider).valueOrNull;
  final farm = session?.selectedFarm;

  if (farm == null) {
    return const PopulationReport(
      total: 0,
      bySex: [],
      byStatus: [],
      byBreed: [],
      byLocation: [],
    );
  }

  if (isOfflineDemoSession(session) && isOfflineDemoFarm(farm.id)) {
    return offlineDemoPopulationReport;
  }

  if (isOfflineDemoSession(session) && isOfflineEmptyFarm(farm.id)) {
    return const PopulationReport(
      total: 0,
      bySex: [],
      byStatus: [],
      byBreed: [],
      byLocation: [],
    );
  }

  return ref.watch(populationReportRepositoryProvider).show(farm.id);
});
