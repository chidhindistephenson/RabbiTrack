import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import '../auth/auth_repository.dart';
import 'health_models.dart';

final healthRepositoryProvider = Provider<HealthRepository>((ref) {
  final session = ref.watch(authControllerProvider).valueOrNull;

  return HealthRepository(dio: ref.watch(dioProvider), token: session?.token);
});

class HealthRepository {
  const HealthRepository({required this.dio, required this.token});

  final Dio dio;
  final String? token;

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
    final response = await dio.post<Map<String, dynamic>>(
      '/farms/$farmId/health-events',
      data: {
        'rabbit_id': rabbitId,
        'observed_on': DateTime.now().toIso8601String(),
        'symptoms': symptoms,
        'diagnosis': diagnosis,
        'severity': severity,
        'body_system': bodySystem,
        'isolation_required': isolationRequired,
        'notes': notes,
      },
      options: _authOptions(),
    );

    return HealthEventSummary.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
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
    final response = await dio.post<Map<String, dynamic>>(
      '/farms/$farmId/health-events/$healthEventId/treatments',
      data: {
        'medication': medication,
        'dosage': dosage,
        'route': route,
        'frequency': frequency,
        'started_on': DateTime.now().toIso8601String(),
        'withdrawal_days': withdrawalDays,
        'notes': notes,
      },
      options: _authOptions(),
    );

    return TreatmentSummary.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }

  Future<HealthEventSummary> updateStatus({
    required String farmId,
    required String healthEventId,
    required String action,
  }) async {
    final response = await dio.patch<Map<String, dynamic>>(
      '/farms/$farmId/health-events/$healthEventId',
      data: {'action': action},
      options: _authOptions(),
    );

    return HealthEventSummary.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }

  Options _authOptions() {
    return Options(headers: {'Authorization': 'Bearer $token'});
  }
}
