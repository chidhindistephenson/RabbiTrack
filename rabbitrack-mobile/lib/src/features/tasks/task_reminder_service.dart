import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'task_models.dart';

final taskReminderServiceProvider = Provider<TaskReminderService>(
  (ref) => TaskReminderService.instance,
);

class TaskReminderService {
  TaskReminderService._({
    FlutterLocalNotificationsPlugin? plugin,
    DateTime Function()? now,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       _now = now ?? DateTime.now;

  static final TaskReminderService instance = TaskReminderService._();

  final FlutterLocalNotificationsPlugin _plugin;
  final DateTime Function() _now;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Africa/Johannesburg'));

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  Future<void> syncOpenTasks(List<TaskSummary> tasks) async {
    await initialize();
    await _plugin.cancelAll();

    final plans = taskReminderPlans(tasks, now: _now()).take(64);
    for (final plan in plans) {
      await _plugin.zonedSchedule(
        id: plan.notificationId,
        title: plan.title,
        body: plan.body,
        payload: plan.payload,
        scheduledDate: tz.TZDateTime.from(plan.scheduledAt, tz.local),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'task_reminders',
            'Task reminders',
            channelDescription: 'Due and upcoming RabbiTrack farm tasks',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    }
  }
}

class TaskReminderPlan {
  const TaskReminderPlan({
    required this.notificationId,
    required this.title,
    required this.body,
    required this.payload,
    required this.scheduledAt,
  });

  final int notificationId;
  final String title;
  final String body;
  final String payload;
  final DateTime scheduledAt;
}

List<TaskReminderPlan> taskReminderPlans(
  List<TaskSummary> tasks, {
  required DateTime now,
}) {
  final plans = <TaskReminderPlan>[];

  for (final task in tasks) {
    if (task.status != 'open') {
      continue;
    }

    final scheduledAt = taskReminderDateTime(task);
    if (scheduledAt == null || !scheduledAt.isAfter(now)) {
      continue;
    }

    plans.add(
      TaskReminderPlan(
        notificationId: taskReminderNotificationId(task.id),
        title: task.title,
        body: _taskReminderBody(task),
        payload: 'task:${task.id}',
        scheduledAt: scheduledAt,
      ),
    );
  }

  plans.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

  return plans;
}

DateTime? taskReminderDateTime(TaskSummary task) {
  final date = DateTime.tryParse(task.dueOn);
  if (date == null) {
    return null;
  }

  final time = _taskReminderTime(task.dueTime);

  return DateTime(date.year, date.month, date.day, time.$1, time.$2);
}

int taskReminderNotificationId(String taskId) {
  var hash = 0;
  for (final codeUnit in taskId.codeUnits) {
    hash = (hash * 31 + codeUnit) & 0x7fffffff;
  }

  return hash == 0 ? 1 : hash;
}

(int, int) _taskReminderTime(String? value) {
  if (value == null || value.trim().isEmpty) {
    return (8, 0);
  }

  final parts = value.split(':');
  if (parts.length < 2) {
    return (8, 0);
  }

  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null ||
      minute == null ||
      hour < 0 ||
      hour > 23 ||
      minute < 0 ||
      minute > 59) {
    return (8, 0);
  }

  return (hour, minute);
}

String _taskReminderBody(TaskSummary task) {
  final parts = [
    task.rabbitIdentifier,
    task.locationName,
    task.description,
  ].whereType<String>().where((value) => value.trim().isNotEmpty).toList();

  if (parts.isEmpty) {
    return 'Farm task due now';
  }

  return parts.join(' | ');
}
