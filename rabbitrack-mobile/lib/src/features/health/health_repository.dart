import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/api_error_messages.dart';
import '../../shared/offline_action_queue.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_repository.dart';
import 'health_models.dart';

final healthRepositoryProvider = Provider<HealthRepository>((ref) {
  final session = ref.watch(authControllerProvider).valueOrNull;

  return HealthRepository(
    dio: ref.watch(dioProvider),
    token: session?.token,
    offlineQueue: ref.watch(offlineActionQueueProvider),
  );
});

class HealthRepository {
  const HealthRepository({
    required this.dio,
    required this.token,
    this.offlineQueue,
  });

  final Dio dio;
  final String? token;
  final OfflineActionQueue? offlineQueue;

  Future<List<HealthEventSummary>> list(
    String farmId, {
    String? rabbitId,
  }) async {
    final response = await dio.get<Map<String, dynamic>>(
      '/farms/$farmId/health-events',
      queryParameters: {'rabbit_id': ?rabbitId},
      options: _authOptions(),
    );

    final data = response.data!['data'] as List<dynamic>;

    return data
        .map(
          (event) => HealthEventSummary.fromJson(event as Map<String, dynamic>),
        )
        .toList();
  }

  Future<HealthEventSummary> create({
    required String farmId,
    required String rabbitId,
    required String symptoms,
    required String severity,
    String? diagnosis,
    String? bodySystem,
    String? notes,
    bool isolationRequired = false,
  }) async {
    final observedOn = DateTime.now();
    final data = {
      'rabbit_id': rabbitId,
      'observed_on': observedOn.toIso8601String(),
      'symptoms': symptoms,
      'diagnosis': diagnosis,
      'severity': severity,
      'body_system': bodySystem,
      'isolation_required': isolationRequired,
      'notes': notes,
    };

    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/farms/$farmId/health-events',
        data: data,
        options: _authOptions(),
      );

      return HealthEventSummary.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
    } on DioException catch (error) {
      if (!isApiConnectionProblem(error) || offlineQueue == null) {
        rethrow;
      }

      await offlineQueue!.enqueue(
        method: 'POST',
        path: '/farms/$farmId/health-events',
        data: data,
        headers: _authHeaders(),
      );

      return HealthEventSummary(
        id: 'local-${DateTime.now().microsecondsSinceEpoch}',
        rabbitIdentifier: 'Pending rabbit',
        observedOn: observedOn.toIso8601String().split('T').first,
        symptoms: symptoms,
        diagnosis: diagnosis,
        bodySystem: bodySystem,
        severity: severity,
        status: 'open',
        isolationRequired: isolationRequired,
        treatmentsCount: 0,
        notes: notes,
      );
    }
  }

  Future<TreatmentSummary> addTreatment({
    required String farmId,
    required String healthEventId,
    required String medication,
    String? dosage,
    String? route,
    String? frequency,
    String? notes,
    int withdrawalDays = 0,
  }) async {
    final startedOn = DateTime.now();
    final data = {
      'medication': medication,
      'dosage': dosage,
      'route': route,
      'frequency': frequency,
      'started_on': startedOn.toIso8601String(),
      'withdrawal_days': withdrawalDays,
      'notes': notes,
    };

    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/farms/$farmId/health-events/$healthEventId/treatments',
        data: data,
        options: _authOptions(),
      );

      return TreatmentSummary.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
    } on DioException catch (error) {
      if (!isApiConnectionProblem(error) || offlineQueue == null) {
        rethrow;
      }

      await offlineQueue!.enqueue(
        method: 'POST',
        path: '/farms/$farmId/health-events/$healthEventId/treatments',
        data: data,
        headers: _authHeaders(),
      );

      return TreatmentSummary(
        id: 'local-${DateTime.now().microsecondsSinceEpoch}',
        healthEventId: healthEventId,
        rabbitId: 'pending-rabbit',
        medication: medication,
        dosage: dosage,
        route: route,
        frequency: frequency,
        startedOn: startedOn.toIso8601String().split('T').first,
        withdrawalDays: withdrawalDays,
        withdrawalEndsOn: withdrawalDays > 0
            ? startedOn
                  .add(Duration(days: withdrawalDays))
                  .toIso8601String()
                  .split('T')
                  .first
            : null,
        status: 'active',
      );
    }
  }

  Future<HealthEventSummary> updateStatus({
    required String farmId,
    required String healthEventId,
    required String action,
  }) async {
    final data = {'action': action};

    try {
      final response = await dio.patch<Map<String, dynamic>>(
        '/farms/$farmId/health-events/$healthEventId',
        data: data,
        options: _authOptions(),
      );

      return HealthEventSummary.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
    } on DioException catch (error) {
      if (!isApiConnectionProblem(error) || offlineQueue == null) {
        rethrow;
      }

      await offlineQueue!.enqueue(
        method: 'PATCH',
        path: '/farms/$farmId/health-events/$healthEventId',
        data: data,
        headers: _authHeaders(),
      );

      return HealthEventSummary(
        id: healthEventId,
        rabbitIdentifier: 'Pending rabbit',
        observedOn: DateTime.now().toIso8601String().split('T').first,
        symptoms: 'Pending health update',
        severity: 'mild',
        status: action == 'monitor'
            ? 'monitoring'
            : action == 'resolve'
            ? 'resolved'
            : 'closed',
        isolationRequired: false,
        treatmentsCount: 0,
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
