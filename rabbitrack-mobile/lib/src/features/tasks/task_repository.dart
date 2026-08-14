import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import '../auth/auth_repository.dart';
import 'task_models.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final session = ref.watch(authControllerProvider).valueOrNull;

  return TaskRepository(dio: ref.watch(dioProvider), token: session?.token);
});

class TaskRepository {
  const TaskRepository({required this.dio, required this.token});

  final Dio dio;
  final String? token;

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
    final response = await dio.post<Map<String, dynamic>>(
      '/farms/$farmId/tasks',
      data: {
        'title': title,
        'description': description,
        'due_on': dueOn,
        'due_time': dueTime,
        'priority': priority,
        'rabbit_id': rabbitId,
        'location_id': locationId,
      },
      options: _authOptions(),
    );

    return TaskSummary.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  Future<void> complete({
    required String farmId,
    required String taskId,
  }) async {
    await dio.patch<Map<String, dynamic>>(
      '/farms/$farmId/tasks/$taskId',
      data: {'action': 'complete'},
      options: _authOptions(),
    );
  }

  Future<void> cancel({required String farmId, required String taskId}) async {
    await dio.patch<Map<String, dynamic>>(
      '/farms/$farmId/tasks/$taskId',
      data: {'action': 'cancel'},
      options: _authOptions(),
    );
  }

  Future<TaskSummary> reschedule({
    required String farmId,
    required String taskId,
    required String dueOn,
  }) async {
    final response = await dio.patch<Map<String, dynamic>>(
      '/farms/$farmId/tasks/$taskId',
      data: {'action': 'reschedule', 'due_on': dueOn},
      options: _authOptions(),
    );

    return TaskSummary.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  Options _authOptions() {
    return Options(headers: {'Authorization': 'Bearer $token'});
  }
}
