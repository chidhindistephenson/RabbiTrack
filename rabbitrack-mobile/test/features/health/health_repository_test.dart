import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/health/health_repository.dart';

void main() {
  test('list sends rabbit filter when supplied', () async {
    final adapter = _CapturingAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
      ..httpClientAdapter = adapter;
    final repository = HealthRepository(dio: dio, token: 'token');

    final events = await repository.list('farm-1', rabbitId: 'rabbit-1');

    expect(adapter.method, 'GET');
    expect(adapter.path, '/api/v1/farms/farm-1/health-events');
    expect(adapter.queryParameters, containsPair('rabbit_id', 'rabbit-1'));
    expect(events.single.rabbitIdentifier, 'DOE-0001');
  });
}

class _CapturingAdapter implements HttpClientAdapter {
  late String path;
  late String method;
  Map<String, dynamic> queryParameters = {};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    path = options.uri.path;
    method = options.method;
    queryParameters = options.queryParameters;

    return ResponseBody.fromString(
      jsonEncode({
        'data': [
          {
            'id': 'health-1',
            'rabbit_identifier': 'DOE-0001',
            'observed_on': '2026-08-04',
            'symptoms': 'Reduced appetite',
            'diagnosis': null,
            'body_system': 'digestive',
            'severity': 'moderate',
            'status': 'open',
            'isolation_required': false,
            'treatments_count': 0,
            'notes': null,
          },
        ],
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
