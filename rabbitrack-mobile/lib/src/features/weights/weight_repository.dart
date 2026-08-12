import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import '../auth/auth_repository.dart';
import 'weight_models.dart';

final weightRepositoryProvider = Provider<WeightRepository>((ref) {
  final session = ref.watch(authControllerProvider).valueOrNull;

  return WeightRepository(dio: ref.watch(dioProvider), token: session?.token);
});

class WeightRepository {
  const WeightRepository({required this.dio, required this.token});

  final Dio dio;
  final String? token;

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
    final response = await dio.post<Map<String, dynamic>>(
      '/farms/$farmId/weights',
      data: {
        'rabbit_id': rabbitId,
        'weighed_on': DateTime.now().toIso8601String(),
        'weight_value': weightValue,
        'weight_unit': 'kg',
        'method': method ?? 'field entry',
        'notes': ?notes,
      },
      options: _authOptions(),
    );

    return WeightSummary.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }

  Future<WeightSummary> recordLitterWeight({
    required String farmId,
    required String litterId,
    required double weightValue,
    String? method,
    String? notes,
  }) async {
    final response = await dio.post<Map<String, dynamic>>(
      '/farms/$farmId/weights',
      data: {
        'litter_id': litterId,
        'weighed_on': DateTime.now().toIso8601String(),
        'weight_value': weightValue,
        'weight_unit': 'kg',
        'method': method ?? 'field entry',
        'notes': ?notes,
      },
      options: _authOptions(),
    );

    return WeightSummary.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }

  Options _authOptions() {
    return Options(headers: {'Authorization': 'Bearer $token'});
  }
}
