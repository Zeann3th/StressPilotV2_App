import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:stress_pilot/core/config/app_config.dart';
import 'package:stress_pilot/core/system/logger.dart';
import 'package:stress_pilot/core/system/session_manager.dart';

class HttpClient {
  static final Map<String, Dio> _dioInstances = {};
  static CookieJar? _cookieJar;
  static SessionManager? _sessionManager;
  static Dio getInstance({SessionManager? sessionManager, String? baseUrl}) {
    if (sessionManager != null) {
      _sessionManager = sessionManager;
    }

    final effectiveBaseUrl = baseUrl ?? AppConfig.apiBaseUrl;

    if (_dioInstances.containsKey(effectiveBaseUrl)) {
      return _dioInstances[effectiveBaseUrl]!;
    }

    final dio = Dio(
      BaseOptions(
        baseUrl: effectiveBaseUrl,
        headers: {'Content-Type': 'application/json'},
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ),
    );

    final jar = CookieJar();

    dio.interceptors.add(CookieManager(jar));

    // Error logging in release too
    dio.interceptors.add(InterceptorsWrapper(
      onError: (error, handler) {
        AppLogger.error(
          'HTTP Error: ${error.type} - ${error.message} (Path: ${error.requestOptions.path})',
          name: 'HTTP',
          error: error.error,
        );
        return handler.next(error);
      },
    ));

    dio.interceptors.add(
      InterceptorsWrapper(
        onResponse: (response, handler) {
          if (response.data is Map<String, dynamic>) {
            final data = response.data as Map<String, dynamic>;
            if (data.containsKey('errorType')) {
              if (data['errorType'] != 'SUCCESS') {
                return handler.reject(
                  DioException(
                    requestOptions: response.requestOptions,
                    response: response,
                    type: DioExceptionType.badResponse,
                    message: data['message']?.toString() ?? 'API Error',
                  ),
                );
              }
            }
          }
          return handler.next(response);
        },
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

              int attempts = 0;
              while (_sessionManager?.isRefreshing == true && attempts < 20) {
                await Future.delayed(const Duration(milliseconds: 500));
                attempts++;
              }

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

    if (kDebugMode) {
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
    }

    _dioInstances[effectiveBaseUrl] = dio;
    _cookieJar = jar;
    return dio;
  }

  static void clearCookies() {
    _cookieJar?.deleteAll();
  }

  Future<Response> get(Uri uri, {Duration? timeout}) async {
    return await getInstance().get(
      uri.toString(),
      options: timeout != null
          ? Options(connectTimeout: timeout, receiveTimeout: timeout)
          : null,
    );
  }

  Future<Response> post(Uri uri, {dynamic data, Duration? timeout}) async {
    return await getInstance().post(
      uri.toString(),
      data: data,
      options: timeout != null
          ? Options(connectTimeout: timeout, receiveTimeout: timeout)
          : null,
    );
  }

  Future<Response> patch(Uri uri, {dynamic data, Duration? timeout}) async {
    return await getInstance().patch(
      uri.toString(),
      data: data,
      options: timeout != null
          ? Options(connectTimeout: timeout, receiveTimeout: timeout)
          : null,
    );
  }

  Future<Response> delete(Uri uri, {Duration? timeout}) async {
    return await getInstance().delete(
      uri.toString(),
      options: timeout != null
          ? Options(connectTimeout: timeout, receiveTimeout: timeout)
          : null,
    );
  }

  Future<Response> upload(
    Uri uri, {
    required Map<String, String> fields,
    required String filePath,
    Duration? timeout,
  }) async {
    final formData = FormData.fromMap({
      ...fields,
      'file': await MultipartFile.fromFile(filePath),
    });
    return await getInstance().post(
      uri.toString(),
      data: formData,
      options: Options(
        connectTimeout: timeout ?? const Duration(seconds: 60),
        receiveTimeout: timeout ?? const Duration(seconds: 60),
      ),
    );
  }
}
