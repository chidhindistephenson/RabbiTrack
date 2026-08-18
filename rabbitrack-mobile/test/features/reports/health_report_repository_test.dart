import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/reports/health_report_repository.dart';

void main() {
  test('HealthReportRepository parses health report counts', () async {
    final adapter = _HealthReportAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
      ..httpClientAdapter = adapter;
    final repository = HealthReportRepository(dio: dio, token: 'token');

    final report = await repository.show('farm-1');

    expect(adapter.path, '/farms/farm-1/reports/health');
    expect(report.activeHealthEvents, 1);
    expect(report.activeTreatments, 1);
    expect(report.withdrawalRestrictions, 1);
    expect(report.medicineUse.first.label, 'Oxytet');
    expect(report.withdrawals.first.rabbitIdentifier, 'DOE-HEALTH');
  });

  test('HealthReportRepository exports CSV', () async {
    final adapter = _HealthReportAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
      ..httpClientAdapter = adapter;
    final repository = HealthReportRepository(dio: dio, token: 'token');

    final csv = await repository.exportCsv('farm-1');

    expect(adapter.query['format'], 'csv');
    expect(csv, contains('summary,active_health_events,1'));
  });
}

class _HealthReportAdapter implements HttpClientAdapter {
  String? path;
  Map<String, dynamic> query = {};

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    path = options.path;
    query = options.queryParameters;

    if (query['format'] == 'csv') {
      return ResponseBody.fromString(
        'section,label,count,rabbit_identifier,medication,withdrawal_ends_on\nsummary,active_health_events,1,,,\n',
        200,
        headers: {
          Headers.contentTypeHeader: ['text/csv'],
        },
      );
    }

    return ResponseBody.fromString(
      jsonEncode({
        'data': {
          'active_health_events': 1,
          'active_treatments': 1,
          'withdrawal_restrictions': 1,
          'mortality_count': 2,
          'events_by_severity': [
            {'label': 'severe', 'count': 1},
          ],
          'events_by_body_system': [
            {'label': 'respiratory', 'count': 1},
          ],
          'events_by_diagnosis': [
            {'label': 'Snuffles', 'count': 1},
          ],
          'medicine_use': [
            {'label': 'Oxytet', 'count': 1},
          ],
          'withdrawals': [
            {
              'id': 'treatment-1',
              'rabbit_id': 'rabbit-1',
              'rabbit_identifier': 'DOE-HEALTH',
              'medication': 'Oxytet',
              'withdrawal_ends_on': '2026-08-22',
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
