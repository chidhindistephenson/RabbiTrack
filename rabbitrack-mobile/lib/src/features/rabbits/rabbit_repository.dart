import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/api_error_messages.dart';
import '../../shared/offline_action_queue.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_repository.dart';
import 'rabbit_models.dart';

final rabbitRepositoryProvider = Provider<RabbitRepository>((ref) {
  final session = ref.watch(authControllerProvider).valueOrNull;

  return RabbitRepository(
    dio: ref.watch(dioProvider),
    token: session?.token,
    offlineQueue: ref.watch(offlineActionQueueProvider),
  );
});

class RabbitRepository {
  const RabbitRepository({
    required this.dio,
    required this.token,
    this.offlineQueue,
  });

  final Dio dio;
  final String? token;
  final OfflineActionQueue? offlineQueue;

  Future<List<RabbitSummary>> list(
    String farmId, {
    String? search,
    String? sex,
    String? status,
    String? breed,
  }) async {
    final response = await dio.get<Map<String, dynamic>>(
      '/farms/$farmId/rabbits',
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        'sex': ?sex,
        'status': ?status,
        'breed': ?breed,
      },
      options: _authOptions(),
    );

    final data = response.data!['data'] as List<dynamic>;

    return data
        .map((rabbit) => RabbitSummary.fromJson(rabbit as Map<String, dynamic>))
        .toList();
  }

  Future<RabbitSummary> create({
    required String farmId,
    required String sex,
    required String status,
    String? name,
    String? breed,
    String? colour,
    String? currentLocationId,
    String? dateOfBirth,
    String? weightValue,
    String? weightUnit,
    String? tagOrTattoo,
    String? notes,
    String? motherId,
    String? fatherId,
    String? originType,
    String? originLitterId,
    String? supplier,
    String? acquiredAt,
    String? acquisitionCost,
  }) async {
    final data = {
      'sex': sex,
      'status': status,
      'name': ?name,
      'breed': ?breed,
      'colour': ?colour,
      'current_location_id': ?currentLocationId,
      'date_of_birth': ?dateOfBirth,
      'weight_value': ?weightValue,
      'weight_unit': ?weightUnit,
      'tag_or_tattoo': ?tagOrTattoo,
      'notes': ?notes,
      'mother_id': ?motherId,
      'father_id': ?fatherId,
      'origin_type': ?originType,
      'origin_litter_id': ?originLitterId,
      'supplier': ?supplier,
      'acquired_at': ?acquiredAt,
      'acquisition_cost': ?acquisitionCost,
    };

    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/farms/$farmId/rabbits',
        data: data,
        options: _authOptions(),
      );

      return RabbitSummary.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
    } on DioException catch (error) {
      if (!isApiConnectionProblem(error) || offlineQueue == null) {
        rethrow;
      }

      await offlineQueue!.enqueue(
        method: 'POST',
        path: '/farms/$farmId/rabbits',
        data: data,
        headers: _authHeaders(),
      );

      return RabbitSummary(
        id: 'local-${DateTime.now().microsecondsSinceEpoch}',
        identifier: 'Pending ID',
        name: name,
        sex: sex,
        breed: breed,
        status: status,
      );
    }
  }

  Future<RabbitDetail> show({
    required String farmId,
    required String rabbitId,
  }) async {
    final response = await dio.get<Map<String, dynamic>>(
      '/farms/$farmId/rabbits/$rabbitId',
      options: _authOptions(),
    );

    return RabbitDetail.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }

  Future<RabbitMovementResult> move({
    required String farmId,
    required String rabbitId,
    required String toLocationId,
    String? reason,
    String? notes,
  }) async {
    final data = {
      'to_location_id': toLocationId,
      'reason': reason,
      'notes': notes,
    };

    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/farms/$farmId/rabbits/$rabbitId/movements',
        data: data,
        options: _authOptions(),
      );

      return RabbitMovementResult.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
    } on DioException catch (error) {
      if (!isApiConnectionProblem(error) || offlineQueue == null) {
        rethrow;
      }

      await offlineQueue!.enqueue(
        method: 'POST',
        path: '/farms/$farmId/rabbits/$rabbitId/movements',
        data: data,
        headers: _authHeaders(),
      );

      return RabbitMovementResult(
        id: 'local-${DateTime.now().microsecondsSinceEpoch}',
        rabbitId: rabbitId,
        toLocationId: toLocationId,
        movedAt: DateTime.now().toIso8601String(),
        reason: reason,
        notes: notes,
      );
    }
  }

  Future<RabbitSummary> updateStatus({
    required String farmId,
    required String rabbitId,
    required String status,
    String? notes,
  }) async {
    final data = {'status': status, 'notes': ?notes};

    try {
      final response = await dio.patch<Map<String, dynamic>>(
        '/farms/$farmId/rabbits/$rabbitId',
        data: data,
        options: _authOptions(),
      );

      return RabbitSummary.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
    } on DioException catch (error) {
      if (!isApiConnectionProblem(error) || offlineQueue == null) {
        rethrow;
      }

      await offlineQueue!.enqueue(
        method: 'PATCH',
        path: '/farms/$farmId/rabbits/$rabbitId',
        data: data,
        headers: _authHeaders(),
      );

      return RabbitSummary(
        id: rabbitId,
        identifier: 'Pending update',
        sex: 'unknown',
        status: status,
      );
    }
  }

  Future<RabbitSummary> updateProfile({
    required String farmId,
    required String rabbitId,
    required String sex,
    required String status,
    String? name,
    String? breed,
    String? colour,
    String? currentLocationId,
    String? dateOfBirth,
    String? weightValue,
    String? weightUnit,
    String? tagOrTattoo,
    String? notes,
    String? motherId,
    String? fatherId,
  }) async {
    final data = {
      'sex': sex,
      'status': status,
      'name': name,
      'breed': breed,
      'colour': colour,
      'current_location_id': currentLocationId,
      'date_of_birth': dateOfBirth,
      'weight_value': weightValue,
      'weight_unit': weightUnit,
      'tag_or_tattoo': tagOrTattoo,
      'notes': notes,
      'mother_id': motherId,
      'father_id': fatherId,
    };

    try {
      final response = await dio.patch<Map<String, dynamic>>(
        '/farms/$farmId/rabbits/$rabbitId',
        data: data,
        options: _authOptions(),
      );

      return RabbitSummary.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
    } on DioException catch (error) {
      if (!isApiConnectionProblem(error) || offlineQueue == null) {
        rethrow;
      }

      await offlineQueue!.enqueue(
        method: 'PATCH',
        path: '/farms/$farmId/rabbits/$rabbitId',
        data: data,
        headers: _authHeaders(),
      );

      return RabbitSummary(
        id: rabbitId,
        identifier: 'Pending update',
        name: name,
        sex: sex,
        breed: breed,
        status: status,
      );
    }
  }

  Options _authOptions() {
    return Options(headers: _authHeaders());
  }

  Map<String, dynamic> _authHeaders() {
    return {'Authorization': 'Bearer $token'};
  }
}
