import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/sales/sale_repository.dart';
import 'package:rabbitrack_mobile/src/shared/offline_action_queue.dart';

void main() {
  test('list sends rabbit filter when supplied', () async {
    final adapter = _CapturingAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
      ..httpClientAdapter = adapter;
    final repository = SaleRepository(dio: dio, token: 'token');

    final sales = await repository.list('farm-1', rabbitId: 'rabbit-1');

    expect(adapter.method, 'GET');
    expect(adapter.path, '/api/v1/farms/farm-1/sales');
    expect(adapter.queryParameters, containsPair('rabbit_id', 'rabbit-1'));
    expect(sales.single.rabbitIdentifier, 'DOE-0001');
  });

  test('create queues sale when offline', () async {
    final temp = await Directory.systemTemp.createTemp('rabbitrack-queue-test');
    addTearDown(() => temp.delete(recursive: true));
    final queue = OfflineActionQueue(directoryProvider: () async => temp);
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
      ..httpClientAdapter = _OfflineAdapter();
    final repository = SaleRepository(
      dio: dio,
      token: 'token',
      offlineQueue: queue,
    );

    final sale = await repository.create(
      farmId: 'farm-1',
      rabbitId: 'rabbit-1',
      salePrice: 25,
      soldOn: '2026-08-17',
      buyerName: 'Local buyer',
    );

    expect(sale.id, startsWith('local-'));
    expect(sale.salePrice, '25.00');
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
            'id': 'sale-1',
            'rabbit_id': 'rabbit-1',
            'rabbit_identifier': 'DOE-0001',
            'buyer_name': 'Local buyer',
            'buyer_phone': '+263 77 123 4567',
            'sold_on': '2026-08-04',
            'sale_price': '25.00',
            'currency': 'USD',
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
