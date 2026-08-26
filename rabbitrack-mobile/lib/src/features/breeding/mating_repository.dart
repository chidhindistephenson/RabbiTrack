import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/api_error_messages.dart';
import '../../shared/offline_action_queue.dart';
import '../../shared/offline_demo_data.dart';
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
    if (_isOfflineDemo) {
      final deletedIds = await _deletedMatingIds(farmId);
      final checksByMatingId = await _pregnancyChecksByMatingId(farmId);
      final matings = [
        if (isOfflineDemoFarm(farmId))
          ...offlineDemoMatings(rabbitId: rabbitId),
        ...await _pendingOfflineMatings(farmId, rabbitId: rabbitId),
      ];

      return matings
          .where((mating) => !deletedIds.contains(mating.id))
          .map(
            (mating) => _applyOfflinePregnancyStatus(
              mating,
              checksByMatingId[mating.id],
            ),
          )
          .toList();
    }

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

      final action = await offlineQueue!.enqueue(
        method: 'POST',
        path: '/farms/$farmId/matings',
        data: data,
        headers: _authHeaders(),
      );

      final dates = _offlineBreedingDates(matedAt);
      final doe = offlineDemoRabbitDetail(doeId);
      final buck = offlineDemoRabbitDetail(buckId);
      return MatingSummary(
        id: 'local-${action.createdAt.microsecondsSinceEpoch}',
        doeId: doeId,
        doeIdentifier: doe?.identifier ?? 'Pending doe',
        buckIdentifier: buck?.identifier ?? 'Pending buck',
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
    if (_isOfflineDemo) {
      final deletedIds = await _deletedMatingIds(farmId);
      if (deletedIds.contains(matingId)) {
        throw StateError('Mating record was deleted locally.');
      }

      final mating =
          (isOfflineDemoFarm(farmId)
              ? offlineDemoMatingDetail(matingId)
              : null) ??
          await _pendingOfflineMatingDetail(farmId, matingId);
      if (mating != null) {
        final checksByMatingId = await _pregnancyChecksByMatingId(farmId);
        return _applyOfflinePregnancyDetail(
          mating,
          checksByMatingId[mating.id],
        );
      }
    }

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

  bool get _isOfflineDemo => token?.startsWith('offline-demo-') == true;

  Future<List<MatingSummary>> _pendingOfflineMatings(
    String farmId, {
    String? rabbitId,
  }) async {
    final actions =
        await offlineQueue?.pendingActionsFor(
          method: 'POST',
          path: '/farms/$farmId/matings',
        ) ??
        const [];

    return actions
        .map(_summaryFromQueuedCreate)
        .where((mating) => rabbitId == null || mating.doeId == rabbitId)
        .toList();
  }

  Future<MatingDetail?> _pendingOfflineMatingDetail(
    String farmId,
    String matingId,
  ) async {
    final actions =
        await offlineQueue?.pendingActionsFor(
          method: 'POST',
          path: '/farms/$farmId/matings',
        ) ??
        const [];

    for (final action in actions) {
      final summary = _summaryFromQueuedCreate(action);
      if (summary.id != matingId) {
        continue;
      }

      final data = action.data;
      final matedAt = data['mated_at'] as String?;
      final dates = _offlineBreedingDates(
        matedAt ?? DateTime.now().toIso8601String(),
      );

      return MatingDetail(
        id: summary.id,
        doeId: summary.doeId,
        doeIdentifier: summary.doeIdentifier,
        buckIdentifier: summary.buckIdentifier,
        pregnancyCheckDueOn: summary.pregnancyCheckDueOn,
        expectedKindlingOn: summary.expectedKindlingOn,
        status: summary.status,
        matedAt: matedAt,
        outcome: data['outcome'] as String?,
        behaviorObserved: data['behavior_observed'] as String?,
        nestBoxDueOn: dates.$2,
        notes: data['notes'] as String?,
        pregnancyChecks: const [],
        litters: const [],
      );
    }

    return null;
  }

  MatingSummary _summaryFromQueuedCreate(QueuedOfflineAction action) {
    final data = action.data;
    final doeId = data['doe_id'] as String? ?? 'pending-doe';
    final buckId = data['buck_id'] as String? ?? 'pending-buck';
    final dates = _offlineBreedingDates(
      data['mated_at'] as String? ?? DateTime.now().toIso8601String(),
    );
    final doe = offlineDemoRabbitDetail(doeId);
    final buck = offlineDemoRabbitDetail(buckId);

    return MatingSummary(
      id: 'local-${action.createdAt.microsecondsSinceEpoch}',
      doeId: doeId,
      doeIdentifier: doe?.identifier ?? 'Pending doe',
      buckIdentifier: buck?.identifier ?? 'Pending buck',
      pregnancyCheckDueOn: dates.$1,
      expectedKindlingOn: dates.$2,
      status: 'awaiting_pregnancy_check',
    );
  }

  Future<Set<String>> _deletedMatingIds(String farmId) async {
    final actions = await offlineQueue?.pendingActions() ?? const [];
    final prefix = '/farms/$farmId/matings/';

    return actions
        .where(
          (action) =>
              action.method == 'DELETE' && action.path.startsWith(prefix),
        )
        .map((action) => action.path.substring(prefix.length))
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  Future<Map<String, List<PregnancyCheckSummary>>> _pregnancyChecksByMatingId(
    String farmId,
  ) async {
    final actions = await offlineQueue?.pendingActions() ?? const [];
    final prefix = '/farms/$farmId/matings/';
    final checks = <String, List<PregnancyCheckSummary>>{};

    for (final action in actions) {
      if ((action.method != 'POST' && action.method != 'PATCH') ||
          !action.path.startsWith(prefix) ||
          !action.path.contains('/pregnancy-checks')) {
        continue;
      }

      final remaining = action.path.substring(prefix.length);
      final matingId = remaining.split('/').first;
      final data = action.data;
      checks
          .putIfAbsent(matingId, () => [])
          .add(
            PregnancyCheckSummary(
              id: 'local-check-${action.createdAt.microsecondsSinceEpoch}',
              checkedOn: data['checked_on'] as String?,
              result: data['result'] as String? ?? 'unknown',
              notes: data['notes'] as String?,
            ),
          );
    }

    return checks;
  }

  MatingSummary _applyOfflinePregnancyStatus(
    MatingSummary mating,
    List<PregnancyCheckSummary>? checks,
  ) {
    if (checks == null || checks.isEmpty) {
      return mating;
    }

    final result = checks.last.result;
    return MatingSummary(
      id: mating.id,
      doeId: mating.doeId,
      doeIdentifier: mating.doeIdentifier,
      buckIdentifier: mating.buckIdentifier,
      pregnancyCheckDueOn: mating.pregnancyCheckDueOn,
      expectedKindlingOn: mating.expectedKindlingOn,
      status: switch (result) {
        'pregnant' => 'pregnant',
        'not_pregnant' => 'not_pregnant',
        _ => mating.status,
      },
    );
  }

  MatingDetail _applyOfflinePregnancyDetail(
    MatingDetail mating,
    List<PregnancyCheckSummary>? checks,
  ) {
    if (checks == null || checks.isEmpty) {
      return mating;
    }

    final summary = _applyOfflinePregnancyStatus(mating, checks);
    return MatingDetail(
      id: mating.id,
      doeId: mating.doeId,
      doeIdentifier: mating.doeIdentifier,
      buckIdentifier: mating.buckIdentifier,
      pregnancyCheckDueOn: mating.pregnancyCheckDueOn,
      expectedKindlingOn: mating.expectedKindlingOn,
      status: summary.status,
      pregnancyChecks: [...mating.pregnancyChecks, ...checks],
      litters: mating.litters,
      matedAt: mating.matedAt,
      outcome: mating.outcome,
      behaviorObserved: mating.behaviorObserved,
      nestBoxDueOn: mating.nestBoxDueOn,
      notes: mating.notes,
    );
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
