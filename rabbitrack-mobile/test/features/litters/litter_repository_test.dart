import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/litters/litter_repository.dart';
import 'package:rabbitrack_mobile/src/shared/offline_action_queue.dart';

void main() {
  test('recordKindling sends litter birth weight fields', () async {
    final adapter = _CapturingAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
      ..httpClientAdapter = adapter;
    final repository = LitterRepository(dio: dio, token: 'token');

    final litter = await repository.recordKindling(
      farmId: 'farm-1',
      matingId: 'mating-1',
      kitsBornAlive: 8,
      kitsStillborn: 1,
      kitsWeak: 2,
      birthWeightValue: 0.64,
      nestCondition: 'Clean',
      doeCondition: 'Calm',
    );

    expect(adapter.method, 'POST');
    expect(adapter.path, '/api/v1/farms/farm-1/kindlings');
    expect(adapter.requestData, containsPair('mating_id', 'mating-1'));
    expect(adapter.requestData, containsPair('kits_born_alive', 8));
    expect(adapter.requestData, containsPair('birth_weight_value', 0.64));
    expect(litter.identifier, 'LIT-260817-TEST');
  });

  test('recordKindling queues when offline', () async {
    final temp = await Directory.systemTemp.createTemp('rabbitrack-queue-test');
    addTearDown(() => temp.delete(recursive: true));
    final queue = OfflineActionQueue(directoryProvider: () async => temp);
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
      ..httpClientAdapter = _OfflineAdapter();
    final repository = LitterRepository(
      dio: dio,
      token: 'token',
      offlineQueue: queue,
    );

    final litter = await repository.recordKindling(
      farmId: 'farm-1',
      doeId: 'doe-1',
      kitsBornAlive: 7,
      kitsStillborn: 0,
      kitsWeak: 1,
      birthWeightValue: 0.58,
    );

    expect(litter.id, startsWith('local-'));
    expect(litter.identifier, 'Pending litter');
    expect(litter.currentLiveCount, 7);
    expect(litter.status, 'nursing');
    expect(await queue.pendingCount(), 1);
  });

  test('offline demo list and detail include queued kindlings', () async {
    final temp = await Directory.systemTemp.createTemp('rabbitrack-queue-test');
    addTearDown(() => temp.delete(recursive: true));
    final queue = OfflineActionQueue(directoryProvider: () async => temp);
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
      ..httpClientAdapter = _OfflineAdapter();
    final repository = LitterRepository(
      dio: dio,
      token: 'offline-demo-owner',
      offlineQueue: queue,
    );

    await repository.recordKindling(
      farmId: 'offline-demo-farm',
      doeId: 'offline-doe-0047',
      kitsBornAlive: 6,
      kitsStillborn: 1,
      kitsWeak: 0,
      birthWeightValue: 0.72,
    );

    final litters = await repository.list('offline-demo-farm');
    final pending = litters.last;
    final detail = await repository.show(
      farmId: 'offline-demo-farm',
      litterId: pending.id,
    );

    expect(pending.identifier, startsWith('LIT-'));
    expect(pending.currentLiveCount, 6);
    expect(detail.kitsStillborn, 1);
    expect(detail.weights.single.stage, 'birth');
  });

  test('recordWeaning sends weaning fields', () async {
    final adapter = _CapturingAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
      ..httpClientAdapter = adapter;
    final repository = LitterRepository(dio: dio, token: 'token');

    await repository.recordWeaning(
      farmId: 'farm-1',
      litterId: 'litter-1',
      numberWeaned: 6,
      averageWeightValue: 0.92,
      destination: 'Grow-out cage',
      notes: 'Uniform litter',
    );

    expect(adapter.method, 'POST');
    expect(adapter.path, '/api/v1/farms/farm-1/litters/litter-1/weanings');
    expect(adapter.requestData, containsPair('number_weaned', 6));
    expect(adapter.requestData, containsPair('average_weight_value', 0.92));
    expect(adapter.requestData, containsPair('destination', 'Grow-out cage'));
  });

  test('recordWeaning queues when offline', () async {
    final temp = await Directory.systemTemp.createTemp('rabbitrack-queue-test');
    addTearDown(() => temp.delete(recursive: true));
    final queue = OfflineActionQueue(directoryProvider: () async => temp);
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
      ..httpClientAdapter = _OfflineAdapter();
    final repository = LitterRepository(
      dio: dio,
      token: 'token',
      offlineQueue: queue,
    );

    await repository.recordWeaning(
      farmId: 'farm-1',
      litterId: 'litter-1',
      numberWeaned: 5,
      averageWeightValue: 0.84,
    );

    expect(await queue.pendingCount(), 1);
  });

  test('convertKits sends conversion fields', () async {
    final adapter = _CapturingAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
      ..httpClientAdapter = adapter;
    final repository = LitterRepository(dio: dio, token: 'token');

    final result = await repository.convertKits(
      farmId: 'farm-1',
      litterId: 'litter-1',
      count: 3,
      sex: 'unknown',
      breed: 'Rex',
      colour: 'Black',
    );

    expect(adapter.method, 'POST');
    expect(adapter.path, '/api/v1/farms/farm-1/litters/litter-1/conversions');
    expect(adapter.requestData, containsPair('count', 3));
    expect(adapter.requestData, containsPair('breed', 'Rex'));
    expect(result.convertedCount, 3);
    expect(result.rabbits.single.identifier, 'RAB-0001');
  });

  test('convertKits queues when offline', () async {
    final temp = await Directory.systemTemp.createTemp('rabbitrack-queue-test');
    addTearDown(() => temp.delete(recursive: true));
    final queue = OfflineActionQueue(directoryProvider: () async => temp);
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
      ..httpClientAdapter = _OfflineAdapter();
    final repository = LitterRepository(
      dio: dio,
      token: 'token',
      offlineQueue: queue,
    );

    final result = await repository.convertKits(
      farmId: 'farm-1',
      litterId: 'litter-1',
      count: 2,
    );

    expect(result.convertedCount, 2);
    expect(await queue.pendingCount(), 1);
  });

  test('recordCheck sends litter check fields', () async {
    final adapter = _CapturingAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
      ..httpClientAdapter = adapter;
    final repository = LitterRepository(dio: dio, token: 'token');

    final check = await repository.recordCheck(
      farmId: 'farm-1',
      litterId: 'litter-1',
      liveCount: 6,
      deadCount: 1,
      weakCount: 2,
      suspectedCause: 'Chilling',
      nestObservation: 'Damp nest',
      correctiveAction: 'Changed bedding',
    );

    expect(adapter.method, 'POST');
    expect(adapter.path, '/api/v1/farms/farm-1/litters/litter-1/checks');
    expect(adapter.requestData, containsPair('live_count', 6));
    expect(adapter.requestData, containsPair('dead_count', 1));
    expect(adapter.requestData, containsPair('weak_count', 2));
    expect(check.liveCount, 6);
    expect(check.suspectedCause, 'Chilling');
  });

  test('recordCheck queues when offline', () async {
    final temp = await Directory.systemTemp.createTemp('rabbitrack-queue-test');
    addTearDown(() => temp.delete(recursive: true));
    final queue = OfflineActionQueue(directoryProvider: () async => temp);
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
      ..httpClientAdapter = _OfflineAdapter();
    final repository = LitterRepository(
      dio: dio,
      token: 'token',
      offlineQueue: queue,
    );

    final check = await repository.recordCheck(
      farmId: 'farm-1',
      litterId: 'litter-1',
      liveCount: 5,
      deadCount: 1,
    );

    expect(check.id, startsWith('local-'));
    expect(check.liveCount, 5);
    expect(await queue.pendingCount(), 1);
  });

  test('recordFoster sends fostering fields', () async {
    final adapter = _CapturingAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
      ..httpClientAdapter = adapter;
    final repository = LitterRepository(dio: dio, token: 'token');

    final foster = await repository.recordFoster(
      farmId: 'farm-1',
      fromLitterId: 'litter-1',
      toLitterId: 'litter-2',
      kitCount: 2,
      reason: 'Balance litter sizes',
      notes: 'Accepted quickly',
    );

    expect(adapter.method, 'POST');
    expect(adapter.path, '/api/v1/farms/farm-1/litters/litter-1/fosters');
    expect(adapter.requestData, containsPair('to_litter_id', 'litter-2'));
    expect(adapter.requestData, containsPair('kit_count', 2));
    expect(adapter.requestData, containsPair('reason', 'Balance litter sizes'));
    expect(foster.kitCount, 2);
    expect(foster.toLitterIdentifier, 'LIT-DEST');
  });

  test('recordFoster queues when offline', () async {
    final temp = await Directory.systemTemp.createTemp('rabbitrack-queue-test');
    addTearDown(() => temp.delete(recursive: true));
    final queue = OfflineActionQueue(directoryProvider: () async => temp);
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
      ..httpClientAdapter = _OfflineAdapter();
    final repository = LitterRepository(
      dio: dio,
      token: 'token',
      offlineQueue: queue,
    );

    final foster = await repository.recordFoster(
      farmId: 'farm-1',
      fromLitterId: 'litter-1',
      toLitterId: 'litter-2',
      kitCount: 1,
    );

    expect(foster.id, startsWith('local-'));
    expect(foster.kitCount, 1);
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
      jsonEncode({'data': _responseData()}),
      201,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}

  Object _responseData() {
    if (path.endsWith('/conversions')) {
      return {
        'converted_count': requestData['count'],
        'remaining_count': 0,
        'rabbits': [
          {
            'id': 'rabbit-1',
            'identifier': 'RAB-0001',
            'sex': 'unknown',
            'breed': requestData['breed'],
            'status': 'growing',
          },
        ],
      };
    }

    if (path.endsWith('/checks')) {
      return {
        'id': 'check-1',
        'litter_id': 'litter-1',
        'checked_on': '2026-08-17',
        'live_count': requestData['live_count'],
        'dead_count': requestData['dead_count'],
        'weak_count': requestData['weak_count'],
        'suspected_cause': requestData['suspected_cause'],
        'nest_observation': requestData['nest_observation'],
        'corrective_action': requestData['corrective_action'],
        'notes': requestData['notes'],
      };
    }

    if (path.endsWith('/fosters')) {
      return {
        'id': 'foster-1',
        'fostered_on': '2026-08-17',
        'kit_count': requestData['kit_count'],
        'reason': requestData['reason'],
        'notes': requestData['notes'],
        'from_litter_id': 'litter-1',
        'from_litter_identifier': 'LIT-SOURCE',
        'to_litter_id': requestData['to_litter_id'],
        'to_litter_identifier': 'LIT-DEST',
      };
    }

    return {
      'id': 'litter-1',
      'identifier': 'LIT-260817-TEST',
      'doe_id': 'doe-1',
      'doe_identifier': 'DOE-0001',
      'buck_id': 'buck-1',
      'buck_identifier': 'BUCK-0001',
      'kindled_on': '2026-08-17',
      'current_live_count': requestData['kits_born_alive'] ?? 6,
      'converted_rabbits_count': 0,
      'unconverted_kits_count': requestData['kits_born_alive'] ?? 6,
      'planned_weaning_on': '2026-09-21',
      'status': 'nursing',
      'checks': [],
      'fosters_out': [],
      'fosters_in': [],
    };
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
