import 'package:flutter/material.dart';
import '../../domain/endpoint.dart';
import '../../data/endpoint_service.dart';

class EndpointProvider extends ChangeNotifier {
  final EndpointService _service = EndpointService();
  List<Endpoint> _endpoints = [];
  bool _isLoading = false;
  String? _error;

  List<Endpoint> get endpoints => _endpoints;
  bool get isLoading => _isLoading;
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

  Future<void> uploadEndpointsFile({required String filePath, required int projectId}) async {
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
}
