import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/offline_demo_data.dart';
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
    if (_isOfflineDemo) {
      final report = isOfflineDemoFarm(farmId)
          ? offlineDemoHealthReport
          : const HealthReport(
              activeHealthEvents: 0,
              activeTreatments: 0,
              withdrawalRestrictions: 0,
              mortalityCount: 0,
              eventsBySeverity: [],
              eventsByBodySystem: [],
              eventsByDiagnosis: [],
              medicineUse: [],
              withdrawals: [],
            );
      return _healthCsv(report);
    }

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

  bool get _isOfflineDemo => token?.startsWith('offline-demo-') == true;
}

String _healthCsv(HealthReport report) {
  return [
    'metric,value',
    'active_health_events,${report.activeHealthEvents}',
    'active_treatments,${report.activeTreatments}',
    'withdrawal_restrictions,${report.withdrawalRestrictions}',
    'mortality_count,${report.mortalityCount}',
    for (final row in report.eventsBySeverity)
      'severity:${_csvValue(row.label)},${row.count}',
    for (final row in report.eventsByBodySystem)
      'body_system:${_csvValue(row.label)},${row.count}',
    for (final row in report.eventsByDiagnosis)
      'diagnosis:${_csvValue(row.label)},${row.count}',
    for (final row in report.medicineUse)
      'medicine:${_csvValue(row.label)},${row.count}',
  ].join('\n');
}

String _csvValue(Object? value) {
  final text = (value ?? '').toString();
  if (!text.contains(',') && !text.contains('"') && !text.contains('\n')) {
    return text;
  }

  return '"${text.replaceAll('"', '""')}"';
}
