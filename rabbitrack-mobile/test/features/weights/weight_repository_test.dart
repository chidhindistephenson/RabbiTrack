import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/weights/weight_repository.dart';
import 'package:rabbitrack_mobile/src/shared/offline_action_queue.dart';

void main() {
  test('recordRabbitWeight sends weight fields', () async {
    final adapter = _CapturingAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
      ..httpClientAdapter = adapter;
    final repository = WeightRepository(dio: dio, token: 'token');

    final weight = await repository.recordRabbitWeight(
      farmId: 'farm-1',
      rabbitId: 'rabbit-1',
      weightValue: 3.42,
      method: 'scale',
      notes: 'Healthy gain',
    );

    expect(adapter.method, 'POST');
    expect(adapter.path, '/api/v1/farms/farm-1/weights');
    expect(adapter.requestData, containsPair('rabbit_id', 'rabbit-1'));
    expect(adapter.requestData, containsPair('weight_value', 3.42));
    expect(adapter.requestData, containsPair('weight_unit', 'kg'));
    expect(adapter.requestData, containsPair('method', 'scale'));
    expect(weight.weightValue, '3.420');
  });

  test('recordRabbitWeight queues when offline', () async {
    final temp = await Directory.systemTemp.createTemp('rabbitrack-queue-test');
    addTearDown(() => temp.delete(recursive: true));
    final queue = OfflineActionQueue(directoryProvider: () async => temp);
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
      ..httpClientAdapter = _OfflineAdapter();
    final repository = WeightRepository(
      dio: dio,
      token: 'token',
      offlineQueue: queue,
    );

    final weight = await repository.recordRabbitWeight(
      farmId: 'farm-1',
      rabbitId: 'rabbit-1',
      weightValue: 2.75,
      notes: 'Offline weighing',
    );

    expect(weight.id, startsWith('local-'));
    expect(weight.weightValue, '2.750');
    expect(weight.weightUnit, 'kg');
    expect(await queue.pendingCount(), 1);
  });
}

class _CapturingAdapter implements HttpClientAdapter {
  late String path;
  late String method;
  Map<String, dynamic> requestData = {};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    path = options.uri.path;
    method = options.method;
    if (options.data is Map) {
      requestData = Map<String, dynamic>.from(options.data as Map);
    }

    return ResponseBody.fromString(
      jsonEncode({
        'data': {
          'id': 'weight-1',
          'rabbit_identifier': 'DOE-0001',
          'weighed_on': '2026-08-17',
          'weight_value': '3.420',
          'weight_unit': 'kg',
          'method': requestData['method'],
          'notes': requestData['notes'],
        },
      }),
      201,
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
