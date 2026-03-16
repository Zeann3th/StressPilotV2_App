import 'package:dio/dio.dart';
import 'package:stress_pilot/core/network/http_client.dart';

class UtilityService {
  final Dio _dio = HttpClient.getInstance();

  Future<String> getSession() async {
    final response = await _dio.get('/api/v1/utilities/session');
    return response.data['data'].toString();
  }
}
