import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/tasks/task_repository.dart';
import 'package:rabbitrack_mobile/src/shared/offline_action_queue.dart';

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

  test('TaskRepository queues complete action when offline', () async {
    final temp = await Directory.systemTemp.createTemp('rabbitrack-queue-test');
    addTearDown(() => temp.delete(recursive: true));
    final queue = OfflineActionQueue(directoryProvider: () async => temp);
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
      ..httpClientAdapter = _OfflineAdapter();
    final repository = TaskRepository(
      dio: dio,
      token: 'token',
      offlineQueue: queue,
    );

    await repository.complete(farmId: 'farm-1', taskId: 'task-1');

    expect(await queue.pendingCount(), 1);
  });

  test('TaskRepository queues create action when offline', () async {
    final temp = await Directory.systemTemp.createTemp('rabbitrack-queue-test');
    addTearDown(() => temp.delete(recursive: true));
    final queue = OfflineActionQueue(directoryProvider: () async => temp);
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
      ..httpClientAdapter = _OfflineAdapter();
    final repository = TaskRepository(
      dio: dio,
      token: 'token',
      offlineQueue: queue,
    );

    final task = await repository.create(
      farmId: 'farm-1',
      title: 'Check feeders',
      dueOn: '2026-08-17',
      dueTime: '08:30',
      priority: 'normal',
      description: 'Morning round',
    );

    expect(task.id, startsWith('local-'));
    expect(task.title, 'Check feeders');
    expect(await queue.pendingCount(), 1);
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

class _OfflineAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw DioException(
      requestOptions: options,
      type: DioExceptionType.connectionError,
      error: const SocketException('offline'),
    );
  }

  @override
  void close({bool force = false}) {}
}
