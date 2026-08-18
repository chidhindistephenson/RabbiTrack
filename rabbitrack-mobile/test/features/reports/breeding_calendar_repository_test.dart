import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/reports/breeding_calendar_repository.dart';

void main() {
  test(
    'BreedingCalendarRepository sends date window and parses events',
    () async {
      final adapter = _CalendarAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
        ..httpClientAdapter = adapter;
      final repository = BreedingCalendarRepository(dio: dio, token: 'token');

      final events = await repository.list(
        farmId: 'farm-1',
        start: '2026-08-01',
        end: '2026-09-30',
      );

      expect(adapter.path, '/farms/farm-1/reports/breeding/calendar');
      expect(adapter.query['start'], '2026-08-01');
      expect(adapter.query['end'], '2026-09-30');
      expect(events, hasLength(1));
      expect(events.first.type, 'mating');
      expect(events.first.title, 'Mating: DOE-CAL x BUCK-CAL');
    },
  );

  test('BreedingCalendarRepository exports CSV', () async {
    final adapter = _CalendarAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
      ..httpClientAdapter = adapter;
    final repository = BreedingCalendarRepository(dio: dio, token: 'token');

    final csv = await repository.exportCsv(
      farmId: 'farm-1',
      start: '2026-08-01',
      end: '2026-09-30',
    );

    expect(adapter.query['start'], '2026-08-01');
    expect(adapter.query['end'], '2026-09-30');
    expect(adapter.query['format'], 'csv');
    expect(csv, contains('date,type,title,subtitle'));
  });
}

class _CalendarAdapter implements HttpClientAdapter {
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
        'date,type,title,subtitle,rabbit_identifier,related_type,related_id\n2026-08-01,mating,Mating: DOE-CAL x BUCK-CAL,observed,DOE-CAL,mating,mating-1\n',
        200,
        headers: {
          Headers.contentTypeHeader: ['text/csv'],
        },
      );
    }

    return ResponseBody.fromString(
      jsonEncode({
        'data': [
          {
            'date': '2026-08-01',
            'type': 'mating',
            'title': 'Mating: DOE-CAL x BUCK-CAL',
            'subtitle': 'observed',
            'related_type': 'mating',
            'related_id': 'mating-1',
            'rabbit_id': 'doe-1',
            'rabbit_identifier': 'DOE-CAL',
          },
        ],
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}
