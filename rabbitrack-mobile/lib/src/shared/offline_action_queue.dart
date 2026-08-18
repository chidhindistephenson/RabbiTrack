import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'api_error_messages.dart';

final offlineActionQueueProvider = Provider<OfflineActionQueue>((ref) {
  return OfflineActionQueue();
});

class OfflineActionQueue {
  OfflineActionQueue({this.directoryProvider});

  final Future<Directory> Function()? directoryProvider;
  Directory? _queueDirectory;
  bool _isReplaying = false;

  Future<void> enqueue({
    required String method,
    required String path,
    required Map<String, dynamic> data,
    Map<String, dynamic> headers = const {},
  }) async {
    final directory = await _directory();
    await directory.create(recursive: true);
    final now = DateTime.now();
    final file = File(
      p.join(
        directory.path,
        '${now.microsecondsSinceEpoch}-${_stableHash(path)}.json',
      ),
    );

    await file.writeAsString(
      jsonEncode({
        'created_at': now.toIso8601String(),
        'method': method.toUpperCase(),
        'path': path,
        'data': data,
        'headers': headers,
      }),
    );
  }

  Future<int> pendingCount() async {
    final directory = await _directory();
    if (!await directory.exists()) {
      return 0;
    }

    return directory
        .list()
        .where((entity) => entity is File && entity.path.endsWith('.json'))
        .length;
  }

  Future<void> replay(Dio dio) async {
    if (_isReplaying) {
      return;
    }

    _isReplaying = true;
    try {
      final directory = await _directory();
      if (!await directory.exists()) {
        return;
      }

      final files = await directory
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.json'))
          .cast<File>()
          .toList();
      files.sort((a, b) => a.path.compareTo(b.path));

      for (final file in files) {
        final action = await _readAction(file);
        if (action == null) {
          await file.delete();
          continue;
        }

        try {
          await dio.request<Map<String, dynamic>>(
            action.path,
            data: action.data,
            options: Options(
              method: action.method,
              headers: action.headers,
              extra: {'skip_offline_queue': true},
            ),
          );
          await file.delete();
        } on DioException catch (error) {
          if (isApiConnectionProblem(error)) {
            return;
          }

          await file.delete();
        }
      }
    } finally {
      _isReplaying = false;
    }
  }

  Future<QueuedOfflineAction?> _readAction(File file) async {
    try {
      final json =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;

      return QueuedOfflineAction(
        method: json['method'] as String,
        path: json['path'] as String,
        data: Map<String, dynamic>.from(json['data'] as Map),
        headers: Map<String, dynamic>.from(json['headers'] as Map? ?? const {}),
      );
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  Future<Directory> _directory() async {
    if (_queueDirectory != null) {
      return _queueDirectory!;
    }

    final root = directoryProvider == null
        ? await getApplicationSupportDirectory()
        : await directoryProvider!();
    _queueDirectory = Directory(p.join(root.path, 'offline-actions'));

    return _queueDirectory!;
  }
}

class QueuedOfflineAction {
  const QueuedOfflineAction({
    required this.method,
    required this.path,
    required this.data,
    required this.headers,
  });

  final String method;
  final String path;
  final Map<String, dynamic> data;
  final Map<String, dynamic> headers;
}

String _stableHash(String value) {
  const offset = 0xcbf29ce484222325;
  const prime = 0x100000001b3;
  var hash = offset;

  for (final byte in utf8.encode(value)) {
    hash ^= byte;
    hash = (hash * prime) & 0x7fffffffffffffff;
  }

  return hash.toRadixString(16);
}
