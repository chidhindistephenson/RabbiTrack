import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import '../auth/auth_repository.dart';
import 'finance_report_models.dart';

final financeReportRepositoryProvider = Provider<FinanceReportRepository>((
  ref,
) {
  final session = ref.watch(authControllerProvider).valueOrNull;

  return FinanceReportRepository(
    dio: ref.watch(dioProvider),
    token: session?.token,
  );
});

class FinanceReportRepository {
  const FinanceReportRepository({required this.dio, required this.token});

  final Dio dio;
  final String? token;

  Future<MonthlyFinanceReport> monthly(String farmId) async {
    final response = await dio.get<Map<String, dynamic>>(
      '/farms/$farmId/reports/finance/monthly',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return MonthlyFinanceReport.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }

  Future<String> exportCsv(String farmId) async {
    final response = await dio.get<String>(
      '/farms/$farmId/reports/finance/monthly',
      queryParameters: {'format': 'csv'},
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
        responseType: ResponseType.plain,
      ),
    );

    return response.data ?? '';
  }
}
