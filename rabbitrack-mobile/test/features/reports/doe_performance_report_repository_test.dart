import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/reports/doe_performance_report_repository.dart';

void main() {
  test('DoePerformanceReportRepository parses report rows', () async {
    final adapter = _DoeReportAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
      ..httpClientAdapter = adapter;
    final repository = DoePerformanceReportRepository(dio: dio, token: 'token');

    final report = await repository.show(
      'farm-1',
      start: '2026-08-01',
      end: '2026-08-31',
    );

    expect(adapter.path, '/farms/farm-1/reports/does/performance');
    expect(adapter.queryParameters, {
      'start': '2026-08-01',
      'end': '2026-08-31',
    });
    expect(report.doeCount, 1);
    expect(report.survivalRate, 50);
    expect(report.does.first.identifier, 'DOE-PERF');
    expect(report.does.first.averageLitterIntervalDays, 31);
  });

  test(
    'DoePerformanceReportRepository exports CSV with period filters',
    () async {
      final adapter = _DoeReportAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
        ..httpClientAdapter = adapter;
      final repository = DoePerformanceReportRepository(
        dio: dio,
        token: 'token',
      );

      final csv = await repository.exportCsv(
        'farm-1',
        start: '2026-08-01',
        end: '2026-08-31',
      );

      expect(adapter.path, '/farms/farm-1/reports/does/performance');
      expect(adapter.queryParameters, {
        'format': 'csv',
        'start': '2026-08-01',
        'end': '2026-08-31',
      });
      expect(csv, contains('identifier,name,breed,status,matings'));
    },
  );
}

class _DoeReportAdapter implements HttpClientAdapter {
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
        'identifier,name,breed,status,matings\nDOE-PERF,Athena,Rex,nursing,2\n',
        200,
        headers: {
          Headers.contentTypeHeader: ['text/csv'],
        },
      );
    }

    return ResponseBody.fromString(
      jsonEncode({
        'data': {
          'doe_count': 1,
          'total_matings': 2,
          'confirmed_pregnancies': 2,
          'kindlings': 2,
          'completed_litters': 1,
          'kits_born_alive': 14,
          'kits_weaned': 7,
          'average_litter_size': 7,
          'survival_rate': 50,
          'does': [
            {
              'id': 'doe-1',
              'identifier': 'DOE-PERF',
              'name': 'Athena',
              'breed': 'New Zealand White',
              'status': 'nursing',
              'matings': 2,
              'confirmed_pregnancies': 2,
              'kindlings': 2,
              'completed_litters': 1,
              'kits_born_alive': 14,
              'kits_weaned': 7,
              'average_litter_size': 7,
              'survival_rate': 50,
              'average_litter_interval_days': 31,
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
