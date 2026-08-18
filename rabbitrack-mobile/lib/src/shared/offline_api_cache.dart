import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'api_error_messages.dart';

final offlineApiCacheProvider = Provider<OfflineApiCache>((ref) {
  return OfflineApiCache();
});

final offlineApiStatusProvider = StateProvider<OfflineApiStatus>((ref) {
  return const OfflineApiStatus.online();
});

class OfflineApiStatus {
  const OfflineApiStatus({
    required this.usingCachedData,
    this.cachedAt,
    this.lastOnlineAt,
  });

  const OfflineApiStatus.online({DateTime? at})
    : usingCachedData = false,
      cachedAt = null,
      lastOnlineAt = at;

  const OfflineApiStatus.cached({required DateTime this.cachedAt})
    : usingCachedData = true,
      lastOnlineAt = null;

  final bool usingCachedData;
  final DateTime? cachedAt;
  final DateTime? lastOnlineAt;
}

class OfflineApiCache {
  OfflineApiCache({this.directoryProvider});

  final Future<Directory> Function()? directoryProvider;
  Directory? _cacheDirectory;

  Future<void> put(RequestOptions request, Object? data) async {
    if (!_isCacheable(request) || data == null) {
      return;
    }

    final file = await _fileFor(request);
    await file.parent.create(recursive: true);
    await file.writeAsString(
      jsonEncode({
        'cached_at': DateTime.now().toIso8601String(),
        'url': request.uri.toString(),
        'data': data,
      }),
    );
  }

  Future<CachedApiResponse?> get(RequestOptions request) async {
    if (!_isCacheable(request)) {
      return null;
    }

    final file = await _fileFor(request);
    if (!await file.exists()) {
      return null;
    }

    try {
      final json =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;

      return CachedApiResponse(
        cachedAt: DateTime.parse(json['cached_at'] as String),
        data: json['data'],
      );
    } on FormatException {
      await file.delete();

      return null;
    }
  }

  Future<File> _fileFor(RequestOptions request) async {
    final directory = await _directory();
    final authHash = _stableHash(
      request.headers[HttpHeaders.authorizationHeader]?.toString() ?? '',
    );
    final urlHash = _stableHash(request.uri.toString());

    return File(p.join(directory.path, '$authHash-$urlHash.json'));
  }

  Future<Directory> _directory() async {
    if (_cacheDirectory != null) {
      return _cacheDirectory!;
    }

    final root = directoryProvider == null
        ? await getApplicationSupportDirectory()
        : await directoryProvider!();
    _cacheDirectory = Directory(p.join(root.path, 'api-cache'));

    return _cacheDirectory!;
  }

  bool _isCacheable(RequestOptions request) {
    return request.method.toUpperCase() == 'GET';
  }
}

class CachedApiResponse {
  const CachedApiResponse({required this.cachedAt, required this.data});

  final DateTime cachedAt;
  final Object? data;
}

class OfflineCacheInterceptor extends Interceptor {
  OfflineCacheInterceptor({
    required this.cache,
    this.onOnlineResponse,
    this.onCachedResponse,
  });

  final OfflineApiCache cache;
  final void Function()? onOnlineResponse;
  final void Function(DateTime cachedAt)? onCachedResponse;

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (response.statusCode == 200) {
      cache.put(response.requestOptions, response.data);
      onOnlineResponse?.call();
    }

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (!isApiConnectionProblem(err)) {
      handler.next(err);
      return;
    }

    final cached = await cache.get(err.requestOptions);
    if (cached == null) {
      handler.next(err);
      return;
    }

    handler.resolve(
      Response(
        requestOptions: err.requestOptions,
        data: cached.data,
        statusCode: 200,
        statusMessage: 'OK (offline cache)',
        extra: {
          ...err.response?.extra ?? const <String, dynamic>{},
          'offline_cache': true,
          'offline_cached_at': cached.cachedAt.toIso8601String(),
        },
      ),
    );
    onCachedResponse?.call(cached.cachedAt);
  }
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
