import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import '../auth/auth_repository.dart';
import 'health_report_models.dart';

final healthReportRepositoryProvider = Provider<HealthReportRepository>((ref) {
  final session = ref.watch(authControllerProvider).valueOrNull;

  return HealthReportRepository(
    dio: ref.watch(dioProvider),
    token: session?.token,
  );
});

class HealthReportRepository {
  const HealthReportRepository({required this.dio, required this.token});

  final Dio dio;
  final String? token;

  Future<HealthReport> show(String farmId) async {
    final response = await dio.get<Map<String, dynamic>>(
      '/farms/$farmId/reports/health',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return HealthReport.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }

  Future<String> exportCsv(String farmId) async {
    final response = await dio.get<String>(
      '/farms/$farmId/reports/health',
      queryParameters: {'format': 'csv'},
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
        responseType: ResponseType.plain,
      ),
    );

    return response.data ?? '';
  }
}
