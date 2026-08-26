import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/reports/finance_report_repository.dart';

void main() {
  test('FinanceReportRepository parses monthly finance report', () async {
    final adapter = _FinanceReportAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
      ..httpClientAdapter = adapter;
    final repository = FinanceReportRepository(dio: dio, token: 'token');

    final report = await repository.monthly('farm-1');

    expect(adapter.path, '/farms/farm-1/reports/finance/monthly');
    expect(report.currency, 'USD');
    expect(report.months.first.netIncome, '27.50');
  });

  test('FinanceReportRepository exports CSV', () async {
    final adapter = _FinanceReportAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
      ..httpClientAdapter = adapter;
    final repository = FinanceReportRepository(dio: dio, token: 'token');

    final csv = await repository.exportCsv('farm-1');

    expect(adapter.query['format'], 'csv');
    expect(csv, contains('month,label,currency,revenue,expenses,net_income'));
  });

  test(
    'FinanceReportRepository exports offline demo CSV without API',
    () async {
      final adapter = _FinanceReportAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
        ..httpClientAdapter = adapter;
      final repository = FinanceReportRepository(
        dio: dio,
        token: 'offline-demo-owner',
      );

      final csv = await repository.exportCsv('offline-demo-farm');

      expect(adapter.path, isNull);
      expect(csv, contains('month,label,revenue,expenses,net_income,currency'));
      expect(csv, contains('43.75'));
    },
  );
}

class _FinanceReportAdapter implements HttpClientAdapter {
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
        'month,label,currency,revenue,expenses,net_income\n2026-07,Jul 2026,USD,40.00,12.50,27.50\n',
        200,
        headers: {
          Headers.contentTypeHeader: ['text/csv'],
        },
      );
    }

    return ResponseBody.fromString(
      jsonEncode({
        'data': {
          'currency': 'USD',
          'months': [
            {
              'month': '2026-07',
              'label': 'Jul 2026',
              'revenue': '40.00',
              'expenses': '12.50',
              'net_income': '27.50',
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
