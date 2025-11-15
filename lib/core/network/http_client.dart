import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:stress_pilot/core/config/app_config.dart';
import 'package:stress_pilot/core/system/logger.dart';
import 'package:stress_pilot/core/system/session_manager.dart';

class HttpClient {
  static Dio? _dio;
  static CookieJar? _cookieJar;
  static SessionManager? _sessionManager;

  static Dio getInstance({SessionManager? sessionManager}) {
    if (_dio != null) return _dio!;

    if (sessionManager != null) {
      _sessionManager = sessionManager;
    }

    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        headers: {'Content-Type': 'application/json'},
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    final jar = CookieJar();

    dio.interceptors.add(CookieManager(jar));

    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            AppLogger.warning(
              'Received 401 - Session expired, attempting to refresh...',
              name: 'HTTP',
            );

            final isSessionRequest = error.requestOptions.path.contains(
              '/api/v1/utilities/session',
            );

            if (isSessionRequest) {
              AppLogger.error(
                'Session endpoint itself returned 401 - cannot refresh',
                name: 'HTTP',
              );
              return handler.next(error);
            }

            if (_sessionManager?.isRefreshing == true) {
              AppLogger.debug(
                'Session refresh already in progress, waiting...',
                name: 'HTTP',
              );
              await Future.delayed(const Duration(milliseconds: 500));

              try {
                final response = await dio.fetch(error.requestOptions);
                return handler.resolve(response);
              } catch (e) {
                return handler.next(error);
              }
            }

            try {
              await _sessionManager?.initializeSession();

              AppLogger.info(
                'Session refreshed successfully, retrying original request',
                name: 'HTTP',
              );

              final options = error.requestOptions;
              final response = await dio.fetch(options);
              return handler.resolve(response);
            } catch (e) {
              AppLogger.error(
                'Failed to refresh session',
                name: 'HTTP',
                error: e,
              );
              return handler.next(error);
            }
          }

          return handler.next(error);
        },
      ),
    );

    dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        logPrint: (obj) => AppLogger.info(obj.toString(), name: 'HTTP'),
      ),
    );

    _dio = dio;
    _cookieJar = jar;
    return dio;
  }

  static void clearCookies() {
    _cookieJar?.deleteAll();
  }
}
