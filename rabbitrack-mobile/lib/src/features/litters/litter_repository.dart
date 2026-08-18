import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/api_error_messages.dart';
import '../../shared/offline_action_queue.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_repository.dart';
import 'litter_models.dart';

final litterRepositoryProvider = Provider<LitterRepository>((ref) {
  final session = ref.watch(authControllerProvider).valueOrNull;

  return LitterRepository(
    dio: ref.watch(dioProvider),
    token: session?.token,
    offlineQueue: ref.watch(offlineActionQueueProvider),
  );
});

class LitterRepository {
  const LitterRepository({
    required this.dio,
    required this.token,
    this.offlineQueue,
  });

  final Dio dio;
  final String? token;
  final OfflineActionQueue? offlineQueue;

  Future<List<LitterSummary>> list(String farmId) async {
    final response = await dio.get<Map<String, dynamic>>(
      '/farms/$farmId/litters',
      options: _authOptions(),
    );

    final data = response.data!['data'] as List<dynamic>;

    return data
        .map((litter) => LitterSummary.fromJson(litter as Map<String, dynamic>))
        .toList();
  }

  Future<LitterSummary> recordKindling({
    required String farmId,
    String? matingId,
    String? doeId,
    required int kitsBornAlive,
    required int kitsStillborn,
    required int kitsWeak,
    required double birthWeightValue,
    String? nestCondition,
    String? doeCondition,
    String? notes,
  }) async {
    final kindledOn = DateTime.now();
    final data = {
      'mating_id': ?matingId,
      'doe_id': ?doeId,
      'kindled_on': kindledOn.toIso8601String(),
      'kits_born_alive': kitsBornAlive,
      'kits_stillborn': kitsStillborn,
      'kits_weak': kitsWeak,
      'birth_weight_value': birthWeightValue,
      'weight_unit': 'kg',
      'nest_condition': ?nestCondition,
      'doe_condition': ?doeCondition,
      'notes': ?notes,
    };

    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/farms/$farmId/kindlings',
        data: data,
        options: _authOptions(),
      );

