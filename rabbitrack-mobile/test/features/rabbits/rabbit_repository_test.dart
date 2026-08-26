import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/rabbits/rabbit_repository.dart';
import 'package:rabbitrack_mobile/src/shared/offline_action_queue.dart';

void main() {
  test('RabbitRepository.list sends breed filters', () async {
    final adapter = _CapturingAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
      ..httpClientAdapter = adapter;
    final repository = RabbitRepository(dio: dio, token: 'test-token');

    await repository.list(
      'farm-1',
      search: 'doe',
      sex: 'female',
      status: 'growing',
      breed: 'New Zealand White',
    );

    expect(adapter.method, 'GET');
    expect(adapter.path, '/api/v1/farms/farm-1/rabbits');
    expect(adapter.queryParameters, containsPair('search', 'doe'));
    expect(adapter.queryParameters, containsPair('sex', 'female'));
    expect(adapter.queryParameters, containsPair('status', 'growing'));
    expect(adapter.queryParameters, containsPair('breed', 'New Zealand White'));
  });

  test('RabbitRepository.create does not send a manual identifier', () async {
    final adapter = _CapturingAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
      ..httpClientAdapter = adapter;
    final repository = RabbitRepository(dio: dio, token: 'test-token');

    final rabbit = await repository.create(
      farmId: 'farm-1',
      name: 'Freya',
      sex: 'female',
      status: 'growing',
      breed: 'New Zealand White',
      colour: 'White',
      currentLocationId: 'location-1',
      dateOfBirth: '2026-01-15',
      weightValue: '2.4',
      weightUnit: 'kg',
      tagOrTattoo: 'TAG-42',
      notes: 'Strong grower',
      motherId: 'doe-1',
      fatherId: 'buck-1',
    );

    final data = adapter.requestData;

    expect(adapter.path, '/api/v1/farms/farm-1/rabbits');
    expect(data.containsKey('identifier'), isFalse);
    expect(data['sex'], 'female');
    expect(data['status'], 'growing');
    expect(data['name'], 'Freya');
    expect(data['current_location_id'], 'location-1');
    expect(data['date_of_birth'], '2026-01-15');
    expect(data['weight_value'], '2.4');
    expect(data['weight_unit'], 'kg');
    expect(data['tag_or_tattoo'], 'TAG-42');
    expect(data['notes'], 'Strong grower');
    expect(data['mother_id'], 'doe-1');
    expect(data['father_id'], 'buck-1');
    expect(rabbit.identifier, 'DOE-0048');
  });

  test('RabbitRepository.create omits unselected optional fields', () async {
    final adapter = _CapturingAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
      ..httpClientAdapter = adapter;
    final repository = RabbitRepository(dio: dio, token: 'test-token');

    await repository.create(
      farmId: 'farm-1',
      sex: 'unknown',
      status: 'growing',
    );

    final data = adapter.requestData;

    expect(data, containsPair('sex', 'unknown'));
    expect(data, containsPair('status', 'growing'));
    expect(data.containsKey('identifier'), isFalse);
    expect(data.containsKey('name'), isFalse);
    expect(data.containsKey('breed'), isFalse);
    expect(data.containsKey('colour'), isFalse);
    expect(data.containsKey('current_location_id'), isFalse);
  });

  test('RabbitRepository queues create action when offline', () async {
    final temp = await Directory.systemTemp.createTemp('rabbitrack-queue-test');
    addTearDown(() => temp.delete(recursive: true));
    final queue = OfflineActionQueue(directoryProvider: () async => temp);
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
      ..httpClientAdapter = _OfflineAdapter();
    final repository = RabbitRepository(
      dio: dio,
      token: 'test-token',
      offlineQueue: queue,
    );

    final rabbit = await repository.create(
      farmId: 'farm-1',
      name: 'Offline Doe',
      sex: 'female',
      status: 'growing',
      breed: 'Rex',
    );

    expect(rabbit.id, startsWith('local-'));
    expect(rabbit.identifier, 'Pending ID');
    expect(rabbit.name, 'Offline Doe');
    expect(await queue.pendingCount(), 1);
  });

  test('offline demo can open queued local rabbit detail', () async {
    final temp = await Directory.systemTemp.createTemp('rabbitrack-queue-test');
    addTearDown(() => temp.delete(recursive: true));
    final queue = OfflineActionQueue(directoryProvider: () async => temp);
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
      ..httpClientAdapter = _OfflineAdapter();
    final repository = RabbitRepository(
      dio: dio,
      token: 'offline-demo-owner',
      offlineQueue: queue,
    );

    await repository.create(
      farmId: 'offline-demo-farm',
      name: 'Local Rex',
      sex: 'female',
      status: 'growing',
      breed: 'Rex',
      colour: 'Black',
      currentLocationId: 'offline-house-1',
      tagOrTattoo: 'LR-01',
      notes: 'Offline profile',
    );

    final rabbits = await repository.list('offline-demo-farm');
    final local = rabbits.last;
    final detail = await repository.show(
      farmId: 'offline-demo-farm',
      rabbitId: local.id,
    );

    expect(local.identifier, 'LR-01');
    expect(detail.name, 'Local Rex');
    expect(detail.colour, 'Black');
    expect(detail.currentLocationName, 'House 1');
    expect(detail.notes, 'Offline profile');
  });

  test('empty offline farm starts without seeded rabbits', () async {
    final temp = await Directory.systemTemp.createTemp('rabbitrack-queue-test');
    addTearDown(() => temp.delete(recursive: true));
    final queue = OfflineActionQueue(directoryProvider: () async => temp);
    final repository = RabbitRepository(
      dio: Dio(BaseOptions(baseUrl: 'http://localhost/api/v1')),
      token: 'offline-demo-owner',
      offlineQueue: queue,
    );

    expect(await repository.list('offline-empty-farm'), isEmpty);
  });

  test('RabbitRepository queues movement action when offline', () async {
    final temp = await Directory.systemTemp.createTemp('rabbitrack-queue-test');
    addTearDown(() => temp.delete(recursive: true));
    final queue = OfflineActionQueue(directoryProvider: () async => temp);
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
      ..httpClientAdapter = _OfflineAdapter();
    final repository = RabbitRepository(
      dio: dio,
      token: 'test-token',
      offlineQueue: queue,
    );

    final movement = await repository.move(
      farmId: 'farm-1',
      rabbitId: 'rabbit-1',
      toLocationId: 'location-2',
      reason: 'Cage cleaning',
    );

    expect(movement.id, startsWith('local-'));
    expect(movement.rabbitId, 'rabbit-1');
    expect(movement.toLocationId, 'location-2');
    expect(await queue.pendingCount(), 1);
  });

  test('RabbitRepository.updateStatus sends notes when supplied', () async {
    final adapter = _CapturingAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
      ..httpClientAdapter = adapter;
    final repository = RabbitRepository(dio: dio, token: 'test-token');

    final rabbit = await repository.updateStatus(
      farmId: 'farm-1',
      rabbitId: 'rabbit-1',
      status: 'ready_for_sale',
      notes: 'Reached target weight',
    );

    expect(adapter.method, 'PATCH');
    expect(adapter.path, '/api/v1/farms/farm-1/rabbits/rabbit-1');
    expect(adapter.requestData, containsPair('status', 'ready_for_sale'));
    expect(adapter.requestData, containsPair('notes', 'Reached target weight'));
    expect(rabbit.status, 'ready_for_sale');
  });

  test('RabbitRepository.updateStatus omits blank notes', () async {
    final adapter = _CapturingAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
      ..httpClientAdapter = adapter;
    final repository = RabbitRepository(dio: dio, token: 'test-token');

    await repository.updateStatus(
      farmId: 'farm-1',
      rabbitId: 'rabbit-1',
      status: 'pregnant',
    );

    expect(adapter.requestData, containsPair('status', 'pregnant'));
    expect(adapter.requestData.containsKey('notes'), isFalse);
  });

  test('RabbitRepository queues status update when offline', () async {
    final temp = await Directory.systemTemp.createTemp('rabbitrack-queue-test');
    addTearDown(() => temp.delete(recursive: true));
    final queue = OfflineActionQueue(directoryProvider: () async => temp);
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
      ..httpClientAdapter = _OfflineAdapter();
    final repository = RabbitRepository(
      dio: dio,
      token: 'test-token',
      offlineQueue: queue,
    );

    final rabbit = await repository.updateStatus(
      farmId: 'farm-1',
      rabbitId: 'rabbit-1',
      status: 'ready_for_sale',
      notes: 'Offline status change',
    );

    expect(rabbit.id, 'rabbit-1');
    expect(rabbit.status, 'ready_for_sale');
    expect(await queue.pendingCount(), 1);
  });

  test(
    'RabbitRepository.updateProfile sends editable profile fields',
    () async {
      final adapter = _CapturingAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
        ..httpClientAdapter = adapter;
      final repository = RabbitRepository(dio: dio, token: 'test-token');

      await repository.updateProfile(
        farmId: 'farm-1',
        rabbitId: 'rabbit-1',
        name: 'Freya',
        sex: 'female',
        status: 'available_for_breeding',
        breed: 'Rex',
        colour: 'Black',
        currentLocationId: 'location-1',
        dateOfBirth: '2025-12-10',
        weightValue: '3.25',
        weightUnit: 'kg',
        tagOrTattoo: 'TAG-77',
        notes: 'Good condition',
        motherId: 'doe-1',
        fatherId: 'buck-1',
      );

      expect(adapter.method, 'PATCH');
      expect(adapter.path, '/api/v1/farms/farm-1/rabbits/rabbit-1');
      expect(adapter.requestData, containsPair('name', 'Freya'));
      expect(adapter.requestData, containsPair('sex', 'female'));
      expect(
        adapter.requestData,
        containsPair('status', 'available_for_breeding'),
      );
      expect(adapter.requestData, containsPair('breed', 'Rex'));
      expect(adapter.requestData, containsPair('colour', 'Black'));
      expect(
        adapter.requestData,
        containsPair('current_location_id', 'location-1'),
      );
      expect(adapter.requestData, containsPair('date_of_birth', '2025-12-10'));
      expect(adapter.requestData, containsPair('weight_value', '3.25'));
      expect(adapter.requestData, containsPair('weight_unit', 'kg'));
      expect(adapter.requestData, containsPair('tag_or_tattoo', 'TAG-77'));
      expect(adapter.requestData, containsPair('notes', 'Good condition'));
      expect(adapter.requestData, containsPair('mother_id', 'doe-1'));
      expect(adapter.requestData, containsPair('father_id', 'buck-1'));
    },
  );

  test('RabbitRepository.updateProfile sends nulls to clear fields', () async {
    final adapter = _CapturingAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
      ..httpClientAdapter = adapter;
    final repository = RabbitRepository(dio: dio, token: 'test-token');

    await repository.updateProfile(
      farmId: 'farm-1',
      rabbitId: 'rabbit-1',
      sex: 'unknown',
      status: 'growing',
    );

    expect(adapter.requestData, containsPair('sex', 'unknown'));
    expect(adapter.requestData, containsPair('status', 'growing'));
    expect(adapter.requestData.containsKey('breed'), isTrue);
    expect(adapter.requestData['breed'], isNull);
    expect(adapter.requestData.containsKey('weight_value'), isTrue);
    expect(adapter.requestData['weight_value'], isNull);
  });

  test('RabbitRepository queues profile update when offline', () async {
    final temp = await Directory.systemTemp.createTemp('rabbitrack-queue-test');
    addTearDown(() => temp.delete(recursive: true));
    final queue = OfflineActionQueue(directoryProvider: () async => temp);
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
      ..httpClientAdapter = _OfflineAdapter();
    final repository = RabbitRepository(
      dio: dio,
      token: 'test-token',
      offlineQueue: queue,
    );

    final rabbit = await repository.updateProfile(
      farmId: 'farm-1',
      rabbitId: 'rabbit-1',
      name: 'Offline Rex',
      sex: 'male',
      status: 'growing',
      breed: 'Rex',
    );

    expect(rabbit.id, 'rabbit-1');
    expect(rabbit.name, 'Offline Rex');
    expect(rabbit.sex, 'male');
    expect(await queue.pendingCount(), 1);
  });
}

