import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import '../auth/auth_repository.dart';
import 'litter_performance_report_models.dart';

final litterPerformanceReportRepositoryProvider =
    Provider<LitterPerformanceReportRepository>((ref) {
      final session = ref.watch(authControllerProvider).valueOrNull;

      return LitterPerformanceReportRepository(
        dio: ref.watch(dioProvider),
        token: session?.token,
      );
    });

class LitterPerformanceReportRepository {
  const LitterPerformanceReportRepository({
    required this.dio,
    required this.token,
  });

  final Dio dio;
  final String? token;

  Future<LitterPerformanceReport> show(String farmId) async {
    final response = await dio.get<Map<String, dynamic>>(
      '/farms/$farmId/reports/litters/performance',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return LitterPerformanceReport.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }

  Future<String> exportCsv(String farmId) async {
    final response = await dio.get<String>(
      '/farms/$farmId/reports/litters/performance',
      queryParameters: {'format': 'csv'},
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
        responseType: ResponseType.plain,
      ),
    );

    return response.data ?? '';
  }
}
