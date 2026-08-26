import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/api_error_messages.dart';
import '../../shared/offline_action_queue.dart';
import '../../shared/offline_demo_data.dart';
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
    if (_isOfflineDemo) {
      return [
        if (isOfflineDemoFarm(farmId)) ...offlineDemoLitters(),
        ...await _pendingOfflineLitters(farmId),
      ];
    }

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
    if (_isOfflineDemo) {
      final litter = isOfflineDemoFarm(farmId)
          ? offlineDemoLitterDetail(litterId)
          : null;
      if (litter != null) {
        return litter;
      }
      final pending = await _pendingOfflineLitter(farmId, litterId);
      if (pending != null) {
        return pending;
      }
    }

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

  bool get _isOfflineDemo => token?.startsWith('offline-demo-') == true;

  Future<List<LitterSummary>> _pendingOfflineLitters(String farmId) async {
    final actions =
        await offlineQueue?.pendingActionsFor(
          method: 'POST',
          path: '/farms/$farmId/kindlings',
        ) ??
        const <QueuedOfflineAction>[];

    return actions
        .map((action) => _litterFromQueuedKindling(action))
        .whereType<LitterSummary>()
        .toList();
  }

  Future<LitterDetail?> _pendingOfflineLitter(
    String farmId,
    String litterId,
  ) async {
    final actions =
        await offlineQueue?.pendingActionsFor(
          method: 'POST',
          path: '/farms/$farmId/kindlings',
        ) ??
        const <QueuedOfflineAction>[];

    for (final action in actions) {
      final summary = _litterFromQueuedKindling(action);
      if (summary == null || summary.id != litterId) {
        continue;
      }

      final data = action.data;
      final birthWeight = data['birth_weight_value'];
      final weightValue = birthWeight?.toString();
      final kitCount = data['kits_born_alive'] as int? ?? 0;
      final averageWeight = birthWeight is num && kitCount > 0
          ? (birthWeight / kitCount).toStringAsFixed(3)
          : null;

      return LitterDetail(
        id: summary.id,
        identifier: summary.identifier,
        doeId: summary.doeId,
        doeIdentifier: summary.doeIdentifier,
        buckId: summary.buckId,
        buckIdentifier: summary.buckIdentifier,
        kindledOn: summary.kindledOn,
        currentLiveCount: summary.currentLiveCount,
        plannedWeaningOn: summary.plannedWeaningOn,
        status: summary.status,
        convertedRabbitsCount: summary.convertedRabbitsCount,
        unconvertedKitsCount: summary.unconvertedKitsCount,
        kitsBornAlive: data['kits_born_alive'] as int? ?? 0,
        kitsStillborn: data['kits_stillborn'] as int? ?? 0,
        kitsWeak: data['kits_weak'] as int? ?? 0,
        notes: data['notes'] as String?,
        weanings: const [],
        checks: const [],
        fostersOut: const [],
        fostersIn: const [],
        weights: weightValue == null
            ? const []
            : [
                LitterWeightSummary(
                  id: '${summary.id}-birth-weight',
                  weighedOn: summary.kindledOn,
                  weightValue: weightValue,
                  weightUnit: data['weight_unit'] as String? ?? 'kg',
                  stage: 'birth',
                  kitCount: kitCount,
                  averageWeightValue: averageWeight,
                  method: 'kindling',
                ),
              ],
      );
    }

    return null;
  }

  LitterSummary? _litterFromQueuedKindling(QueuedOfflineAction action) {
    final data = action.data;
    final kindledOn = _dateValue(
      data['kindled_on'] as String? ?? action.createdAt.toIso8601String(),
    );
    final doeId = data['doe_id'] as String?;
    final matingId = data['mating_id'] as String?;
    final mating = matingId == null ? null : offlineDemoMatingDetail(matingId);
    final doe = offlineDemoRabbitDetail(doeId ?? mating?.doeId ?? '');
    final kitsBornAlive = data['kits_born_alive'] as int? ?? 0;

    return LitterSummary(
      id: 'local-${action.createdAt.microsecondsSinceEpoch}',
      identifier: 'LIT-${kindledOn.replaceAll('-', '').substring(2)}-LOCAL',
      doeId: doeId ?? mating?.doeId ?? 'pending-doe',
      doeIdentifier: doe?.identifier ?? mating?.doeIdentifier ?? 'Pending doe',
      buckIdentifier: mating?.buckIdentifier,
      kindledOn: kindledOn,
      currentLiveCount: kitsBornAlive,
      convertedRabbitsCount: 0,
      unconvertedKitsCount: kitsBornAlive,
      plannedWeaningOn: _dateValue(
        DateTime.tryParse(
              kindledOn,
            )?.add(const Duration(days: 35)).toIso8601String() ??
            action.createdAt.add(const Duration(days: 35)).toIso8601String(),
      ),
      status: 'nursing',
    );
  }

  String _dateValue(String value) {
    return value.split('T').first;
  }
}
