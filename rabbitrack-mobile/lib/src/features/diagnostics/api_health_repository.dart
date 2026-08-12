import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_repository.dart';
import 'api_health_models.dart';

final apiHealthRepositoryProvider = Provider<ApiHealthRepository>((ref) {
  return ApiHealthRepository(dio: ref.watch(dioProvider));
});

class ApiHealthRepository {
  const ApiHealthRepository({required this.dio});

  final Dio dio;

  Future<ApiHealthStatus> check() async {
    final response = await dio.get<Map<String, dynamic>>('/health');

    return ApiHealthStatus.fromJson(response.data!);
  }
}
