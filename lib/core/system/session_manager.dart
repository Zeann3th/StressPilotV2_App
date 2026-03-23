import 'dart:async';

import 'package:dio/dio.dart';
import 'package:stress_pilot/core/system/logger.dart';

class SessionManager {
  static const _logName = 'SessionManager';
  final Dio _dio;
  String? _sessionId;
  bool _isRefreshing = false;

  Timer? _keepAliveTimer;
  Duration _keepAliveInterval = const Duration(minutes: 5);

  SessionManager(this._dio);

  String? get sessionId => _sessionId;

  bool get isRefreshing => _isRefreshing;

  void startAutoRefresh({Duration? interval}) {
    _keepAliveInterval = interval ?? _keepAliveInterval;
    _keepAliveTimer?.cancel();
    _keepAliveTimer = Timer.periodic(_keepAliveInterval, (_) async {
      AppLogger.debug('Auto-refresh timer triggered', name: _logName);
      try {

        await _dio.get('/api/v1/utilities/session', options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ));
        AppLogger.debug('Session keep-alive successful', name: _logName);
      } catch (e) {
        AppLogger.warning('Session keep-alive failed, re-initializing...', name: _logName);
        try {
          await initializeSession(retry: true);
        } catch (e2) {
          AppLogger.error('Session re-initialization failed during auto-refresh', name: _logName, error: e2);
        }
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
    int maxAttempts = 20,
    Duration initialInterval = const Duration(seconds: 1),
    Duration maxInterval = const Duration(seconds: 10),
  }) async {
    AppLogger.info(
      'Starting session health check (max $maxAttempts attempts)',
      name: _logName,
    );

    Duration currentInterval = initialInterval;

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final sessionResponse = await _dio.get(
          '/api/v1/utilities/session',
          options: Options(
            sendTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 5),
            validateStatus: (status) => status != null && status < 500,
          ),
        );

        if (sessionResponse.statusCode == 200) {
          AppLogger.info('Backend session is ready!', name: _logName);
          _sessionId = sessionResponse.data['data']?.toString();
          startAutoRefresh();
          return true;
        }
      } on DioException catch (e) {
        AppLogger.debug(
          'Health check attempt $attempt/$maxAttempts failed: ${e.type} - ${e.message}',
          name: _logName,
        );
      } catch (e) {
        AppLogger.error(
          'Unexpected error during health check attempt $attempt',
          name: _logName,
          error: e,
        );
      }

      if (attempt < maxAttempts) {
        await Future.delayed(currentInterval);
        currentInterval = (currentInterval * 1.5);
        if (currentInterval > maxInterval) currentInterval = maxInterval;
      }
    }

    AppLogger.error(
      'Backend failed to provide a session after $maxAttempts attempts. App may be unhealthy.',
      name: _logName,
    );
    return false;
  }

  Future<void> initializeSession({bool retry = false}) async {
    if (_isRefreshing) {
      AppLogger.debug('Session refresh already in progress', name: _logName);
      return;
    }

    _isRefreshing = true;

    try {
      await AppLogger.measure('Session initialization', () async {
        final success = await waitForHealthCheck(
          maxAttempts: retry ? 5 : 20,
        );

        if (!success) {
          throw Exception('Failed to initialize session after multiple attempts');
        }
      }, name: _logName);
    } finally {
      _isRefreshing = false;
    }
  }
}
