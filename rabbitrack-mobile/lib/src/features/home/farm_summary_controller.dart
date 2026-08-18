import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import 'farm_summary_models.dart';
import 'farm_summary_repository.dart';

final farmSummaryProvider = FutureProvider.autoDispose<FarmSummaryCounts>((
  ref,
) async {
  final session = ref.watch(authControllerProvider).valueOrNull;
  final farm = session?.selectedFarm;

  if (farm == null) {
    return const FarmSummaryCounts(
      activeRabbits: 0,
      does: 0,
      bucks: 0,
      liveKits: 0,
      readyForSale: 0,
      healthAlerts: 0,
      quarantined: 0,
      pregnantDoes: 0,
      nursingDoes: 0,
      openTasks: 0,
      overdueTasks: 0,
      expectedKindlings: 0,
      totalSales: 0,
      salesRevenue: '0.00',
      totalExpenses: '0.00',
      netIncome: '0.00',
      currency: 'USD',
    );
  }

  return ref.watch(farmSummaryRepositoryProvider).summary(farm.id);
});
