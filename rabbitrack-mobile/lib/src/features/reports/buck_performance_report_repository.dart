import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import '../auth/auth_repository.dart';
import 'buck_performance_report_models.dart';

final buckPerformanceReportRepositoryProvider =
    Provider<BuckPerformanceReportRepository>((ref) {
      final session = ref.watch(authControllerProvider).valueOrNull;

      return BuckPerformanceReportRepository(
        dio: ref.watch(dioProvider),
        token: session?.token,
      );
    });

class BuckPerformanceReportRepository {
  const BuckPerformanceReportRepository({
    required this.dio,
    required this.token,
  });

  final Dio dio;
  final String? token;

  Future<BuckPerformanceReport> show(
    String farmId, {
    String? start,
    String? end,
  }) async {
    final queryParameters = <String, dynamic>{};
    if (start != null) {
      queryParameters['start'] = start;
    }
    if (end != null) {
      queryParameters['end'] = end;
    }

    final response = await dio.get<Map<String, dynamic>>(
      '/farms/$farmId/reports/bucks/performance',
      queryParameters: queryParameters,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return BuckPerformanceReport.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }

  Future<String> exportCsv(String farmId, {String? start, String? end}) async {
    final queryParameters = <String, dynamic>{'format': 'csv'};
    if (start != null) {
      queryParameters['start'] = start;
    }
    if (end != null) {
      queryParameters['end'] = end;
    }

    final response = await dio.get<String>(
      '/farms/$farmId/reports/bucks/performance',
      queryParameters: queryParameters,
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
        responseType: ResponseType.plain,
      ),
    );

    return response.data ?? '';
  }
}