class _CapturingAdapter implements HttpClientAdapter {
  late String path;
  late String method;
  late Map<String, dynamic> queryParameters;
  late Map<String, dynamic> requestData;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    path = options.uri.path;
    method = options.method;
    queryParameters = options.queryParameters;
    requestData = options.data is Map
        ? Map<String, dynamic>.from(options.data as Map)
        : <String, dynamic>{};

    final responseData = options.uri.path.endsWith('/movements')
        ? {
            'id': 'movement-1',
            'rabbit_id': 'rabbit-1',
            'from_location_id': 'location-1',
            'to_location_id': requestData['to_location_id'],
            'moved_at': '2026-08-17T12:00:00Z',
            'reason': requestData['reason'],
            'notes': requestData['notes'],
          }
        : options.method == 'GET'
        ? [
            {
              'id': 'rabbit-1',
              'identifier': 'DOE-0048',
              'sex': 'female',
              'breed': 'New Zealand White',
              'status': 'growing',
            },
          ]
        : {
            'id': 'rabbit-1',
            'identifier': 'DOE-0048',
            'name': requestData['name'],
            'sex': requestData['sex'] ?? 'female',
            'breed': requestData['breed'],
            'status': requestData['status'],
            'current_location_name':
                requestData.containsKey('current_location_id')
                ? 'Cage 1'
                : null,
          };

    return ResponseBody.fromString(
      jsonEncode({'data': responseData}),
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
