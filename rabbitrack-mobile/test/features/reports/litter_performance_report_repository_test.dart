import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/reports/litter_performance_report_repository.dart';

void main() {
  test('LitterPerformanceReportRepository parses report rows', () async {
    final adapter = _LitterReportAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
      ..httpClientAdapter = adapter;
    final repository = LitterPerformanceReportRepository(
      dio: dio,
      token: 'token',
    );

    final report = await repository.show('farm-1');

    expect(adapter.path, '/farms/farm-1/reports/litters/performance');
    expect(report.litterCount, 1);
    expect(report.survivalRate, 75);
    expect(report.litters.first.identifier, 'LIT-PERF');
    expect(report.litters.first.weaningAverageWeight, '0.850');
  });

  test('LitterPerformanceReportRepository exports CSV', () async {
    final adapter = _LitterReportAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
      ..httpClientAdapter = adapter;
    final repository = LitterPerformanceReportRepository(
      dio: dio,
      token: 'token',
    );

    final csv = await repository.exportCsv('farm-1');

    expect(adapter.path, '/farms/farm-1/reports/litters/performance');
    expect(adapter.queryParameters, {'format': 'csv'});
    expect(csv, contains('identifier,doe_identifier,buck_identifier'));
  });
}

class _LitterReportAdapter implements HttpClientAdapter {
  String? path;
  Map<String, dynamic>? queryParameters;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    path = options.path;
    queryParameters = options.queryParameters;

    if (options.queryParameters['format'] == 'csv') {
      return ResponseBody.fromString(
        'identifier,doe_identifier,buck_identifier\nLIT-PERF,DOE-1,BUCK-1\n',
        200,
        headers: {
          Headers.contentTypeHeader: ['text/csv'],
        },
      );
    }

    return ResponseBody.fromString(
      jsonEncode({
        'data': {
          'litter_count': 1,
          'born_alive': 8,
          'stillborn': 2,
          'mortality': 2,
          'current_live': 6,
          'weaned': 6,
          'survival_rate': 75,
          'litters': [
            {
              'id': 'litter-1',
              'identifier': 'LIT-PERF',
              'kindled_on': '2026-08-10',
              'born_alive': 8,
              'stillborn': 2,
              'mortality': 2,
              'current_live': 6,
              'weaned': 6,
              'survival_rate': 75,
              'birth_average_weight': '0.080',
              'weaning_average_weight': '0.850',
              'weight_unit': 'kg',
              'status': 'weaned',
            },
          ],
        },
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}