      return LitterSummary.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
    } on DioException catch (error) {
      if (!isApiConnectionProblem(error) || offlineQueue == null) {
        rethrow;
      }

      await offlineQueue!.enqueue(
        method: 'POST',
        path: '/farms/$farmId/kindlings',
        data: data,
        headers: _authHeaders(),
      );

      return LitterSummary(
        id: 'local-${DateTime.now().microsecondsSinceEpoch}',
        identifier: 'Pending litter',
        doeId: doeId ?? 'pending-doe',
        doeIdentifier: 'Pending doe',
        kindledOn: kindledOn.toIso8601String().split('T').first,
        currentLiveCount: kitsBornAlive,
        plannedWeaningOn: kindledOn
            .add(const Duration(days: 35))
            .toIso8601String()
            .split('T')
            .first,
        status: 'nursing',
      );
    }
  }

  Future<LitterDetail> show({
    required String farmId,
    required String litterId,
  }) async {
    final response = await dio.get<Map<String, dynamic>>(
      '/farms/$farmId/litters/$litterId',
      options: _authOptions(),
    );

    return LitterDetail.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }

  Future<void> recordWeaning({
    required String farmId,
    required String litterId,
    required int numberWeaned,
    double? averageWeightValue,
    String? destination,
    String? notes,
  }) async {
    final data = {
      'weaned_on': DateTime.now().toIso8601String(),
      'number_weaned': numberWeaned,
      'average_weight_value': averageWeightValue,
      'weight_unit': 'kg',
      'destination': destination,
      'notes': ?notes,
    };

    try {
      await dio.post<Map<String, dynamic>>(
        '/farms/$farmId/litters/$litterId/weanings',
        data: data,
        options: _authOptions(),
      );
    } on DioException catch (error) {
      if (!isApiConnectionProblem(error) || offlineQueue == null) {
        rethrow;
      }

      await offlineQueue!.enqueue(
        method: 'POST',
        path: '/farms/$farmId/litters/$litterId/weanings',
        data: data,
        headers: _authHeaders(),
      );
    }
  }

  Future<LitterConversionResult> convertKits({
    required String farmId,
    required String litterId,
    required int count,
    String sex = 'unknown',
    String? breed,
    String? colour,
    String? notes,
  }) async {
    final data = {
      'count': count,
      'sex': sex,
      'breed': breed,
      'colour': colour,
      'notes': ?notes,
    };

    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/farms/$farmId/litters/$litterId/conversions',
        data: data,
        options: _authOptions(),
      );

      return LitterConversionResult.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
    } on DioException catch (error) {
      if (!isApiConnectionProblem(error) || offlineQueue == null) {
        rethrow;
      }

      await offlineQueue!.enqueue(
        method: 'POST',
        path: '/farms/$farmId/litters/$litterId/conversions',
        data: data,
        headers: _authHeaders(),
      );

      return LitterConversionResult(
        convertedCount: count,
        remainingCount: 0,
        rabbits: const [],
      );
    }
  }

  Future<LitterCheckSummary> recordCheck({
    required String farmId,
    required String litterId,
    required int liveCount,
    int deadCount = 0,
    int weakCount = 0,
    String? suspectedCause,
    String? nestObservation,
    String? correctiveAction,
    String? notes,
  }) async {
    final checkedOn = DateTime.now();
    final data = {
      'checked_on': checkedOn.toIso8601String(),
      'live_count': liveCount,
      'dead_count': deadCount,
      'weak_count': weakCount,
      'suspected_cause': suspectedCause,
      'nest_observation': nestObservation,
      'corrective_action': correctiveAction,
      'notes': ?notes,
    };

    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/farms/$farmId/litters/$litterId/checks',
        data: data,
        options: _authOptions(),
      );

      return LitterCheckSummary.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
    } on DioException catch (error) {
      if (!isApiConnectionProblem(error) || offlineQueue == null) {
        rethrow;
      }

      await offlineQueue!.enqueue(
        method: 'POST',
        path: '/farms/$farmId/litters/$litterId/checks',
        data: data,
        headers: _authHeaders(),
      );

      return LitterCheckSummary(
        id: 'local-${DateTime.now().microsecondsSinceEpoch}',
        checkedOn: checkedOn.toIso8601String().split('T').first,
        liveCount: liveCount,
        deadCount: deadCount,
        weakCount: weakCount,
        suspectedCause: suspectedCause,
        nestObservation: nestObservation,
        correctiveAction: correctiveAction,
        notes: notes,
      );
    }
  }

  Future<LitterFosterSummary> recordFoster({
    required String farmId,
    required String fromLitterId,
    required String toLitterId,
    required int kitCount,
    String? reason,
    String? notes,
  }) async {
    final fosteredOn = DateTime.now();
    final data = {
      'to_litter_id': toLitterId,
      'fostered_on': fosteredOn.toIso8601String(),
      'kit_count': kitCount,
      'reason': ?reason,
      'notes': ?notes,
    };

    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/farms/$farmId/litters/$fromLitterId/fosters',
        data: data,
        options: _authOptions(),
      );

      return LitterFosterSummary.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
    } on DioException catch (error) {
      if (!isApiConnectionProblem(error) || offlineQueue == null) {
        rethrow;
      }

      await offlineQueue!.enqueue(
        method: 'POST',
        path: '/farms/$farmId/litters/$fromLitterId/fosters',
        data: data,
        headers: _authHeaders(),
      );

      return LitterFosterSummary(
        id: 'local-${DateTime.now().microsecondsSinceEpoch}',
        fosteredOn: fosteredOn.toIso8601String().split('T').first,
        kitCount: kitCount,
        reason: reason,
        notes: notes,
        fromLitterId: fromLitterId,
        toLitterId: toLitterId,
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
