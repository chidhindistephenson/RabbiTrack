import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/offline_demo_data.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_repository.dart';
import 'doe_performance_report_models.dart';

final doePerformanceReportRepositoryProvider =
    Provider<DoePerformanceReportRepository>((ref) {
      final session = ref.watch(authControllerProvider).valueOrNull;

      return DoePerformanceReportRepository(
        dio: ref.watch(dioProvider),
        token: session?.token,
      );
    });

class DoePerformanceReportRepository {
  const DoePerformanceReportRepository({
    required this.dio,
    required this.token,
  });

  final Dio dio;
  final String? token;

  Future<DoePerformanceReport> show(
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
      '/farms/$farmId/reports/does/performance',
      queryParameters: queryParameters,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return DoePerformanceReport.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }

  Future<String> exportCsv(String farmId, {String? start, String? end}) async {
    if (_isOfflineDemo) {
      final rows = isOfflineDemoFarm(farmId)
          ? offlineDemoRabbits(sex: 'female').map((rabbit) {
              final isNursing = rabbit.status == 'nursing';
              final isPregnant = rabbit.status == 'pregnant' || isNursing;
              return DoePerformanceRow(
                id: rabbit.id,
                identifier: rabbit.identifier,
                name: rabbit.name,
                breed: rabbit.breed,
                status: rabbit.status,
                matings: rabbit.id == 'offline-doe-0047' ? 1 : 0,
                confirmedPregnancies: isPregnant ? 1 : 0,
                kindlings: isNursing ? 1 : 0,
                completedLitters: 0,
                kitsBornAlive: isNursing ? 9 : 0,
                kitsWeaned: 0,
                averageLitterSize: isNursing ? 9 : 0,
                survivalRate: isNursing ? 100 : 0,
              );
            }).toList()
          : const <DoePerformanceRow>[];
      return _doeCsv(rows);
    }

    final queryParameters = <String, dynamic>{'format': 'csv'};
    if (start != null) {
      queryParameters['start'] = start;
    }
    if (end != null) {
      queryParameters['end'] = end;
    }

    final response = await dio.get<String>(
      '/farms/$farmId/reports/does/performance',
      queryParameters: queryParameters,
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
        responseType: ResponseType.plain,
      ),
    );

    return response.data ?? '';
  }

  bool get _isOfflineDemo => token?.startsWith('offline-demo-') == true;
}

String _doeCsv(List<DoePerformanceRow> rows) {
  return [
    'identifier,name,breed,status,matings,confirmed_pregnancies,kindlings,completed_litters,kits_born_alive,kits_weaned,average_litter_size,survival_rate',
    for (final row in rows)
      [
        row.identifier,
        row.name,
        row.breed,
        row.status,
        row.matings,
        row.confirmedPregnancies,
        row.kindlings,
        row.completedLitters,
        row.kitsBornAlive,
        row.kitsWeaned,
        row.averageLitterSize,
        row.survivalRate,
      ].map(_csvValue).join(','),
  ].join('\n');
}

String _csvValue(Object? value) {
  final text = (value ?? '').toString();
  if (!text.contains(',') && !text.contains('"') && !text.contains('\n')) {
    return text;
  }

  return '"${text.replaceAll('"', '""')}"';
}
