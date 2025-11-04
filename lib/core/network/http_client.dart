import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:stress_pilot/core/config/app_config.dart';

class HttpClient {
  static Dio? _dio;
  static CookieJar? _cookieJar;

  static Dio getInstance() {
    if (_dio != null) return _dio!;

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

    _dio = dio;
    _cookieJar = jar;
    return dio;
  }

  static void clearCookies() {
    _cookieJar?.deleteAll();
  }
}
