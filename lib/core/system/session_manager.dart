import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:stress_pilot/core/system/logger.dart';

class SessionManager {
  static const _logName = 'SessionManager';
  final Dio _dio;
  String? _sessionId;
  bool _isRefreshing = false;

  SessionManager(this._dio);

  String? get sessionId => _sessionId;

  bool get isRefreshing => _isRefreshing;

  Future<bool> waitForHealthCheck({
    int maxAttempts = 12,
    Duration interval = const Duration(seconds: 5),
  }) async {
    AppLogger.info(
      'Starting health check (max $maxAttempts attempts, ${interval.inSeconds}s interval)',
      name: _logName,
    );

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      AppLogger.debug(
        'Health check attempt $attempt/$maxAttempts...',
        name: _logName,
      );

      try {
        final response = await _dio.get(
          '/api/v1/utilities/healthz',
          options: Options(
            sendTimeout: const Duration(seconds: 3),
            receiveTimeout: const Duration(seconds: 3),
            validateStatus: (status) => status != null && status < 500,
          ),
        );

        AppLogger.debug(
          'Health check response: ${response.statusCode} - ${response.data}',
          name: _logName,
        );

        if (response.statusCode == 200 && response.data == 'OK') {
          AppLogger.info('Backend is ready!', name: _logName);
          return true;
        } else {
          AppLogger.warning(
            'Unexpected health check response: ${response.statusCode}',
            name: _logName,
          );
        }
      } on DioException catch (e) {
        AppLogger.debug(
          'Health check failed: ${e.type} - ${e.message}',
          name: _logName,
        );
      } catch (e) {
        AppLogger.error(
          'Unexpected error during health check',
          name: _logName,
          error: e,
        );
      }

      if (attempt < maxAttempts) {
        await Future.delayed(interval);
      }
    }

    AppLogger.error(
      'Backend failed to become ready after $maxAttempts attempts',
      name: _logName,
    );
    return false;
  }

  Future<void> initializeSession() async {
    if (_isRefreshing) {
      AppLogger.debug('Session refresh already in progress', name: _logName);
      return;
    }

    _isRefreshing = true;

    try {
      await AppLogger.measure('Session initialization', () async {
        AppLogger.info('Requesting session...', name: _logName);

        final response = await _dio.get(
          '/api/v1/utilities/session',
          options: Options(
            validateStatus: (status) => status != null && status < 500,
          ),
        );

        AppLogger.debug(
          'Session response: ${response.statusCode} - ${response.data}',
          name: _logName,
        );

        if (response.statusCode == 200) {
          _sessionId = response.data;
          AppLogger.info('Session ID: $_sessionId', name: _logName);

          try {
            final cookieManager = _dio.interceptors
                .whereType<CookieManager>()
                .first;
            final cookies = await cookieManager.cookieJar.loadForRequest(
              Uri.parse('${_dio.options.baseUrl}/api/v1/utilities/session'),
            );

            AppLogger.debug(
              'Stored cookies: ${cookies.map((c) => '${c.name}=${c.value}').join(', ')}',
              name: _logName,
            );
          } catch (e) {
            AppLogger.warning(
              'Could not load cookies for logging',
              name: _logName,
            );
          }
        } else {
          throw Exception(
            'Failed to get session: ${response.statusCode} - ${response.data}',
          );
        }
      }, name: _logName);
    } finally {
      _isRefreshing = false;
    }
  }
}
