import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/api_error_messages.dart';
import '../../shared/offline_action_queue.dart';
import '../../shared/offline_demo_data.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_repository.dart';
import 'task_models.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final session = ref.watch(authControllerProvider).valueOrNull;

  return TaskRepository(
    dio: ref.watch(dioProvider),
    token: session?.token,
    offlineQueue: ref.watch(offlineActionQueueProvider),
  );
});

class TaskRepository {
  const TaskRepository({
    required this.dio,
    required this.token,
    this.offlineQueue,
  });

  final Dio dio;
  final String? token;
  final OfflineActionQueue? offlineQueue;

  Future<List<TaskSummary>> list(String farmId, {String? due}) async {
    if (_isOfflineDemo) {
      final patchesByTaskId = await _taskPatchesById(farmId);
      final tasks = [
        if (isOfflineDemoFarm(farmId)) ...offlineDemoTasks(DateTime.now()),
        ...await _pendingOfflineTasks(farmId),
      ];

      return tasks
          .map(
            (task) => _applyOfflineTaskPatches(task, patchesByTaskId[task.id]),
          )
          .where((task) => task.status == 'open')
          .where((task) => _matchesDueFilter(task, due))
          .toList();
    }

    final response = await dio.get<Map<String, dynamic>>(
      '/farms/$farmId/tasks',
      queryParameters: {'status': 'open', 'due': ?due},
      options: _authOptions(),
    );

    final data = response.data!['data'] as List<dynamic>;

    return data
        .map((task) => TaskSummary.fromJson(task as Map<String, dynamic>))
        .toList();
  }

  Future<TaskSummaryCounts> summary(String farmId) async {
    if (_isOfflineDemo) {
      final patchesByTaskId = await _taskPatchesById(farmId);
      final tasks =
          [
                if (isOfflineDemoFarm(farmId))
                  ...offlineDemoTasks(DateTime.now()),
                ...await _pendingOfflineTasks(farmId),
              ]
              .map(
                (task) =>
                    _applyOfflineTaskPatches(task, patchesByTaskId[task.id]),
              )
              .where((task) => task.status == 'open')
              .toList();
      final today = _dateValue(DateTime.now());

      return TaskSummaryCounts(
        today: tasks.where((task) => task.dueOn == today).length,
        overdue: tasks.where((task) => task.dueOn.compareTo(today) < 0).length,
        open: tasks.length,
      );
    }

    final response = await dio.get<Map<String, dynamic>>(
      '/farms/$farmId/tasks/summary',
      options: _authOptions(),
    );

    return TaskSummaryCounts.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }

  Future<TaskSummary> create({
    required String farmId,
    required String title,
    required String dueOn,
    required String priority,
    String? description,
    String? dueTime,
    String? rabbitId,
    String? locationId,
  }) async {
    final data = {
      'title': title,
      'description': description,
      'due_on': dueOn,
      'due_time': dueTime,
      'priority': priority,
      'rabbit_id': rabbitId,
      'location_id': locationId,
    };

    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/farms/$farmId/tasks',
        data: data,
        options: _authOptions(),
      );

