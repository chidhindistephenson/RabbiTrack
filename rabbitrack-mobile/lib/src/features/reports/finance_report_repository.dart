import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/offline_demo_data.dart';
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
    if (_isOfflineDemo) {
      final report = isOfflineDemoFarm(farmId)
          ? offlineDemoFinanceReport(DateTime.now())
          : const MonthlyFinanceReport(currency: 'USD', months: []);
      return _financeCsv(report);
    }

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

  bool get _isOfflineDemo => token?.startsWith('offline-demo-') == true;
}

String _financeCsv(MonthlyFinanceReport report) {
  final rows = [
    'month,label,revenue,expenses,net_income,currency',
    for (final row in report.months)
      [
        row.month,
        row.label,
        row.revenue,
        row.expenses,
        row.netIncome,
        report.currency,
      ].map(_csvValue).join(','),
  ];

  return rows.join('\n');
}

String _csvValue(Object? value) {
  final text = (value ?? '').toString();
  if (!text.contains(',') && !text.contains('"') && !text.contains('\n')) {
    return text;
  }

  return '"${text.replaceAll('"', '""')}"';
}
