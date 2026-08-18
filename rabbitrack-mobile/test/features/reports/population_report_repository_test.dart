import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/reports/population_report_repository.dart';

void main() {
  test('PopulationReportRepository parses grouped counts', () async {
    final adapter = _PopulationAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
      ..httpClientAdapter = adapter;
    final repository = PopulationReportRepository(dio: dio, token: 'token');

    final report = await repository.show('farm-1');

    expect(adapter.path, '/farms/farm-1/reports/population');
    expect(report.total, 3);
    expect(report.bySex.first.label, 'female');
    expect(report.byBreed.first.count, 2);
  });

  test('PopulationReportRepository exports CSV', () async {
    final adapter = _PopulationAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
      ..httpClientAdapter = adapter;
    final repository = PopulationReportRepository(dio: dio, token: 'token');

    final csv = await repository.exportCsv('farm-1');

    expect(adapter.path, '/farms/farm-1/reports/population');
    expect(adapter.queryParameters, {'format': 'csv'});
    expect(csv, contains('farm,report,section,label,count'));
  });
}

class _PopulationAdapter implements HttpClientAdapter {
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
        'farm,report,section,label,count\nDemo,Population report,Total,Active rabbits,3\n',
        200,
        headers: {
          Headers.contentTypeHeader: ['text/csv'],
        },
      );
    }

    return ResponseBody.fromString(
      jsonEncode({
        'data': {
          'total': 3,
          'by_sex': [
            {'label': 'female', 'count': 2},
            {'label': 'male', 'count': 1},
          ],
          'by_status': [
            {'label': 'available_for_breeding', 'count': 2},
          ],
          'by_breed': [
            {'label': 'Rex', 'count': 2},
          ],
          'by_location': [
            {'label': 'Cage A', 'count': 2},
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
