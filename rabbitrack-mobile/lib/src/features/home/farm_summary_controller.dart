import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/offline_action_queue.dart';
import '../../shared/offline_demo_data.dart';
import '../auth/auth_controller.dart';
import 'farm_summary_models.dart';
import 'farm_summary_repository.dart';

final farmSummaryProvider = FutureProvider.autoDispose<FarmSummaryCounts>((
  ref,
) async {
  final session = ref.watch(authControllerProvider).valueOrNull;
  final farm = session?.selectedFarm;

  if (isOfflineDemoSession(session) && farm != null) {
    return _offlineSummaryWithQueuedChanges(
      ref.watch(offlineActionQueueProvider),
      farm.id,
    );
  }

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

Future<FarmSummaryCounts> _offlineSummaryWithQueuedChanges(
  OfflineActionQueue queue,
  String farmId,
) async {
  final base = isOfflineDemoFarm(farmId)
      ? offlineDemoFarmSummary
      : offlineEmptyFarmSummary;
  final actions = await queue.pendingActions();
  final farmActions = actions
      .where((action) => action.path.startsWith('/farms/$farmId/'))
      .toList();

  var activeRabbits = base.activeRabbits;
  var does = base.does;
  var bucks = base.bucks;
  var liveKits = base.liveKits;
  var readyForSale = base.readyForSale;
  var healthAlerts = base.healthAlerts;
  var pregnantDoes = base.pregnantDoes;
  var nursingDoes = base.nursingDoes;
  var openTasks = base.openTasks;
  var overdueTasks = base.overdueTasks;
  var expectedKindlings = base.expectedKindlings;
  var totalSales = base.totalSales;
  var salesRevenue = double.tryParse(base.salesRevenue) ?? 0;
  var totalExpenses = double.tryParse(base.totalExpenses) ?? 0;

  final today = DateTime.now().toIso8601String().split('T').first;

  for (final action in farmActions) {
    if (action.method != 'POST') {
      continue;
    }

    if (action.path.endsWith('/rabbits')) {
      final status = action.data['status'] as String? ?? 'growing';
      if (!_terminalStatuses.contains(status)) {
        activeRabbits += 1;
      }
      if (action.data['sex'] == 'female') {
        does += 1;
      } else if (action.data['sex'] == 'male') {
        bucks += 1;
      }
      if (status == 'ready_for_sale') {
        readyForSale += 1;
      } else if (status == 'pregnant') {
        pregnantDoes += 1;
      } else if (status == 'nursing') {
        nursingDoes += 1;
      }
    } else if (action.path.endsWith('/kindlings')) {
      liveKits += action.data['kits_born_alive'] as int? ?? 0;
      nursingDoes += 1;
    } else if (action.path.endsWith('/health-events')) {
      healthAlerts += 1;
    } else if (action.path.endsWith('/tasks')) {
      openTasks += 1;
      final dueOn = action.data['due_on'] as String?;
      if (dueOn != null && dueOn.compareTo(today) < 0) {
        overdueTasks += 1;
      }
    } else if (action.path.endsWith('/sales')) {
      totalSales += 1;
      salesRevenue += _money(action.data['amount']);
    } else if (action.path.endsWith('/expenses')) {
      totalExpenses += _money(action.data['amount']);
    } else if (action.path.endsWith('/matings')) {
      expectedKindlings += 1;
    }
  }

  final netIncome = salesRevenue - totalExpenses;

  return FarmSummaryCounts(
    activeRabbits: activeRabbits,
    does: does,
    bucks: bucks,
    liveKits: liveKits,
    readyForSale: readyForSale,
    healthAlerts: healthAlerts,
    quarantined: base.quarantined,
    pregnantDoes: pregnantDoes,
    nursingDoes: nursingDoes,
    openTasks: openTasks,
    overdueTasks: overdueTasks,
    expectedKindlings: expectedKindlings,
    totalSales: totalSales,
    salesRevenue: salesRevenue.toStringAsFixed(2),
    totalExpenses: totalExpenses.toStringAsFixed(2),
    netIncome: netIncome.toStringAsFixed(2),
    currency: base.currency,
  );
}

double _money(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

const _terminalStatuses = {'sold', 'retired', 'deceased', 'culled'};
