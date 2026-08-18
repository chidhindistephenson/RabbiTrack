import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/shared/offline_action_queue.dart';

void main() {
  test('OfflineActionQueue stores and replays queued actions', () async {
    final temp = await Directory.systemTemp.createTemp('rabbitrack-queue-test');
    addTearDown(() => temp.delete(recursive: true));

    final queue = OfflineActionQueue(directoryProvider: () async => temp);
    await queue.enqueue(
      method: 'PATCH',
      path: '/farms/farm-1/tasks/task-1',
      data: {'action': 'complete'},
      headers: {'Authorization': 'Bearer token'},
    );

    expect(await queue.pendingCount(), 1);

    final adapter = _CapturingAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
      ..httpClientAdapter = adapter;

    await queue.replay(dio);

    expect(adapter.requests.single.method, 'PATCH');
    expect(adapter.requests.single.path, '/api/v1/farms/farm-1/tasks/task-1');
    expect(adapter.requests.single.data, {'action': 'complete'});
    expect(await queue.pendingCount(), 0);
  });
}

class _CapturedRequest {
  const _CapturedRequest({
    required this.method,
    required this.path,
    required this.data,
  });

  final String method;
  final String path;
  final Map<String, dynamic> data;
}

class _CapturingAdapter implements HttpClientAdapter {
  final requests = <_CapturedRequest>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final body = await utf8.decodeStream(requestStream ?? const Stream.empty());
    requests.add(
      _CapturedRequest(
        method: options.method,
        path: options.uri.path,
        data: jsonDecode(body) as Map<String, dynamic>,
      ),
    );

    return ResponseBody.fromString(
      jsonEncode({'data': {}}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
