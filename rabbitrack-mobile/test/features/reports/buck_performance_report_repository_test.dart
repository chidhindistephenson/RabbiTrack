import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/reports/buck_performance_report_repository.dart';

void main() {
  test('BuckPerformanceReportRepository parses report rows', () async {
    final adapter = _BuckReportAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
      ..httpClientAdapter = adapter;
    final repository = BuckPerformanceReportRepository(
      dio: dio,
      token: 'token',
    );

    final report = await repository.show(
      'farm-1',
      start: '2026-08-01',
      end: '2026-08-31',
    );

    expect(adapter.path, '/farms/farm-1/reports/bucks/performance');
    expect(adapter.queryParameters, {
      'start': '2026-08-01',
      'end': '2026-08-31',
    });
    expect(report.buckCount, 1);
    expect(report.conceptionRate, 50);
    expect(report.bucks.first.identifier, 'BUCK-PERF');
    expect(report.bucks.first.weaningRate, 88.9);
  });

  test(
    'BuckPerformanceReportRepository exports CSV with period filters',
    () async {
      final adapter = _BuckReportAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
        ..httpClientAdapter = adapter;
      final repository = BuckPerformanceReportRepository(
        dio: dio,
        token: 'token',
      );

      final csv = await repository.exportCsv(
        'farm-1',
        start: '2026-08-01',
        end: '2026-08-31',
      );

      expect(adapter.path, '/farms/farm-1/reports/bucks/performance');
      expect(adapter.queryParameters, {
        'format': 'csv',
        'start': '2026-08-01',
        'end': '2026-08-31',
      });
      expect(csv, contains('identifier,name,breed,status,matings'));
    },
  );
}

class _BuckReportAdapter implements HttpClientAdapter {
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
        'identifier,name,breed,status,matings\nBUCK-PERF,Atlas,Rex,available_for_breeding,2\n',
        200,
        headers: {
          Headers.contentTypeHeader: ['text/csv'],
        },
      );
    }

    return ResponseBody.fromString(
      jsonEncode({
        'data': {
          'buck_count': 1,
          'total_matings': 2,
          'confirmed_pregnancies': 1,
          'conception_rate': 50,
          'litters': 1,
          'kits_born_alive': 9,
          'kits_weaned': 8,
          'average_litter_size': 9,
          'weaning_rate': 88.9,
          'bucks': [
            {
              'id': 'buck-1',
              'identifier': 'BUCK-PERF',
              'name': 'Atlas',
              'breed': 'New Zealand White',
              'status': 'available_for_breeding',
              'matings': 2,
              'confirmed_pregnancies': 1,
              'conception_rate': 50,
              'litters': 1,
              'kits_born_alive': 9,
              'kits_weaned': 8,
              'average_litter_size': 9,
              'weaning_rate': 88.9,
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
