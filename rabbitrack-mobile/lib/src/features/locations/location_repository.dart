import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/api_error_messages.dart';
import '../../shared/offline_action_queue.dart';
import '../../shared/offline_demo_data.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_repository.dart';
import 'location_models.dart';

final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  final session = ref.watch(authControllerProvider).valueOrNull;

  return LocationRepository(
    dio: ref.watch(dioProvider),
    token: session?.token,
    offlineQueue: ref.watch(offlineActionQueueProvider),
  );
});

class LocationRepository {
  const LocationRepository({
    required this.dio,
    required this.token,
    this.offlineQueue,
  });

  final Dio dio;
  final String? token;
  final OfflineActionQueue? offlineQueue;

  Future<List<FarmLocationSummary>> list(String farmId) async {
    if (_isOfflineDemo) {
      return [
        if (isOfflineDemoFarm(farmId)) ...offlineDemoLocations(),
        ...await _pendingOfflineLocations(farmId),
      ];
    }

    final response = await dio.get<Map<String, dynamic>>(
      '/farms/$farmId/locations',
      options: _authOptions(),
    );

    final data = response.data!['data'] as List<dynamic>;

    return data
        .map(
          (location) =>
              FarmLocationSummary.fromJson(location as Map<String, dynamic>),
        )
        .toList();
  }

  Future<FarmLocationSummary> create({
    required String farmId,
    required String type,
    required String name,
    String? parentId,
    String? code,
    int? capacity,
    String? notes,
  }) async {
    final data = {
      'parent_id': parentId,
      'type': type,
      'name': name,
      'code': code,
      'capacity': capacity,
      'notes': notes,
    };

    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/farms/$farmId/locations',
        data: data,
        options: _authOptions(),
      );

      return FarmLocationSummary.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
    } on DioException catch (error) {
      if (!isApiConnectionProblem(error) || offlineQueue == null) {
        rethrow;
      }

      await offlineQueue!.enqueue(
        method: 'POST',
        path: '/farms/$farmId/locations',
        data: data,
        headers: _authHeaders(),
      );

      return FarmLocationSummary(
        id: 'local-${DateTime.now().microsecondsSinceEpoch}',
        parentId: parentId,
        type: type,
        name: name,
        code: code,
        capacity: capacity,
        occupiedCount: 0,
        isActive: true,
        notes: notes,
      );
    }
  }

  Future<FarmLocationSummary> update({
    required String farmId,
    required String locationId,
    required String type,
    required String name,
    String? code,
    int? capacity,
    required bool isActive,
    String? notes,
  }) async {
    final data = {
      'type': type,
      'name': name,
      'code': code,
      'capacity': capacity,
      'is_active': isActive,
      'notes': notes,
    };

    try {
      final response = await dio.patch<Map<String, dynamic>>(
        '/farms/$farmId/locations/$locationId',
        data: data,
        options: _authOptions(),
      );

      return FarmLocationSummary.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
    } on DioException catch (error) {
      if (!isApiConnectionProblem(error) || offlineQueue == null) {
        rethrow;
      }

      await offlineQueue!.enqueue(
        method: 'PATCH',
        path: '/farms/$farmId/locations/$locationId',
        data: data,
        headers: _authHeaders(),
      );

      return FarmLocationSummary(
        id: locationId,
        type: type,
        name: name,
        code: code,
        capacity: capacity,
        occupiedCount: 0,
        isActive: isActive,
        notes: notes,
      );
    }
  }

  Future<FarmLocationDetail> show({
    required String farmId,
    required String locationId,
  }) async {
    if (_isOfflineDemo) {
      final location = isOfflineDemoFarm(farmId)
          ? offlineDemoLocationDetail(locationId)
          : null;
      if (location != null) {
        return location;
      }
      final pending = await _pendingOfflineLocation(farmId, locationId);
      if (pending != null) {
        return pending;
      }
    }

    final response = await dio.get<Map<String, dynamic>>(
      '/farms/$farmId/locations/$locationId',
      options: _authOptions(),
    );

    return FarmLocationDetail.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }

  Options _authOptions() {
    return Options(headers: _authHeaders());
  }

  Map<String, dynamic> _authHeaders() {
    return {'Authorization': 'Bearer $token'};
  }

  bool get _isOfflineDemo => token?.startsWith('offline-demo-') == true;

  Future<List<FarmLocationSummary>> _pendingOfflineLocations(
    String farmId,
  ) async {
    final actions =
        await offlineQueue?.pendingActionsFor(
          method: 'POST',
          path: '/farms/$farmId/locations',
        ) ??
        const <QueuedOfflineAction>[];

    return actions
        .map((action) => _locationFromQueuedCreate(action))
        .whereType<FarmLocationSummary>()
        .toList();
  }

  Future<FarmLocationDetail?> _pendingOfflineLocation(
    String farmId,
    String locationId,
  ) async {
    final actions =
        await offlineQueue?.pendingActionsFor(
          method: 'POST',
          path: '/farms/$farmId/locations',
        ) ??
        const <QueuedOfflineAction>[];

    for (final action in actions) {
      final id = _localIdFor(action);
      if (id != locationId) {
        continue;
      }

      final summary = _locationFromQueuedCreate(action);
      if (summary == null) {
        return null;
      }

      return FarmLocationDetail(
        id: summary.id,
        parentId: summary.parentId,
        type: summary.type,
        name: summary.name,
        code: summary.code,
        capacity: summary.capacity,
        occupiedCount: summary.occupiedCount,
        isActive: summary.isActive,
        notes: summary.notes,
        rabbits: const [],
      );
    }

    return null;
  }

  FarmLocationSummary? _locationFromQueuedCreate(QueuedOfflineAction action) {
    final data = action.data;
    final type = data['type'] as String?;
    final name = data['name'] as String?;
    if (type == null || name == null) {
      return null;
    }

    return FarmLocationSummary(
      id: _localIdFor(action),
      parentId: data['parent_id'] as String?,
      type: type,
      name: name,
      code: data['code'] as String?,
      capacity: data['capacity'] as int?,
      occupiedCount: 0,
      isActive: true,
      notes: data['notes'] as String?,
    );
  }

  String _localIdFor(QueuedOfflineAction action) {
    return 'local-${action.createdAt.microsecondsSinceEpoch}';
  }
}
