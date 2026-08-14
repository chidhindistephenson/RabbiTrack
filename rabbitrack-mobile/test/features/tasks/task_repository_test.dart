import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/tasks/task_repository.dart';

void main() {
  test('TaskRepository.list sends open status and due filter', () async {
    final adapter = _CapturingAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
      ..httpClientAdapter = adapter;
    final repository = TaskRepository(dio: dio, token: 'token');

    final tasks = await repository.list('farm-1', due: 'overdue');

    expect(adapter.method, 'GET');
    expect(adapter.path, '/api/v1/farms/farm-1/tasks');
    expect(adapter.queryParameters, containsPair('status', 'open'));
    expect(adapter.queryParameters, containsPair('due', 'overdue'));
    expect(tasks.single.title, 'Prepare nest box');
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
            'id': 'task-1',
            'type': 'nest_box_preparation',
            'title': 'Prepare nest box',
            'description': null,
            'due_on': '2026-08-03',
            'due_time': '14:30',
            'priority': 'critical',
            'status': 'open',
            'rabbit_identifier': 'DOE-0001',
            'location_name': 'Cage A',
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
