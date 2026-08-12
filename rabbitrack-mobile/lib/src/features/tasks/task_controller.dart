import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import 'task_models.dart';
import 'task_repository.dart';

final taskListProvider = FutureProvider.autoDispose<List<TaskSummary>>((
  ref,
) async {
  final session = ref.watch(authControllerProvider).valueOrNull;
  final farm = session?.selectedFarm;

  if (farm == null) {
    return [];
  }

  return ref.watch(taskRepositoryProvider).list(farm.id);
});

final taskSummaryProvider = FutureProvider.autoDispose<TaskSummaryCounts>((
  ref,
) async {
  final session = ref.watch(authControllerProvider).valueOrNull;
  final farm = session?.selectedFarm;

  if (farm == null) {
    return const TaskSummaryCounts(today: 0, overdue: 0, open: 0);
  }

  return ref.watch(taskRepositoryProvider).summary(farm.id);
});
