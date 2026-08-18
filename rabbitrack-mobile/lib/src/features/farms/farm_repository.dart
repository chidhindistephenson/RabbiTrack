import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/api_error_messages.dart';
import '../../shared/offline_action_queue.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_models.dart';
import '../auth/auth_repository.dart';

final farmRepositoryProvider = Provider<FarmRepository>((ref) {
  final session = ref.watch(authControllerProvider).valueOrNull;

  return FarmRepository(
    dio: ref.watch(dioProvider),
    token: session?.token,
    offlineQueue: ref.watch(offlineActionQueueProvider),
  );
});

class FarmRepository {
  const FarmRepository({
    required this.dio,
    required this.token,
    this.offlineQueue,
  });

  final Dio dio;
  final String? token;
  final OfflineActionQueue? offlineQueue;

  Future<FarmSummary> create({
    required String name,
    required String currency,
  }) async {
    final data = {'name': name, 'currency': currency};

    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/farms',
        data: data,
        options: _authOptions(),
      );

      return FarmSummary.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
    } on DioException catch (error) {
      if (!isApiConnectionProblem(error) || offlineQueue == null) {
        rethrow;
      }

      await offlineQueue!.enqueue(
        method: 'POST',
        path: '/farms',
        data: data,
        headers: _authHeaders(),
      );

      return FarmSummary(
        id: 'local-${DateTime.now().microsecondsSinceEpoch}',
        name: name,
        code: 'PENDING',
        role: 'administrator',
        timezone: 'Africa/Johannesburg',
        currency: currency,
        saleReadyMinAgeDays: 70,
        saleReadyMinWeightKg: 2,
        retirementReviewLitterThreshold: 0,
        breedingMinDoeAgeDays: 0,
        breedingMinBuckAgeDays: 0,
      );
    }
  }

  Future<FarmSummary> update({
    required String farmId,
    required String name,
    required String currency,
    required String timezone,
    required int saleReadyMinAgeDays,
    double? saleReadyMinWeightKg,
    required int retirementReviewLitterThreshold,
    required int breedingMinDoeAgeDays,
    required int breedingMinBuckAgeDays,
  }) async {
    final data = {
      'name': name,
      'currency': currency,
      'timezone': timezone,
      'sale_ready_min_age_days': saleReadyMinAgeDays,
      'sale_ready_min_weight_kg': saleReadyMinWeightKg,
      'retirement_review_litter_threshold': retirementReviewLitterThreshold,
      'breeding_min_doe_age_days': breedingMinDoeAgeDays,
      'breeding_min_buck_age_days': breedingMinBuckAgeDays,
    };

    try {
      final response = await dio.patch<Map<String, dynamic>>(
        '/farms/$farmId',
        data: data,
        options: _authOptions(),
      );

      return FarmSummary.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
    } on DioException catch (error) {
      if (!isApiConnectionProblem(error) || offlineQueue == null) {
        rethrow;
      }

      await offlineQueue!.enqueue(
        method: 'PATCH',
        path: '/farms/$farmId',
        data: data,
        headers: _authHeaders(),
      );

      return FarmSummary(
        id: farmId,
        name: name,
        code: 'PENDING',
        role: 'administrator',
        timezone: timezone,
        currency: currency,
        saleReadyMinAgeDays: saleReadyMinAgeDays,
        saleReadyMinWeightKg: saleReadyMinWeightKg,
        retirementReviewLitterThreshold: retirementReviewLitterThreshold,
        breedingMinDoeAgeDays: breedingMinDoeAgeDays,
        breedingMinBuckAgeDays: breedingMinBuckAgeDays,
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
