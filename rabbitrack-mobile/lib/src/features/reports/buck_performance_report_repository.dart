import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/offline_demo_data.dart';
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
    if (_isOfflineDemo) {
      final rows = isOfflineDemoFarm(farmId)
          ? offlineDemoRabbits(sex: 'male').map((rabbit) {
              final isDemoSire = rabbit.id == 'offline-buck-0003';
              return BuckPerformanceRow(
                id: rabbit.id,
                identifier: rabbit.identifier,
                name: rabbit.name,
                breed: rabbit.breed,
                status: rabbit.status,
                matings: isDemoSire ? 1 : 0,
                confirmedPregnancies: isDemoSire ? 1 : 0,
                conceptionRate: isDemoSire ? 100 : 0,
                litters: isDemoSire ? 1 : 0,
                kitsBornAlive: isDemoSire ? 9 : 0,
                kitsWeaned: 0,
                averageLitterSize: isDemoSire ? 9 : 0,
                weaningRate: 0,
              );
            }).toList()
          : const <BuckPerformanceRow>[];
      return _buckCsv(rows);
    }

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

  bool get _isOfflineDemo => token?.startsWith('offline-demo-') == true;
}

String _buckCsv(List<BuckPerformanceRow> rows) {
  return [
    'identifier,name,breed,status,matings,confirmed_pregnancies,conception_rate,litters,kits_born_alive,kits_weaned,average_litter_size,weaning_rate',
    for (final row in rows)
      [
        row.identifier,
        row.name,
        row.breed,
        row.status,
        row.matings,
        row.confirmedPregnancies,
        row.conceptionRate,
        row.litters,
        row.kitsBornAlive,
        row.kitsWeaned,
        row.averageLitterSize,
        row.weaningRate,
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
