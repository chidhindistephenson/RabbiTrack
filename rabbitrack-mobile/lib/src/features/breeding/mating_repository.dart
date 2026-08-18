import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/api_error_messages.dart';
import '../../shared/offline_action_queue.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_repository.dart';
import 'mating_models.dart';

final matingRepositoryProvider = Provider<MatingRepository>((ref) {
  final session = ref.watch(authControllerProvider).valueOrNull;

  return MatingRepository(
    dio: ref.watch(dioProvider),
    token: session?.token,
    offlineQueue: ref.watch(offlineActionQueueProvider),
  );
});

class MatingRepository {
  const MatingRepository({
    required this.dio,
    required this.token,
    this.offlineQueue,
  });

  final Dio dio;
  final String? token;
  final OfflineActionQueue? offlineQueue;

  Future<List<MatingSummary>> list(String farmId, {String? rabbitId}) async {
    final response = await dio.get<Map<String, dynamic>>(
      '/farms/$farmId/matings',
      queryParameters: {'rabbit_id': ?rabbitId},
      options: _authOptions(),
    );

    final data = response.data!['data'] as List<dynamic>;

    return data
        .map((mating) => MatingSummary.fromJson(mating as Map<String, dynamic>))
        .toList();
  }

  Future<MatingSummary> create({
    required String farmId,
    required String doeId,
    required String buckId,
    required String matedAt,
    required String outcome,
    String? behaviorObserved,
    String? notes,
    bool confirmRelationshipRisk = false,
  }) async {
    final data = {
      'doe_id': doeId,
      'buck_id': buckId,
      'mated_at': matedAt,
      'outcome': outcome,
      'behavior_observed': ?behaviorObserved,
      'notes': ?notes,
      'confirm_relationship_risk': confirmRelationshipRisk,
    };

    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/farms/$farmId/matings',
        data: data,
        options: _authOptions(),
      );

      return MatingSummary.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
    } on DioException catch (error) {
      if (!isApiConnectionProblem(error) || offlineQueue == null) {
        rethrow;
      }

      await offlineQueue!.enqueue(
        method: 'POST',
        path: '/farms/$farmId/matings',
        data: data,
        headers: _authHeaders(),
      );

      final dates = _offlineBreedingDates(matedAt);
      return MatingSummary(
        id: 'local-${DateTime.now().microsecondsSinceEpoch}',
        doeId: doeId,
        doeIdentifier: 'Pending doe',
        buckIdentifier: 'Pending buck',
        pregnancyCheckDueOn: dates.$1,
        expectedKindlingOn: dates.$2,
        status: 'awaiting_pregnancy_check',
      );
    }
  }

  Future<MatingDetail> show({
    required String farmId,
    required String matingId,
  }) async {
    final response = await dio.get<Map<String, dynamic>>(
      '/farms/$farmId/matings/$matingId',
      options: _authOptions(),
    );

    return MatingDetail.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }

  Future<void> recordPregnancyCheck({
    required String farmId,
    required String matingId,
    required String result,
    String? notes,
  }) async {
    final data = {
      'checked_on': DateTime.now().toIso8601String(),
      'result': result,
      'notes': ?notes,
    };

    await _writeOrQueue(
      method: 'POST',
      path: '/farms/$farmId/matings/$matingId/pregnancy-checks',
      data: data,
    );
  }

  Future<void> revisePregnancyDecision({
    required String farmId,
    required String matingId,
    required String result,
    String? notes,
  }) async {
    final data = {
      'checked_on': DateTime.now().toIso8601String(),
      'result': result,
      'notes': ?notes,
    };

    await _writeOrQueue(
      method: 'PATCH',
      path: '/farms/$farmId/matings/$matingId/pregnancy-checks/latest',
      data: data,
    );
  }

  Future<void> delete({
    required String farmId,
    required String matingId,
  }) async {
    await _writeOrQueue(
      method: 'DELETE',
      path: '/farms/$farmId/matings/$matingId',
    );
  }

  Options _authOptions() {
    return Options(headers: _authHeaders());
  }

  Map<String, dynamic> _authHeaders() {
    return {'Authorization': 'Bearer $token'};
  }

  Future<void> _writeOrQueue({
    required String method,
    required String path,
    Map<String, dynamic>? data,
  }) async {
    try {
      await dio.request<Map<String, dynamic>>(
        path,
        data: data,
        options: _authOptions().copyWith(method: method),
      );
    } on DioException catch (error) {
      if (!isApiConnectionProblem(error) || offlineQueue == null) {
        rethrow;
      }

      await offlineQueue!.enqueue(
        method: method,
        path: path,
        data: data ?? const {},
        headers: _authHeaders(),
      );
    }
  }

  (String, String) _offlineBreedingDates(String matedAt) {
    final parsed = DateTime.tryParse(matedAt) ?? DateTime.now();
    return (
      parsed.add(const Duration(days: 14)).toIso8601String().split('T').first,
      parsed.add(const Duration(days: 31)).toIso8601String().split('T').first,
    );
  }
}
