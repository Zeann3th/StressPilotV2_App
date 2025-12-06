import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:stress_pilot/core/network/http_client.dart';
import '../domain/endpoint.dart';

class EndpointService {
  final Dio _dio = HttpClient.getInstance();

  Future<List<Endpoint>> fetchEndpoints({required int projectId}) async {
    final response = await _dio.get(
      '/api/v1/endpoints',
      queryParameters: {'projectId': projectId},
    );
    if (response.statusCode == 200) {
      final data = response.data;
      final List endpointsJson = data['content'] ?? [];
      return endpointsJson.map((e) => Endpoint.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load endpoints');
    }
  }

  Future<Endpoint> getEndpointDetail(int endpointId) async {
    final response = await _dio.get('/api/v1/endpoints/$endpointId');
    if (response.statusCode == 200) {
      return Endpoint.fromJson(response.data);
    } else {
      throw Exception('Failed to load endpoint detail');
    }
  }

  Future<Endpoint> createEndpoint(Map<String, dynamic> endpointData) async {
    final response = await _dio.post('/api/v1/endpoints', data: endpointData);
    if (response.statusCode == 200) {
      return Endpoint.fromJson(response.data);
    } else {
      throw Exception('Failed to create endpoint');
    }
  }

  Future<Endpoint> updateEndpoint(
    int endpointId,
    Map<String, dynamic> endpointData,
  ) async {
    // Create a copy to avoid modifying the original map
    final dataToSend = Map<String, dynamic>.from(endpointData);

    // Serialize complex fields to JSON strings if they are Maps/Lists
    // This is required because the backend uses reflection to update the Entity directly,
    // and the Entity likely stores these as JSON Strings.
    final complexFields = ['httpHeaders', 'httpParameters', 'graphqlVariables'];

    for (final field in complexFields) {
      if (dataToSend[field] is Map || dataToSend[field] is List) {
        dataToSend[field] = jsonEncode(dataToSend[field]);
      }
    }

    // httpBody special handling: if it's a Map/List, stringify it.
    if (dataToSend['httpBody'] is Map || dataToSend['httpBody'] is List) {
      dataToSend['httpBody'] = jsonEncode(dataToSend['httpBody']);
    }

    final response = await _dio.patch(
      '/api/v1/endpoints/$endpointId',
      data: dataToSend,
    );
    if (response.statusCode == 200) {
      return Endpoint.fromJson(response.data);
    } else {
      throw Exception('Failed to update endpoint');
    }
  }

  Future<void> deleteEndpoint(int endpointId) async {
    final response = await _dio.delete('/api/v1/endpoints/$endpointId');
    if (response.statusCode != 204) {
      throw Exception('Failed to delete endpoint');
    }
  }

  Future<void> uploadEndpoints({
    required String filePath,
    required int projectId,
  }) async {
    final formData = FormData.fromMap({
      'projectId': projectId.toString(),
      'file': await MultipartFile.fromFile(filePath),
    });
    final response = await _dio.post(
      '/api/v1/endpoints/upload',
      data: formData,
    );
    if (response.statusCode != 204) {
      throw Exception('Failed to upload endpoints');
    }
  }

  Future<Map<String, dynamic>> executeEndpoint(
    int endpointId,
    Map<String, dynamic> requestBody,
  ) async {
    final response = await _dio.post(
      '/api/v1/endpoints/$endpointId/execute',
      data: requestBody,
    );
    if (response.statusCode == 200) {
      return response.data as Map<String, dynamic>;
    } else {
      throw Exception('Failed to execute endpoint');
    }
  }
}
