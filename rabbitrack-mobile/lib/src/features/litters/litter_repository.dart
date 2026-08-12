import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import '../auth/auth_repository.dart';
import 'litter_models.dart';

final litterRepositoryProvider = Provider<LitterRepository>((ref) {
  final session = ref.watch(authControllerProvider).valueOrNull;

  return LitterRepository(dio: ref.watch(dioProvider), token: session?.token);
});

class LitterRepository {
  const LitterRepository({required this.dio, required this.token});

  final Dio dio;
  final String? token;

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
    String? nestCondition,
    String? doeCondition,
    String? notes,
  }) async {
    final response = await dio.post<Map<String, dynamic>>(
      '/farms/$farmId/kindlings',
      data: {
        'mating_id': ?matingId,
        'doe_id': ?doeId,
        'kindled_on': DateTime.now().toIso8601String(),
        'kits_born_alive': kitsBornAlive,
        'kits_stillborn': kitsStillborn,
        'kits_weak': kitsWeak,
        'nest_condition': ?nestCondition,
        'doe_condition': ?doeCondition,
        'notes': ?notes,
      },
      options: _authOptions(),
    );

    return LitterSummary.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
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
    await dio.post<Map<String, dynamic>>(
      '/farms/$farmId/litters/$litterId/weanings',
      data: {
        'weaned_on': DateTime.now().toIso8601String(),
        'number_weaned': numberWeaned,
        'average_weight_value': averageWeightValue,
        'weight_unit': 'kg',
        'destination': destination,
        'notes': ?notes,
      },
      options: _authOptions(),
    );
  }

  Options _authOptions() {
    return Options(headers: {'Authorization': 'Bearer $token'});
  }
}
