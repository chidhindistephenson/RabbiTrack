import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/app_state.dart';
import '../../shared/soft_list_tile.dart';
import '../../shared/snackbars.dart';
import '../../theme/rabbitrack_colors.dart';
import '../auth/auth_controller.dart';
import '../home/farm_summary_controller.dart';
import 'task_controller.dart';
import 'task_models.dart';
import 'task_options.dart';
import 'task_repository.dart';

class TaskListScreen extends ConsumerWidget {
  const TaskListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(taskListProvider);
    final summary = ref.watch(taskSummaryProvider);
    final selectedFilter = ref.watch(taskDueFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        backgroundColor: RabbiTrackColors.forestGreen,
        foregroundColor: RabbiTrackColors.cream,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/tasks/new'),
        icon: const Icon(Icons.add),
        label: const Text('Task'),
      ),
      body: tasks.when(
        data: (items) {
          return RefreshIndicator(
            onRefresh: () => Future.wait([
              ref.refresh(taskSummaryProvider.future),
              ref.refresh(taskListProvider.future),
            ]),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _TaskFocusCard(summary: summary),
                const SizedBox(height: 12),
                _TaskFilterBar(selectedFilter: selectedFilter),
                const SizedBox(height: 14),
                if (items.isEmpty)
                  AppState(
                    icon: Icons.task_alt,
                    title: selectedFilter == TaskDueFilter.all
                        ? 'No open tasks'
                        : 'No ${taskDueFilterTitle(selectedFilter.apiValue ?? 'all').toLowerCase()} tasks',
                    message:
                        'Create a task for feeding, breeding, health checks, cage work, or anything that needs follow-up.',
                    actionLabel: 'Add task',
                    actionIcon: Icons.add,
                    onAction: () => context.push('/tasks/new'),
                    minHeight: 300,
                  )
                else
                  for (final task in items) ...[
                    _TaskTile(task: task),
                    const SizedBox(height: 10),
                  ],
              ],
            ),
          );
        },
        error: (error, stackTrace) => AppState(
          icon: Icons.cloud_off_outlined,
          title: 'Could not load tasks',
          message: 'Check the API server and try again.',
          actionLabel: 'Retry',
          onAction: () => ref.invalidate(taskListProvider),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _TaskFocusCard extends StatelessWidget {
  const _TaskFocusCard({required this.summary});

  final AsyncValue<TaskSummaryCounts> summary;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: summary.when(
          data: (counts) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Task focus',
                style: TextStyle(
                  color: RabbiTrackColors.forestGreen,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Keep the daily work moving',
                style: TextStyle(color: RabbiTrackColors.sageGreen),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _TaskCountTile(label: 'Today', value: counts.today),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _TaskCountTile(
                      label: 'Overdue',
                      value: counts.overdue,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _TaskCountTile(label: 'Open', value: counts.open),
                  ),
                ],
              ),
            ],
          ),
          error: (error, stackTrace) =>
              const Text('Could not load task focus.'),
          loading: () => const LinearProgressIndicator(),
        ),
      ),
    );
  }
}

class _TaskCountTile extends StatelessWidget {
  const _TaskCountTile({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RabbiTrackColors.cream,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value.toString(),
            style: const TextStyle(
              color: RabbiTrackColors.forestGreen,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: RabbiTrackColors.sageGreen),
          ),
        ],
      ),
    );
  }
}

class _TaskFilterBar extends ConsumerWidget {
  const _TaskFilterBar({required this.selectedFilter});

  final TaskDueFilter selectedFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final filter in TaskDueFilter.values) ...[
            ChoiceChip(
              label: Text(taskDueFilterTitle(filter.apiValue ?? 'all')),
              selected: selectedFilter == filter,
              onSelected: (_) =>
                  ref.read(taskDueFilterProvider.notifier).state = filter,
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _TaskTile extends ConsumerWidget {
  const _TaskTile({required this.task});

  final TaskSummary task;

  Future<void> _complete(WidgetRef ref) async {
    final farm = ref.read(authControllerProvider).valueOrNull?.selectedFarm;
    if (farm == null) {
      return;
    }

    await ref
        .read(taskRepositoryProvider)
        .complete(farmId: farm.id, taskId: task.id);

    await _refreshTasks(ref, farm.id);
  }

  Future<void> _cancel(WidgetRef ref) async {
    final farm = ref.read(authControllerProvider).valueOrNull?.selectedFarm;
    if (farm == null) {
      return;
    }

    await ref
        .read(taskRepositoryProvider)
        .cancel(farmId: farm.id, taskId: task.id);

    await _refreshTasks(ref, farm.id);
  }

  Future<void> _reschedule(BuildContext context, WidgetRef ref) async {
    final farm = ref.read(authControllerProvider).valueOrNull?.selectedFarm;
    if (farm == null) {
      return;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(task.dueOn) ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );

    if (picked == null) {
      return;
    }

    await ref
        .read(taskRepositoryProvider)
        .reschedule(
          farmId: farm.id,
          taskId: task.id,
          dueOn: _dateString(picked),
        );

    await _refreshTasks(ref, farm.id);
  }

  Future<void> _refreshTasks(WidgetRef ref, String farmId) async {
    ref.invalidate(taskListProvider);
    ref.invalidate(taskSummaryProvider);
    ref.invalidate(farmSummaryProvider);
    await syncTaskRemindersForFarm(ref, farmId);
  }

  String _dateString(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }

  Future<void> _showActions(BuildContext context, WidgetRef ref) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.check_circle_outline),
                title: const Text('Complete task'),
                onTap: () => Navigator.of(context).pop('complete'),
              ),
              ListTile(
                leading: const Icon(Icons.event_repeat),
                title: const Text('Reschedule'),
                onTap: () => Navigator.of(context).pop('reschedule'),
              ),
              ListTile(
                leading: const Icon(Icons.cancel_outlined),
                title: const Text('Cancel task'),
                onTap: () => Navigator.of(context).pop('cancel'),
              ),
            ],
          ),
        );
      },
    );

    try {
      if (action == 'complete') {
        await _complete(ref);
        if (context.mounted) {
          showSuccessSnackBar(context, 'Task completed.');
        }
      } else if (action == 'reschedule' && context.mounted) {
        await _reschedule(context, ref);
        if (context.mounted) {
          showSuccessSnackBar(context, 'Task rescheduled.');
        }
      } else if (action == 'cancel') {
        await _cancel(ref);
        if (context.mounted) {
          showSuccessSnackBar(context, 'Task cancelled.');
        }
      }
    } catch (_) {
      if (context.mounted) {
        showErrorSnackBar(context, _errorMessageFor(action));
      }
    }
  }

  String _errorMessageFor(String? action) {
    return switch (action) {
      'complete' => 'Could not complete task. Try again.',
      'reschedule' => 'Could not reschedule task. Try again.',
      'cancel' => 'Could not cancel task. Try again.',
      _ => 'Could not update task. Try again.',
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SoftListTile(
      icon: task.priority == 'critical' ? Icons.priority_high : Icons.task_alt,
      title: task.title,
      subtitle: [
        taskDueLabel(task.dueOn, task.dueTime),
        taskPriorityLabel(task.priority),
        taskTypeLabel(task.type),
        task.rabbitIdentifier,
        task.locationName,
      ].whereType<String>().join(' | '),
      trailing: IconButton(
        tooltip: 'Task actions',
        onPressed: () => _showActions(context, ref),
        icon: const Icon(Icons.more_vert),
      ),
    );
  }
}
