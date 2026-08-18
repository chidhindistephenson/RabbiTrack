import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/tasks/task_models.dart';
import 'package:rabbitrack_mobile/src/features/tasks/task_reminder_service.dart';

void main() {
  test('taskReminderPlans schedules future open tasks by due time', () {
    final plans = taskReminderPlans(
      [
        const TaskSummary(
          id: 'task-1',
          type: 'manual',
          title: 'Feed growers',
          dueOn: '2026-08-18',
          dueTime: '14:30',
          priority: 'normal',
          status: 'open',
          rabbitIdentifier: 'DOE-0001',
        ),
      ],
      now: DateTime(2026, 8, 18, 12),
    );

    expect(plans, hasLength(1));
    expect(plans.single.title, 'Feed growers');
    expect(plans.single.body, 'DOE-0001');
    expect(plans.single.scheduledAt, DateTime(2026, 8, 18, 14, 30));
  });

  test('taskReminderPlans skips closed and past tasks', () {
    final plans = taskReminderPlans(
      [
        const TaskSummary(
          id: 'task-1',
          type: 'manual',
          title: 'Past task',
          dueOn: '2026-08-17',
          priority: 'normal',
          status: 'open',
        ),
        const TaskSummary(
          id: 'task-2',
          type: 'manual',
          title: 'Closed task',
          dueOn: '2026-08-19',
          priority: 'normal',
          status: 'completed',
        ),
      ],
      now: DateTime(2026, 8, 18, 12),
    );

    expect(plans, isEmpty);
  });

  test('taskReminderDateTime defaults missing due time to 08:00', () {
    const task = TaskSummary(
      id: 'task-1',
      type: 'manual',
      title: 'Morning task',
      dueOn: '2026-08-19',
      priority: 'normal',
      status: 'open',
    );

    expect(taskReminderDateTime(task), DateTime(2026, 8, 19, 8));
  });
}
