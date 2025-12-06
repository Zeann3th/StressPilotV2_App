import 'package:flutter/material.dart';

import '../../data/endpoint_service.dart';
import '../../domain/endpoint.dart';

class EndpointProvider extends ChangeNotifier {
  final EndpointService _service = EndpointService();
  List<Endpoint> _endpoints = [];
  bool _isLoading = false;

  // --- Added Execution State ---
  bool _isExecuting = false;
  String? _error;

  List<Endpoint> get endpoints => _endpoints;

  bool get isLoading => _isLoading;

  // --- Added Getter ---
  bool get isExecuting => _isExecuting;

  String? get error => _error;

  Future<void> loadEndpoints({required int projectId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _endpoints = await _service.fetchEndpoints(projectId: projectId);
    } catch (e) {
      _error = e.toString();
      _endpoints = [];
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshEndpoints({required int projectId}) async {
    await loadEndpoints(projectId: projectId);
  }

  void clearEndpoints() {
    _endpoints = [];
    notifyListeners();
  }

  Future<Endpoint> createEndpoint(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final created = await _service.createEndpoint(data);
      if (data['projectId'] != null) {
        await loadEndpoints(projectId: data['projectId']);
      }
      return created;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<Endpoint> updateEndpoint(int id, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updated = await _service.updateEndpoint(id, data);
      if (data['projectId'] != null) {
        await loadEndpoints(projectId: data['projectId']);
      }
      return updated;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteEndpoint(int id, int projectId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.deleteEndpoint(id);
      await loadEndpoints(projectId: projectId);
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> uploadEndpointsFile({
    required String filePath,
    required int projectId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.uploadEndpoints(filePath: filePath, projectId: projectId);
      await loadEndpoints(projectId: projectId);
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // --- Added Execution Method ---
  Future<Map<String, dynamic>> executeEndpoint(
    int endpointId,
    Map<String, dynamic> body,
  ) async {
    _isExecuting = true;
    notifyListeners();

    try {
      final result = await _service.executeEndpoint(endpointId, body);
      _isExecuting = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isExecuting = false;
      notifyListeners();
      rethrow;
    }
  }
}