      return TaskSummary.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
    } on DioException catch (error) {
      if (!isApiConnectionProblem(error) || offlineQueue == null) {
        rethrow;
      }

      await offlineQueue!.enqueue(
        method: 'POST',
        path: '/farms/$farmId/tasks',
        data: data,
        headers: _authHeaders(),
      );

      return TaskSummary(
        id: 'local-${DateTime.now().microsecondsSinceEpoch}',
        type: 'manual',
        title: title,
        description: description,
        dueOn: dueOn,
        dueTime: dueTime,
        priority: priority,
        status: 'open',
      );
    }
  }

  Future<void> complete({
    required String farmId,
    required String taskId,
  }) async {
    await _patchTaskAction(
      farmId: farmId,
      taskId: taskId,
      data: {'action': 'complete'},
    );
  }

  Future<void> cancel({required String farmId, required String taskId}) async {
    await _patchTaskAction(
      farmId: farmId,
      taskId: taskId,
      data: {'action': 'cancel'},
    );
  }

  Future<void> reschedule({
    required String farmId,
    required String taskId,
    required String dueOn,
  }) async {
    await _patchTaskAction(
      farmId: farmId,
      taskId: taskId,
      data: {'action': 'reschedule', 'due_on': dueOn},
    );
  }

  Options _authOptions() {
    return Options(headers: _authHeaders());
  }

  Future<void> _patchTaskAction({
    required String farmId,
    required String taskId,
    required Map<String, dynamic> data,
  }) async {
    final path = '/farms/$farmId/tasks/$taskId';
    final headers = _authHeaders();

    try {
      await dio.patch<Map<String, dynamic>>(
        path,
        data: data,
        options: Options(headers: headers),
      );
    } on DioException catch (error) {
      if (!isApiConnectionProblem(error) || offlineQueue == null) {
        rethrow;
      }

      await offlineQueue!.enqueue(
        method: 'PATCH',
        path: path,
        data: data,
        headers: headers,
      );
    }
  }

  Map<String, dynamic> _authHeaders() {
    return {'Authorization': 'Bearer $token'};
  }

  bool get _isOfflineDemo => token?.startsWith('offline-demo-') == true;

  Future<List<TaskSummary>> _pendingOfflineTasks(String farmId) async {
    final actions =
        await offlineQueue?.pendingActionsFor(
          method: 'POST',
          path: '/farms/$farmId/tasks',
        ) ??
        const [];

    return actions.map((action) {
      final data = action.data;

      return TaskSummary(
        id: 'local-${action.createdAt.microsecondsSinceEpoch}',
        type: 'manual',
        title: data['title'] as String? ?? 'Pending task',
        description: data['description'] as String?,
        dueOn: data['due_on'] as String? ?? _dateValue(action.createdAt),
        dueTime: data['due_time'] as String?,
        priority: data['priority'] as String? ?? 'normal',
        status: 'open',
      );
    }).toList();
  }

  Future<Map<String, List<Map<String, dynamic>>>> _taskPatchesById(
    String farmId,
  ) async {
    final actions = await offlineQueue?.pendingActions() ?? const [];
    final prefix = '/farms/$farmId/tasks/';
    final patches = <String, List<Map<String, dynamic>>>{};

    for (final action in actions) {
      if (action.method != 'PATCH' || !action.path.startsWith(prefix)) {
        continue;
      }

      final taskId = action.path.substring(prefix.length);
      if (taskId.isEmpty) {
        continue;
      }

      patches.putIfAbsent(taskId, () => []).add(action.data);
    }

    return patches;
  }

  TaskSummary _applyOfflineTaskPatches(
    TaskSummary task,
    List<Map<String, dynamic>>? patches,
  ) {
    if (patches == null || patches.isEmpty) {
      return task;
    }

    var result = task;
    for (final patch in patches) {
      final action = patch['action'] as String?;
      result = TaskSummary(
        id: result.id,
        type: result.type,
        title: result.title,
        description: result.description,
        dueOn: action == 'reschedule'
            ? patch['due_on'] as String? ?? result.dueOn
            : result.dueOn,
        dueTime: result.dueTime,
        priority: result.priority,
        status: switch (action) {
          'complete' => 'completed',
          'cancel' => 'cancelled',
          _ => result.status,
        },
        rabbitIdentifier: result.rabbitIdentifier,
        locationName: result.locationName,
      );
    }

    return result;
  }

  bool _matchesDueFilter(TaskSummary task, String? due) {
    final today = _dateValue(DateTime.now());

    return switch (due) {
      'today' => task.dueOn == today,
      'overdue' => task.dueOn.compareTo(today) < 0,
      'upcoming' => task.dueOn.compareTo(today) > 0,
      _ => true,
    };
  }

  String _dateValue(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
