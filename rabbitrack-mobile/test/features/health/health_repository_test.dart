import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/health/health_repository.dart';
import 'package:rabbitrack_mobile/src/shared/offline_action_queue.dart';

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

  test('create queues health event when offline', () async {
    final temp = await Directory.systemTemp.createTemp('rabbitrack-queue-test');
    addTearDown(() => temp.delete(recursive: true));
    final queue = OfflineActionQueue(directoryProvider: () async => temp);
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
      ..httpClientAdapter = _OfflineAdapter();
    final repository = HealthRepository(
      dio: dio,
      token: 'token',
      offlineQueue: queue,
    );

    final event = await repository.create(
      farmId: 'farm-1',
      rabbitId: 'rabbit-1',
      symptoms: 'Reduced appetite',
      severity: 'moderate',
      isolationRequired: true,
    );

    expect(event.id, startsWith('local-'));
    expect(event.symptoms, 'Reduced appetite');
    expect(event.isolationRequired, isTrue);
    expect(await queue.pendingCount(), 1);
  });

  test('addTreatment queues treatment when offline', () async {
    final temp = await Directory.systemTemp.createTemp('rabbitrack-queue-test');
    addTearDown(() => temp.delete(recursive: true));
    final queue = OfflineActionQueue(directoryProvider: () async => temp);
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
      ..httpClientAdapter = _OfflineAdapter();
    final repository = HealthRepository(
      dio: dio,
      token: 'token',
      offlineQueue: queue,
    );

    final treatment = await repository.addTreatment(
      farmId: 'farm-1',
      healthEventId: 'health-1',
      medication: 'Ivermectin',
      dosage: '1 ml',
      withdrawalDays: 14,
    );

    expect(treatment.id, startsWith('local-'));
    expect(treatment.medication, 'Ivermectin');
    expect(treatment.withdrawalDays, 14);
    expect(treatment.withdrawalEndsOn, isNotNull);
    expect(await queue.pendingCount(), 1);
  });

  test('updateStatus queues action when offline', () async {
    final temp = await Directory.systemTemp.createTemp('rabbitrack-queue-test');
    addTearDown(() => temp.delete(recursive: true));
    final queue = OfflineActionQueue(directoryProvider: () async => temp);
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
      ..httpClientAdapter = _OfflineAdapter();
    final repository = HealthRepository(
      dio: dio,
      token: 'token',
      offlineQueue: queue,
    );

    final event = await repository.updateStatus(
      farmId: 'farm-1',
      healthEventId: 'health-1',
      action: 'resolve',
    );

    expect(event.id, 'health-1');
    expect(event.status, 'resolved');
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
