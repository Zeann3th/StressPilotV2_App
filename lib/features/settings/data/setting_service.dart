import 'package:dio/dio.dart';
import 'package:stress_pilot/core/network/http_client.dart';

class SettingService {
  final Dio _dio = HttpClient.getInstance();

  Future<Map<String, String>> getAllConfigs() async {
    final response = await _dio.get('/api/v1/config');
    final data = Map<String, dynamic>.from(response.data);

    return data.map((key, value) => MapEntry(key, value.toString()));
  }

  Future<String?> getConfigValue(String key) async {
    try {
      final response = await _dio.get(
        '/api/v1/config/value',
        queryParameters: {"key": key},
      );
      return response.data.toString();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<void> setConfigValue({
    required String key,
    required String value,
  }) async {
    final body = {"key": key, "value": value};

    await _dio.post('/api/v1/config', data: body);
  }
}
