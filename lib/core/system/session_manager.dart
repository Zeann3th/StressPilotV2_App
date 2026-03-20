import 'dart:async';

import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:stress_pilot/core/system/logger.dart';

class SessionManager {
  static const _logName = 'SessionManager';
  final Dio _dio;
  String? _sessionId;
  bool _isRefreshing = false;

  Timer? _keepAliveTimer;
  Duration _keepAliveInterval = const Duration(minutes: 25);

  SessionManager(this._dio);

  String? get sessionId => _sessionId;

  bool get isRefreshing => _isRefreshing;

  void startAutoRefresh({Duration? interval}) {
    _keepAliveInterval = interval ?? _keepAliveInterval;
    _keepAliveTimer?.cancel();
    _keepAliveTimer = Timer.periodic(_keepAliveInterval, (_) async {
      AppLogger.debug('Auto-refresh timer triggered', name: _logName);
      try {
        await initializeSession();
      } catch (e) {
        AppLogger.warning('Auto-refresh failed: $e', name: _logName);
      }
    });
    AppLogger.info(
      'Session auto-refresh started (every ${_keepAliveInterval.inMinutes}m)',
      name: _logName,
    );
  }

  void stopAutoRefresh() {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = null;
    AppLogger.info('Session auto-refresh stopped', name: _logName);
  }

  void dispose() {
    stopAutoRefresh();
  }

  Future<bool> waitForHealthCheck({
    int maxAttempts = 15,
    Duration initialInterval = const Duration(seconds: 1),
    Duration maxInterval = const Duration(seconds: 15),
  }) async {
    AppLogger.info(
      'Starting health check (max $maxAttempts attempts, exponential backoff)',
      name: _logName,
    );

    Duration currentInterval = initialInterval;

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      AppLogger.debug(
        'Health check attempt $attempt/$maxAttempts (waiting ${currentInterval.inSeconds}s)...',
        name: _logName,
      );

      try {
        // First try the session endpoint as it's the most critical
        final sessionResponse = await _dio.get(
          '/api/v1/utilities/session',
          options: Options(
            sendTimeout: const Duration(seconds: 3),
            receiveTimeout: const Duration(seconds: 3),
            validateStatus: (status) => status != null && status < 500,
          ),
        );

        if (sessionResponse.statusCode == 200) {
          AppLogger.info('Backend session is ready!', name: _logName);
          _sessionId = sessionResponse.data['data']?.toString();
          startAutoRefresh();
          return true;
        }

        // Fallback to actuator health if session endpoint didn't give 200
        final healthResponse = await _dio.get(
          '/actuator/health',
          options: Options(
            sendTimeout: const Duration(seconds: 3),
            receiveTimeout: const Duration(seconds: 3),
            validateStatus: (status) => status != null && status < 500,
          ),
        );

        if (healthResponse.statusCode == 200 &&
            healthResponse.data is Map &&
            healthResponse.data['status'] == 'UP') {
          AppLogger.info('Backend health is UP!', name: _logName);
          return true;
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
        await Future.delayed(currentInterval);
        // Exponential backoff with a cap
        currentInterval = currentInterval * 1.5;
        if (currentInterval > maxInterval) {
          currentInterval = maxInterval;
        }
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
          _sessionId = response.data['data']?.toString();
          AppLogger.info('Session ID: $_sessionId', name: _logName);

          try {
            final cookieManager = _dio.interceptors
                .whereType<CookieManager>()
                .firstOrNull;
            if (cookieManager == null) {
              AppLogger.warning('CookieManager not found in interceptors', name: _logName);
            } else {
              final cookies = await cookieManager.cookieJar.loadForRequest(
                Uri.parse('${_dio.options.baseUrl}/api/v1/utilities/session'),
              );

              AppLogger.debug(
                'Stored cookies: ${cookies.map((c) => '${c.name}=${c.value}').join(', ')}',
                name: _logName,
              );
            }
          } catch (e) {
            AppLogger.warning(
              'Could not load cookies for logging',
              name: _logName,
            );
          }

          try {
            startAutoRefresh();
          } catch (e) {
            AppLogger.debug('Failed to start auto-refresh: $e', name: _logName);
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
