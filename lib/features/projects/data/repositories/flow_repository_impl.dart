import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:stress_pilot/core/network/http_client.dart';
import 'package:stress_pilot/core/domain/entities/paged_response.dart';
import 'package:stress_pilot/core/domain/entities/flow.dart';
import '../../domain/repositories/flow_repository.dart';

class FlowRepositoryImpl implements FlowRepository {
  final Dio _dio = HttpClient.getInstance();

  @override
  Future<PagedResponse<Flow>> getFlows({
    int? projectId,
    String? name,
    int page = 0,
    int size = 20,
  }) async {
    final response = await _dio.get(
      '/api/v1/flows',
      queryParameters: {
        if (projectId != null) 'projectId': projectId,
        if (name != null && name.isNotEmpty) 'name': name,
        'page': page,
        'size': size,
      },
    );

    return PagedResponse.fromJson(response.data['data'], (json) => Flow.fromJson(json));
  }

  @override
  Future<Flow> getFlowDetail(int flowId) async {
    final response = await _dio.get('/api/v1/flows/$flowId');
    return Flow.fromJson(response.data['data']);
  }

  @override
  Future<Flow> createFlow(CreateFlowRequest request) async {
    final response = await _dio.post('/api/v1/flows', data: request.toJson());
    return Flow.fromJson(response.data['data']);
  }

  @override
  Future<Flow> updateFlow({
    required int flowId,
    String? name,
    String? description,
  }) async {
    final body = {
      if (name != null) 'name': name,
      if (description != null) 'description': description,
    };

    final response = await _dio.patch('/api/v1/flows/$flowId', data: body);
    return Flow.fromJson(response.data['data']);
  }

  @override
  Future<void> deleteFlow(int flowId) async {
    await _dio.delete('/api/v1/flows/$flowId');
  }

  @override
  Future<List<FlowStep>> configureFlow(int flowId, List<FlowStep> steps) async {
    final body = steps.map((s) => s.toJson()).toList();
    final response = await _dio.post(
      '/api/v1/flows/$flowId/configuration',
      data: body,
    );
    return (response.data['data'] as List)
        .map((json) => FlowStep.fromJson(json))
        .toList();
  }

  @override
  Future<void> runFlow({
    required int flowId,
    required RunFlowRequest runFlowRequest,
    MultipartFile? file,
  }) async {
    final formData = FormData();
    formData.files.add(
      MapEntry(
        'request',
        MultipartFile.fromString(
          jsonEncode(runFlowRequest.toJson()),
          contentType: MediaType.parse('application/json'),
        ),
      ),
    );
    if (file != null) {
      formData.files.add(MapEntry('file', file));
    }

    await _dio.post(
      '/api/v1/flows/$flowId/execute',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
  }
}
