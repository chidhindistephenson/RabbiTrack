import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import '../auth/auth_models.dart';
import '../auth/auth_repository.dart';

final farmRepositoryProvider = Provider<FarmRepository>((ref) {
  final session = ref.watch(authControllerProvider).valueOrNull;

  return FarmRepository(dio: ref.watch(dioProvider), token: session?.token);
});

class FarmRepository {
  const FarmRepository({required this.dio, required this.token});

  final Dio dio;
  final String? token;

  Future<FarmSummary> create({
    required String name,
    required String currency,
  }) async {
    final response = await dio.post<Map<String, dynamic>>(
      '/farms',
      data: {'name': name, 'currency': currency},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return FarmSummary.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  Future<FarmSummary> update({
    required String farmId,
    required String name,
    required String currency,
    required String timezone,
  }) async {
    final response = await dio.patch<Map<String, dynamic>>(
      '/farms/$farmId',
      data: {'name': name, 'currency': currency, 'timezone': timezone},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return FarmSummary.fromJson(response.data!['data'] as Map<String, dynamic>);
  }
}
