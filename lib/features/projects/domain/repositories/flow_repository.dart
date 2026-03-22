import 'package:dio/dio.dart';
import 'package:stress_pilot/features/shared/domain/models/paged_response.dart';
import 'package:stress_pilot/features/projects/domain/models/flow.dart';

abstract class FlowRepository {
  Future<PagedResponse<Flow>> getFlows({int? projectId, String? name, int page = 0, int size = 20});
  Future<Flow> getFlowDetail(int flowId);
  Future<Flow> createFlow(CreateFlowRequest request);
  Future<Flow> updateFlow({required int flowId, String? name, String? description});
  Future<void> deleteFlow(int flowId);
  Future<List<FlowStep>> configureFlow(int flowId, List<FlowStep> steps);
  Future<void> runFlow({required int flowId, required RunFlowRequest runFlowRequest, MultipartFile? file});
}
