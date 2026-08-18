import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/breeding/mating_repository.dart';
import 'package:rabbitrack_mobile/src/shared/offline_action_queue.dart';

void main() {
  test('list sends rabbit filter when supplied', () async {
    final adapter = _CapturingAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
      ..httpClientAdapter = adapter;
    final repository = MatingRepository(dio: dio, token: 'token');

    final matings = await repository.list('farm-1', rabbitId: 'rabbit-1');

    expect(adapter.method, 'GET');
    expect(adapter.path, '/api/v1/farms/farm-1/matings');
    expect(adapter.queryParameters, containsPair('rabbit_id', 'rabbit-1'));
    expect(matings.single.doeIdentifier, 'DOE-0001');
  });

  test('create sends mating details', () async {
    final adapter = _CapturingAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
      ..httpClientAdapter = adapter;
    final repository = MatingRepository(dio: dio, token: 'token');

    await repository.create(
      farmId: 'farm-1',
      doeId: 'doe-1',
      buckId: 'buck-1',
      matedAt: '2026-08-05',
      outcome: 'attempted',
      behaviorObserved: 'Mounted twice',
      notes: 'Repeat if no signs.',
      confirmRelationshipRisk: true,
    );

    expect(adapter.method, 'POST');
    expect(adapter.path, '/api/v1/farms/farm-1/matings');
    expect(adapter.requestData, containsPair('doe_id', 'doe-1'));
    expect(adapter.requestData, containsPair('buck_id', 'buck-1'));
    expect(adapter.requestData, containsPair('mated_at', '2026-08-05'));
    expect(adapter.requestData, containsPair('outcome', 'attempted'));
    expect(
      adapter.requestData,
      containsPair('behavior_observed', 'Mounted twice'),
    );
    expect(adapter.requestData, containsPair('notes', 'Repeat if no signs.'));
    expect(
      adapter.requestData,
      containsPair('confirm_relationship_risk', true),
    );
  });

  test('create queues mating when offline', () async {
    final temp = await Directory.systemTemp.createTemp('rabbitrack-queue-test');
    addTearDown(() => temp.delete(recursive: true));
    final queue = OfflineActionQueue(directoryProvider: () async => temp);
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
      ..httpClientAdapter = _OfflineAdapter();
    final repository = MatingRepository(
      dio: dio,
      token: 'token',
      offlineQueue: queue,
    );

    final mating = await repository.create(
      farmId: 'farm-1',
      doeId: 'doe-1',
      buckId: 'buck-1',
      matedAt: '2026-08-05',
      outcome: 'observed',
    );

    expect(mating.id, startsWith('local-'));
    expect(mating.status, 'awaiting_pregnancy_check');
    expect(mating.pregnancyCheckDueOn, '2026-08-19');
    expect(mating.expectedKindlingOn, '2026-09-05');
    expect(await queue.pendingCount(), 1);
  });

  test('recordPregnancyCheck sends result and notes', () async {
    final adapter = _CapturingAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
      ..httpClientAdapter = adapter;
    final repository = MatingRepository(dio: dio, token: 'token');

    await repository.recordPregnancyCheck(
      farmId: 'farm-1',
      matingId: 'mating-1',
      result: 'uncertain',
      notes: 'Check again in three days',
    );

    expect(adapter.method, 'POST');
    expect(
      adapter.path,
      '/api/v1/farms/farm-1/matings/mating-1/pregnancy-checks',
    );
    expect(adapter.requestData, containsPair('result', 'uncertain'));
    expect(
      adapter.requestData,
      containsPair('notes', 'Check again in three days'),
    );
  });

  test('recordPregnancyCheck queues when offline', () async {
    final temp = await Directory.systemTemp.createTemp('rabbitrack-queue-test');
    addTearDown(() => temp.delete(recursive: true));
    final queue = OfflineActionQueue(directoryProvider: () async => temp);
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
      ..httpClientAdapter = _OfflineAdapter();
    final repository = MatingRepository(
      dio: dio,
      token: 'token',
      offlineQueue: queue,
    );

    await repository.recordPregnancyCheck(
      farmId: 'farm-1',
      matingId: 'mating-1',
      result: 'pregnant',
    );

    expect(await queue.pendingCount(), 1);
  });

  test('revisePregnancyDecision patches the latest pregnancy check', () async {
    final adapter = _CapturingAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
      ..httpClientAdapter = adapter;
    final repository = MatingRepository(dio: dio, token: 'token');

    await repository.revisePregnancyDecision(
      farmId: 'farm-1',
      matingId: 'mating-1',
      result: 'not_pregnant',
      notes: 'Changed decision',
    );

    expect(adapter.method, 'PATCH');
    expect(
      adapter.path,
      '/api/v1/farms/farm-1/matings/mating-1/pregnancy-checks/latest',
    );
    expect(adapter.requestData, containsPair('result', 'not_pregnant'));
  });

  test('revisePregnancyDecision queues when offline', () async {
    final temp = await Directory.systemTemp.createTemp('rabbitrack-queue-test');
    addTearDown(() => temp.delete(recursive: true));
    final queue = OfflineActionQueue(directoryProvider: () async => temp);
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
      ..httpClientAdapter = _OfflineAdapter();
    final repository = MatingRepository(
      dio: dio,
      token: 'token',
      offlineQueue: queue,
    );

    await repository.revisePregnancyDecision(
      farmId: 'farm-1',
      matingId: 'mating-1',
      result: 'uncertain',
    );

    expect(await queue.pendingCount(), 1);
  });

  test('delete removes a mating record', () async {
    final adapter = _CapturingAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
      ..httpClientAdapter = adapter;
    final repository = MatingRepository(dio: dio, token: 'token');

    await repository.delete(farmId: 'farm-1', matingId: 'mating-1');

    expect(adapter.method, 'DELETE');
    expect(adapter.path, '/api/v1/farms/farm-1/matings/mating-1');
  });

  test('delete queues when offline', () async {
    final temp = await Directory.systemTemp.createTemp('rabbitrack-queue-test');
    addTearDown(() => temp.delete(recursive: true));
    final queue = OfflineActionQueue(directoryProvider: () async => temp);
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
      ..httpClientAdapter = _OfflineAdapter();
    final repository = MatingRepository(
      dio: dio,
      token: 'token',
      offlineQueue: queue,
    );

    await repository.delete(farmId: 'farm-1', matingId: 'mating-1');

    expect(await queue.pendingCount(), 1);
  });
}

class _CapturingAdapter implements HttpClientAdapter {
  late String path;
  late String method;
  Map<String, dynamic> queryParameters = {};
  Map<String, dynamic> requestData = {};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    path = options.uri.path;
    method = options.method;
    queryParameters = options.queryParameters;
    if (options.data is Map) {
      requestData = Map<String, dynamic>.from(options.data as Map);
    }

    return ResponseBody.fromString(
      jsonEncode({'data': _responseData(options)}),
      201,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}

  Object _responseData(RequestOptions options) {
    final mating = {
      'id': 'mating-1',
      'doe_id': 'rabbit-1',
      'doe_identifier': 'DOE-0001',
      'buck_identifier': 'BUCK-0001',
      'pregnancy_check_due_on': '2026-08-14',
      'expected_kindling_on': '2026-08-31',
      'status': 'awaiting_pregnancy_check',
    };

    return options.method == 'GET' ? [mating] : mating;
  }
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
