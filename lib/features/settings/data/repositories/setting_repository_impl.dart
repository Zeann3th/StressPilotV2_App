import 'package:dio/dio.dart';
import 'package:stress_pilot/core/network/http_client.dart';
import '../../domain/repositories/setting_repository.dart';

class SettingRepositoryImpl implements SettingRepository {
  final Dio _dio = HttpClient.getInstance();

  @override
  Future<Map<String, String>> getAllConfigs() async {
    final response = await _dio.get('/api/v1/config');
    final data = Map<String, dynamic>.from(response.data['data']);

    return data.map((key, value) => MapEntry(key, value.toString()));
  }

  @override
  Future<String?> getConfigValue(String key) async {
    try {
      final response = await _dio.get(
        '/api/v1/config/value',
        queryParameters: {"key": key},
      );
      return response.data['data'].toString();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  @override
  Future<void> setConfigValue({
    required String key,
    required String value,
  }) async {
    final body = {"key": key, "value": value};

    await _dio.post('/api/v1/config', data: body);
  }
}
