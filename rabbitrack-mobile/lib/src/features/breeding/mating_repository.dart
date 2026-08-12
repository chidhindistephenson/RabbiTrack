import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import '../auth/auth_repository.dart';
import 'mating_models.dart';

final matingRepositoryProvider = Provider<MatingRepository>((ref) {
  final session = ref.watch(authControllerProvider).valueOrNull;

  return MatingRepository(dio: ref.watch(dioProvider), token: session?.token);
});

class MatingRepository {
  const MatingRepository({required this.dio, required this.token});

  final Dio dio;
  final String? token;

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
  }) async {
    final response = await dio.post<Map<String, dynamic>>(
      '/farms/$farmId/matings',
      data: {
        'doe_id': doeId,
        'buck_id': buckId,
        'mated_at': matedAt,
        'outcome': outcome,
        'behavior_observed': ?behaviorObserved,
        'notes': ?notes,
      },
      options: _authOptions(),
    );

    return MatingSummary.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
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
    await dio.post<Map<String, dynamic>>(
      '/farms/$farmId/matings/$matingId/pregnancy-checks',
      data: {
        'checked_on': DateTime.now().toIso8601String(),
        'result': result,
        'notes': ?notes,
      },
      options: _authOptions(),
    );
  }

  Future<void> revisePregnancyDecision({
    required String farmId,
    required String matingId,
    required String result,
    String? notes,
  }) async {
    await dio.patch<Map<String, dynamic>>(
      '/farms/$farmId/matings/$matingId/pregnancy-checks/latest',
      data: {
        'checked_on': DateTime.now().toIso8601String(),
        'result': result,
        'notes': ?notes,
      },
      options: _authOptions(),
    );
  }

  Future<void> delete({
    required String farmId,
    required String matingId,
  }) async {
    await dio.delete<Map<String, dynamic>>(
      '/farms/$farmId/matings/$matingId',
      options: _authOptions(),
    );
  }

  Options _authOptions() {
    return Options(headers: {'Authorization': 'Bearer $token'});
  }
}
