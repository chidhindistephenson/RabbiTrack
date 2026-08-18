import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/api_error_messages.dart';
import '../../shared/offline_action_queue.dart';
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
}
