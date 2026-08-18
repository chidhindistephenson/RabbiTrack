import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/api_error_messages.dart';
import '../../shared/offline_action_queue.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_repository.dart';
import 'weight_models.dart';

final weightRepositoryProvider = Provider<WeightRepository>((ref) {
  final session = ref.watch(authControllerProvider).valueOrNull;

  return WeightRepository(
    dio: ref.watch(dioProvider),
    token: session?.token,
    offlineQueue: ref.watch(offlineActionQueueProvider),
  );
});

class WeightRepository {
  const WeightRepository({
    required this.dio,
    required this.token,
    this.offlineQueue,
  });

  final Dio dio;
  final String? token;
  final OfflineActionQueue? offlineQueue;

  Future<List<WeightSummary>> list(
    String farmId, {
    String? rabbitId,
    String? litterId,
  }) async {
    final response = await dio.get<Map<String, dynamic>>(
      '/farms/$farmId/weights',
      queryParameters: {'rabbit_id': ?rabbitId, 'litter_id': ?litterId},
      options: _authOptions(),
    );

    final data = response.data!['data'] as List<dynamic>;

    return data
        .map((weight) => WeightSummary.fromJson(weight as Map<String, dynamic>))
        .toList();
  }

  Future<WeightSummary> recordRabbitWeight({
    required String farmId,
    required String rabbitId,
    required double weightValue,
    String? method,
    String? notes,
  }) async {
    final weighedOn = DateTime.now();
    final data = {
      'rabbit_id': rabbitId,
      'weighed_on': weighedOn.toIso8601String(),
      'weight_value': weightValue,
      'weight_unit': 'kg',
      'method': method ?? 'field entry',
      'notes': ?notes,
    };

    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/farms/$farmId/weights',
        data: data,
        options: _authOptions(),
      );

      return WeightSummary.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
    } on DioException catch (error) {
      if (!isApiConnectionProblem(error) || offlineQueue == null) {
        rethrow;
      }

      await offlineQueue!.enqueue(
        method: 'POST',
        path: '/farms/$farmId/weights',
        data: data,
        headers: _authHeaders(),
      );

      return WeightSummary(
        id: 'local-${DateTime.now().microsecondsSinceEpoch}',
        rabbitIdentifier: 'Pending rabbit',
        weighedOn: weighedOn.toIso8601String().split('T').first,
        weightValue: weightValue.toStringAsFixed(3),
        weightUnit: 'kg',
        method: method ?? 'field entry',
        notes: notes,
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
