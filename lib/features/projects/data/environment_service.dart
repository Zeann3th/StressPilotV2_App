import 'package:dio/dio.dart';
import 'package:stress_pilot/core/network/http_client.dart';
import '../domain/environment_variable.dart';

class EnvironmentService {
  final Dio _dio = HttpClient.getInstance();

  Future<List<EnvironmentVariable>> getVariables(int environmentId) async {
    final response = await _dio.get(
      '/api/v1/environments/$environmentId/variables',
    );
    if (response.statusCode == 200) {
      final List data = response.data;
      return data.map((e) => EnvironmentVariable.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load environment variables');
    }
  }

  Future<void> updateVariables({
    required int environmentId,
    required List<Map<String, dynamic>> added,
    required List<Map<String, dynamic>> updated,
    required List<int> removed,
  }) async {
    final payload = {'added': added, 'updated': updated, 'removed': removed};

    final response = await _dio.patch(
      '/api/v1/environments/$environmentId/variables',
      data: payload,
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to update environment variables');
    }
  }
}
