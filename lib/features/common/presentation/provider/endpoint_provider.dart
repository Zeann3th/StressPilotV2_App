import 'package:flutter/material.dart';

import '../../data/endpoint_service.dart';
import '../../domain/endpoint.dart';
import 'package:stress_pilot/core/models/paged_response.dart';

class EndpointProvider extends ChangeNotifier {
  final EndpointService _service = EndpointService();
  List<Endpoint> _endpoints = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;

  // Pagination state
  int _currentPage = 0; // 0-based
  int _pageSize = 20;
  bool _hasMore = true;

  // --- Added Execution State ---
  bool _isExecuting = false;
  String? _error;

  List<Endpoint> get endpoints => _endpoints;

  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;

  // --- Added Getter ---
  bool get isExecuting => _isExecuting;

  String? get error => _error;

  /// Loads the first page of endpoints (resets pagination).
  Future<void> loadEndpoints({required int projectId, int pageSize = 20}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    _currentPage = 0;
    _pageSize = pageSize;
    _hasMore = true;

    try {
      final PagedResponse<Endpoint> page = await _service.fetchEndpoints(
        projectId: projectId,
        page: _currentPage,
        size: _pageSize,
      );

      _endpoints = page.content;
      _hasMore = _currentPage < (page.totalPages - 1);
    } catch (e) {
      _error = e.toString();
      _endpoints = [];
      _hasMore = false;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Loads the next page and appends to the endpoints list if available.
  Future<void> loadMoreEndpoints({required int projectId}) async {
    if (!_hasMore || _isLoadingMore) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final PagedResponse<Endpoint> page = await _service.fetchEndpoints(
        projectId: projectId,
        page: nextPage,
        size: _pageSize,
      );

      _endpoints.addAll(page.content);
      _currentPage = page.pageNumber;
      _hasMore = _currentPage < (page.totalPages - 1);
    } catch (e) {
      _error = e.toString();
      // Do not clear existing endpoints on loadMore failure
    }

    _isLoadingMore = false;
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
