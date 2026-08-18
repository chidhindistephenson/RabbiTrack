import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/shared/offline_api_cache.dart';

void main() {
  test(
    'OfflineApiCache stores and restores GET responses by URL and token',
    () async {
      final temp = await Directory.systemTemp.createTemp(
        'rabbitrack-cache-test',
      );
      addTearDown(() => temp.delete(recursive: true));

      final cache = OfflineApiCache(directoryProvider: () async => temp);
      final request = RequestOptions(
        method: 'GET',
        path: '/farms/farm-1/rabbits',
        baseUrl: 'http://10.0.2.2:8000/api/v1',
        queryParameters: {'status': 'growing'},
        headers: {'Authorization': 'Bearer token-123'},
      );

      await cache.put(request, {
        'data': [
          {'id': 'rabbit-1', 'identifier': 'DOE-0001'},
        ],
      });

      final cached = await cache.get(request);

      expect(cached, isNotNull);
      expect(cached!.data, {
        'data': [
          {'id': 'rabbit-1', 'identifier': 'DOE-0001'},
        ],
      });
    },
  );

  test('OfflineApiCache does not cache write requests', () async {
    final temp = await Directory.systemTemp.createTemp('rabbitrack-cache-test');
    addTearDown(() => temp.delete(recursive: true));

    final cache = OfflineApiCache(directoryProvider: () async => temp);
    final request = RequestOptions(
      method: 'POST',
      path: '/farms/farm-1/rabbits',
      baseUrl: 'http://10.0.2.2:8000/api/v1',
    );

    await cache.put(request, {'data': 'ignored'});

    expect(await cache.get(request), isNull);
  });
}
