import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/api_error_messages.dart';
import '../../shared/offline_action_queue.dart';
import '../../shared/offline_demo_data.dart';
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
    if (_isOfflineDemo) {
      return _pendingOfflineWeights(
        farmId,
        rabbitId: rabbitId,
        litterId: litterId,
      );
    }

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

  bool get _isOfflineDemo => token?.startsWith('offline-demo-') == true;

  Future<List<WeightSummary>> _pendingOfflineWeights(
    String farmId, {
    String? rabbitId,
    String? litterId,
  }) async {
    final actions =
        await offlineQueue?.pendingActionsFor(
          method: 'POST',
          path: '/farms/$farmId/weights',
        ) ??
        const <QueuedOfflineAction>[];

    return actions
        .map((action) {
          final data = action.data;
          final localRabbitId = data['rabbit_id'] as String?;
          final localLitterId = data['litter_id'] as String?;
          if (rabbitId != null && localRabbitId != rabbitId) {
            return null;
          }
          if (litterId != null && localLitterId != litterId) {
            return null;
          }

          final weightValue = data['weight_value'];
          if (weightValue == null) {
            return null;
          }

          final rabbit = localRabbitId == null
              ? null
              : offlineDemoRabbitDetail(localRabbitId);
          final litter = localLitterId == null
              ? null
              : offlineDemoLitterDetail(localLitterId);

          return WeightSummary(
            id: 'local-${action.createdAt.microsecondsSinceEpoch}',
            rabbitIdentifier: rabbit?.identifier ?? localRabbitId,
            litterIdentifier: litter?.identifier ?? localLitterId,
            weighedOn: _dateValue(
              data['weighed_on'] as String? ??
                  action.createdAt.toIso8601String(),
            ),
            weightValue: weightValue.toString(),
            weightUnit: data['weight_unit'] as String? ?? 'kg',
            stage: data['stage'] as String?,
            kitCount: data['kit_count'] as int?,
            averageWeightValue: data['average_weight_value']?.toString(),
            method: data['method'] as String?,
            notes: data['notes'] as String?,
          );
        })
        .whereType<WeightSummary>()
        .toList();
  }

  String _dateValue(String value) {
    return value.split('T').first;
  }
}
