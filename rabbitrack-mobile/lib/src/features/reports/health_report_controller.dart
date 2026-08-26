import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/offline_demo_data.dart';
import '../auth/auth_controller.dart';
import 'health_report_models.dart';
import 'health_report_repository.dart';

final healthReportProvider = FutureProvider.autoDispose<HealthReport>((
  ref,
) async {
  final session = ref.watch(authControllerProvider).valueOrNull;
  final farm = session?.selectedFarm;

  if (farm == null) {
    return const HealthReport(
      activeHealthEvents: 0,
      activeTreatments: 0,
      withdrawalRestrictions: 0,
      mortalityCount: 0,
      eventsBySeverity: [],
      eventsByBodySystem: [],
      eventsByDiagnosis: [],
      medicineUse: [],
      withdrawals: [],
    );
  }

  if (isOfflineDemoSession(session) && isOfflineDemoFarm(farm.id)) {
    return offlineDemoHealthReport;
  }

  if (isOfflineDemoSession(session) && isOfflineEmptyFarm(farm.id)) {
    return const HealthReport(
      activeHealthEvents: 0,
      activeTreatments: 0,
      withdrawalRestrictions: 0,
      mortalityCount: 0,
      eventsBySeverity: [],
      eventsByBodySystem: [],
      eventsByDiagnosis: [],
      medicineUse: [],
      withdrawals: [],
    );
  }

  return ref.watch(healthReportRepositoryProvider).show(farm.id);
});
