import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import 'task_models.dart';
import 'task_repository.dart';
import 'task_reminder_service.dart';

enum TaskDueFilter { all, today, overdue, upcoming }

final taskDueFilterProvider = StateProvider.autoDispose<TaskDueFilter>(
  (ref) => TaskDueFilter.all,
);

final taskListProvider = FutureProvider.autoDispose<List<TaskSummary>>((
  ref,
) async {
  final session = ref.watch(authControllerProvider).valueOrNull;
  final farm = session?.selectedFarm;
  final dueFilter = ref.watch(taskDueFilterProvider);

  if (farm == null) {
    return [];
  }

  final tasks = await ref
      .watch(taskRepositoryProvider)
      .list(farm.id, due: dueFilter.apiValue);

  if (dueFilter == TaskDueFilter.all) {
    await ref.watch(taskReminderServiceProvider).syncOpenTasks(tasks);
  }

  return tasks;
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

Future<void> syncTaskRemindersForFarm(WidgetRef ref, String farmId) async {
  final tasks = await ref.read(taskRepositoryProvider).list(farmId);
  await ref.read(taskReminderServiceProvider).syncOpenTasks(tasks);
}

extension TaskDueFilterApi on TaskDueFilter {
  String? get apiValue {
    return switch (this) {
      TaskDueFilter.all => null,
      TaskDueFilter.today => 'today',
      TaskDueFilter.overdue => 'overdue',
      TaskDueFilter.upcoming => 'upcoming',
    };
  }
}
