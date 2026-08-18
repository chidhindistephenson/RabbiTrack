import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/api_error_messages.dart';
import '../../shared/offline_action_queue.dart';
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
}
