import 'package:dio/dio.dart';

/// A simple in-memory cache interceptor that caches GET responses for a
/// configurable [ttl] (default 5 minutes). Non-GET requests bypass the cache
/// entirely and also invalidate any cache entries whose path prefix matches.
class CacheInterceptor extends Interceptor {
  final Duration ttl;

  CacheInterceptor({this.ttl = const Duration(minutes: 5)});

  final Map<String, _CacheEntry> _cache = {};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.method.toUpperCase() != 'GET') {
      final basePath = options.path.split('?').first;
      _cache.removeWhere((key, _) => key.startsWith(basePath));
      return handler.next(options);
    }

    final key = _cacheKey(options);
    final entry = _cache[key];
    if (entry != null && !entry.isExpired(ttl)) {
      return handler.resolve(
        Response(
          requestOptions: options,
          data: entry.data,
          statusCode: entry.statusCode,
          headers: entry.headers,
        ),
        true,
      );
    }

    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (response.requestOptions.method.toUpperCase() == 'GET' &&
        response.statusCode != null &&
        response.statusCode! >= 200 &&
        response.statusCode! < 300) {
      final key = _cacheKey(response.requestOptions);
      _cache[key] = _CacheEntry(
        data: response.data,
        statusCode: response.statusCode!,
        headers: response.headers,
        cachedAt: DateTime.now(),
      );
    }

    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    return handler.next(err);
  }

  String _cacheKey(RequestOptions options) {
    final sorted = (options.queryParameters.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key)))
        .map((e) => '${e.key}=${e.value}')
        .join('&');
    return '${options.path}?$sorted';
  }

  void clear() => _cache.clear();
}

class _CacheEntry {
  final dynamic data;
  final int statusCode;
  final Headers headers;
  final DateTime cachedAt;

  _CacheEntry({
    required this.data,
    required this.statusCode,
    required this.headers,
    required this.cachedAt,
  });

  bool isExpired(Duration ttl) =>
      DateTime.now().difference(cachedAt) > ttl;
}
