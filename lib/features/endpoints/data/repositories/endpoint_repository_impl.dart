import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:stress_pilot/core/network/http_client.dart';
import 'package:stress_pilot/features/endpoints/domain/models/endpoint.dart';
import 'package:stress_pilot/features/shared/domain/models/paged_response.dart';
import '../../domain/repositories/endpoint_repository.dart';

class EndpointRepositoryImpl implements EndpointRepository {
  final Dio _dio = HttpClient.getInstance();

  @override
  Future<PagedResponse<Endpoint>> fetchEndpoints({
    required int projectId,
    int page = 0,
    int size = 20,
  }) async {
    final response = await _dio.get(
      '/api/v1/endpoints',
      queryParameters: {
        'projectId': projectId,
        'page': page,
        'size': size,
      },
    );

    if (response.statusCode == 200) {
      return PagedResponse.fromJson(
        response.data['data'],
        (json) => Endpoint.fromJson(json),
      );
    } else {
      throw Exception('Failed to load endpoints');
    }
  }

  @override
  Future<Endpoint> getEndpointDetail(int endpointId) async {
    final response = await _dio.get('/api/v1/endpoints/$endpointId');
    if (response.statusCode == 200) {
      return Endpoint.fromJson(response.data['data']);
    } else {
      throw Exception('Failed to load endpoint detail');
    }
  }

  @override
  Future<Endpoint> createEndpoint(Map<String, dynamic> endpointData) async {
    final response = await _dio.post('/api/v1/endpoints', data: endpointData);
    if (response.statusCode == 200) {
      return Endpoint.fromJson(response.data['data']);
    } else {
      throw Exception('Failed to create endpoint');
    }
  }

  @override
  Future<Endpoint> updateEndpoint(
    int endpointId,
    Map<String, dynamic> endpointData,
  ) async {
    final dataToSend = Map<String, dynamic>.from(endpointData);
    final complexFields = ['httpHeaders', 'httpParameters', 'graphqlVariables'];

    for (final field in complexFields) {
      if (dataToSend[field] is Map || dataToSend[field] is List) {
        dataToSend[field] = jsonEncode(dataToSend[field]);
      }
    }

    if (dataToSend['body'] is Map || dataToSend['body'] is List) {
      dataToSend['body'] = jsonEncode(dataToSend['body']);
    }

    final response = await _dio.patch(
      '/api/v1/endpoints/$endpointId',
      data: dataToSend,
    );
    if (response.statusCode == 200) {
      return Endpoint.fromJson(response.data['data']);
    } else {
      throw Exception('Failed to update endpoint');
    }
  }

  @override
  Future<void> deleteEndpoint(int endpointId) async {
    final response = await _dio.delete('/api/v1/endpoints/$endpointId');
    if (response.statusCode != 204) {
      throw Exception('Failed to delete endpoint');
    }
  }

  @override
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

  @override
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

  @override
  Future<Map<String, dynamic>> executeAdhocEndpoint({
    required int projectId,
    required Map<String, dynamic> requestBody,
  }) async {
    final response = await _dio.post(
      '/api/v1/endpoints/execute-adhoc',
      queryParameters: {'projectId': projectId},
      data: requestBody,
    );
    if (response.statusCode == 200) {
      return response.data as Map<String, dynamic>;
    } else {
      throw Exception('Failed to execute adhoc endpoint');
    }
  }
}
