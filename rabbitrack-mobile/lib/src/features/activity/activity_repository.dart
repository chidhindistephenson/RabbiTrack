import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/offline_action_queue.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_repository.dart';
import 'activity_models.dart';

final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  final session = ref.watch(authControllerProvider).valueOrNull;

  return ActivityRepository(
    dio: ref.watch(dioProvider),
    token: session?.token,
    offlineQueue: ref.watch(offlineActionQueueProvider),
  );
});

class ActivityRepository {
  const ActivityRepository({
    required this.dio,
    required this.token,
    this.offlineQueue,
  });

  final Dio dio;
  final String? token;
  final OfflineActionQueue? offlineQueue;

  Future<List<ActivityLogSummary>> list(String farmId) async {
    if (_isOfflineDemo) {
      return [
        if (farmId == 'offline-demo-farm')
          const ActivityLogSummary(
            id: 'offline-activity-login',
            action: 'offline_demo',
            description: 'Offline demo farm opened',
            actorName: 'RabbiTrack',
            createdAt: '2026-08-19T08:00:00Z',
          ),
        ...await _pendingOfflineActivity(farmId),
      ];
    }

    final response = await dio.get<Map<String, dynamic>>(
      '/farms/$farmId/activity',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    final data = response.data!['data'] as List<dynamic>;

    return data
        .map((log) => ActivityLogSummary.fromJson(log as Map<String, dynamic>))
        .toList();
  }

  bool get _isOfflineDemo => token?.startsWith('offline-demo-') == true;

  Future<List<ActivityLogSummary>> _pendingOfflineActivity(
    String farmId,
  ) async {
    final actions =
        (await offlineQueue?.pendingActions() ?? const <QueuedOfflineAction>[])
            .where((action) => action.path.startsWith('/farms/$farmId/'))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return actions
        .map(
          (action) => ActivityLogSummary(
            id: 'local-${action.createdAt.microsecondsSinceEpoch}',
            action: action.method.toLowerCase(),
            description: _descriptionFor(action),
            actorName: 'Offline queue',
            createdAt: action.createdAt.toIso8601String(),
          ),
        )
        .toList();
  }

  String _descriptionFor(QueuedOfflineAction action) {
    final path = action.path;
    if (path.endsWith('/rabbits')) {
      return 'Rabbit saved locally';
    }
    if (path.contains('/rabbits/') && path.endsWith('/movements')) {
      return 'Rabbit move saved locally';
    }
    if (path.endsWith('/matings')) {
      return 'Mating record saved locally';
    }
    if (path.endsWith('/kindlings')) {
      return 'Kindling record saved locally';
    }
    if (path.endsWith('/health-events')) {
      return 'Health event saved locally';
    }
    if (path.endsWith('/weights')) {
      return 'Weight record saved locally';
    }
    if (path.endsWith('/tasks')) {
      return 'Task saved locally';
    }
    if (path.endsWith('/sales')) {
      return 'Sale saved locally';
    }
    if (path.endsWith('/expenses')) {
      return 'Expense saved locally';
    }
    if (path.endsWith('/locations')) {
      return 'Location saved locally';
    }
    if (path.endsWith('/members')) {
      return 'Team invitation saved locally';
    }

    return 'Farm change saved locally';
  }
}
