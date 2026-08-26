import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/offline_demo_data.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_repository.dart';
import 'population_report_models.dart';

final populationReportRepositoryProvider = Provider<PopulationReportRepository>(
  (ref) {
    final session = ref.watch(authControllerProvider).valueOrNull;

    return PopulationReportRepository(
      dio: ref.watch(dioProvider),
      token: session?.token,
    );
  },
);

class PopulationReportRepository {
  const PopulationReportRepository({required this.dio, required this.token});

  final Dio dio;
  final String? token;

  Future<PopulationReport> show(String farmId) async {
    final response = await dio.get<Map<String, dynamic>>(
      '/farms/$farmId/reports/population',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return PopulationReport.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }

  Future<String> exportCsv(String farmId) async {
    if (_isOfflineDemo) {
      final report = isOfflineDemoFarm(farmId)
          ? offlineDemoPopulationReport
          : const PopulationReport(
              total: 0,
              bySex: [],
              byStatus: [],
              byBreed: [],
              byLocation: [],
            );
      return _populationCsv(report);
    }

    final response = await dio.get<String>(
      '/farms/$farmId/reports/population',
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

String _populationCsv(PopulationReport report) {
  return [
    'section,label,count',
    'total,all,${report.total}',
    for (final row in report.bySex) 'sex,${_csvValue(row.label)},${row.count}',
    for (final row in report.byStatus)
      'status,${_csvValue(row.label)},${row.count}',
    for (final row in report.byBreed)
      'breed,${_csvValue(row.label)},${row.count}',
    for (final row in report.byLocation)
      'location,${_csvValue(row.label)},${row.count}',
  ].join('\n');
}

String _csvValue(Object? value) {
  final text = (value ?? '').toString();
  if (!text.contains(',') && !text.contains('"') && !text.contains('\n')) {
    return text;
  }

  return '"${text.replaceAll('"', '""')}"';
}
