import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/offline_demo_data.dart';
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
    if (_isOfflineDemo) {
      final rows = isOfflineDemoFarm(farmId)
          ? offlineDemoLitters().map((litter) {
              final detail = offlineDemoLitterDetail(litter.id);
              final bornAlive =
                  detail?.kitsBornAlive ?? litter.currentLiveCount;
              final stillborn = detail?.kitsStillborn ?? 0;
              final mortality = (bornAlive - litter.currentLiveCount).clamp(
                0,
                bornAlive,
              );

              return LitterPerformanceRow(
                id: litter.id,
                identifier: litter.identifier,
                doeIdentifier: litter.doeIdentifier,
                buckIdentifier: litter.buckIdentifier,
                kindledOn: litter.kindledOn,
                bornAlive: bornAlive,
                stillborn: stillborn,
                mortality: mortality,
                currentLive: litter.currentLiveCount,
                weaned: litter.status == 'weaned' ? litter.currentLiveCount : 0,
                survivalRate: bornAlive == 0
                    ? 0
                    : (litter.currentLiveCount / bornAlive) * 100,
                birthAverageWeight: detail?.weights.isEmpty == false
                    ? detail!.weights.first.averageWeightValue
                    : null,
                weightUnit: 'kg',
                status: litter.status,
              );
            }).toList()
          : const <LitterPerformanceRow>[];
      return _litterCsv(rows);
    }

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

  bool get _isOfflineDemo => token?.startsWith('offline-demo-') == true;
}

String _litterCsv(List<LitterPerformanceRow> rows) {
  return [
    'identifier,doe,buck,kindled_on,born_alive,stillborn,mortality,current_live,weaned,survival_rate,birth_average_weight,weight_unit,status',
    for (final row in rows)
      [
        row.identifier,
        row.doeIdentifier,
        row.buckIdentifier,
        row.kindledOn,
        row.bornAlive,
        row.stillborn,
        row.mortality,
        row.currentLive,
        row.weaned,
        row.survivalRate,
        row.birthAverageWeight,
        row.weightUnit,
        row.status,
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
