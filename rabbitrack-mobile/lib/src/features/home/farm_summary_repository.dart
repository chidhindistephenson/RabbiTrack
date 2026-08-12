import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import '../auth/auth_repository.dart';
import 'farm_summary_models.dart';

final farmSummaryRepositoryProvider = Provider<FarmSummaryRepository>((ref) {
  final session = ref.watch(authControllerProvider).valueOrNull;

  return FarmSummaryRepository(
    dio: ref.watch(dioProvider),
    token: session?.token,
  );
});

class FarmSummaryRepository {
  const FarmSummaryRepository({required this.dio, required this.token});

  final Dio dio;
  final String? token;

  Future<FarmSummaryCounts> summary(String farmId) async {
    final response = await dio.get<Map<String, dynamic>>(
      '/farms/$farmId/summary',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return FarmSummaryCounts.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }
}
