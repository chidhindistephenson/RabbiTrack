import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
}
