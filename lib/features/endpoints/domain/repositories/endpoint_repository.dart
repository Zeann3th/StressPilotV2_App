import 'package:dio/dio.dart';
import 'package:stress_pilot/features/endpoints/domain/models/endpoint.dart';
import 'package:stress_pilot/features/shared/domain/models/paged_response.dart';

abstract class EndpointRepository {
  Future<PagedResponse<Endpoint>> fetchEndpoints({required int projectId, int page = 0, int size = 20});
  Future<Endpoint> getEndpointDetail(int endpointId);
  Future<Endpoint> createEndpoint(Map<String, dynamic> endpointData);
  Future<Endpoint> updateEndpoint(int endpointId, Map<String, dynamic> endpointData);
  Future<void> deleteEndpoint(int endpointId);
  Future<void> uploadEndpoints({required String filePath, required int projectId});
  Future<Map<String, dynamic>> executeEndpoint(int endpointId, Map<String, dynamic> requestBody, {CancelToken? cancelToken});
  Future<Map<String, dynamic>> executeAdhocEndpoint({required int projectId, required Map<String, dynamic> requestBody, CancelToken? cancelToken});
}

