import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stress_pilot/features/endpoints/domain/repositories/endpoint_repository.dart';
import 'package:stress_pilot/features/endpoints/data/repositories/endpoint_repository_impl.dart';
import 'package:stress_pilot/features/endpoints/domain/models/endpoint.dart';
import 'package:stress_pilot/features/shared/domain/models/paged_response.dart';

class EndpointProvider extends ChangeNotifier {
  final EndpointRepository _endpointRepository = EndpointRepositoryImpl();
  List<Endpoint> _endpoints = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;

  int _currentPage = 0;
  int _pageSize = 20;
  bool _hasMore = true;

  bool _isExecuting = false;
  String? _error;

  String _getCacheKey(int projectId) => 'endpoints_project_${projectId}_json';

  Future<void> _cacheEndpoints(int projectId) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(_endpoints.map((e) => e.toJson()).toList());
    await prefs.setString(_getCacheKey(projectId), jsonString);
  }

  Future<void> _loadCachedEndpoints(int projectId) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_getCacheKey(projectId));
    if (jsonString != null) {
      try {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        _endpoints = jsonList.map((e) => Endpoint.fromJson(e)).toList();
        notifyListeners();
      } catch (_) {}
    }
  }

  List<Endpoint> get endpoints => _endpoints;

  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;

  bool get isExecuting => _isExecuting;

  String? get error => _error;

  Future<void> loadEndpoints({required int projectId, int pageSize = 20}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    _currentPage = 0;
    _pageSize = pageSize;
    _hasMore = true;

    try {
      final PagedResponse<Endpoint> page = await _endpointRepository.fetchEndpoints(
        projectId: projectId,
        page: _currentPage,
        size: _pageSize,
      );

      _endpoints = page.content;
      _hasMore = _currentPage < (page.totalPages - 1);
      await _cacheEndpoints(projectId);
    } catch (e) {
      _error = e.toString();
      if (_endpoints.isEmpty) await _loadCachedEndpoints(projectId);
      _hasMore = false;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMoreEndpoints({required int projectId}) async {
    if (!_hasMore || _isLoadingMore) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final PagedResponse<Endpoint> page = await _endpointRepository.fetchEndpoints(
        projectId: projectId,
        page: nextPage,
        size: _pageSize,
      );

      _endpoints.addAll(page.content);
      _currentPage = page.pageNumber;
      _hasMore = _currentPage < (page.totalPages - 1);
    } catch (e) {
      _error = e.toString();

    }

    _isLoadingMore = false;
    notifyListeners();
  }

  Future<void> refreshEndpoints({required int projectId}) async {
    await loadEndpoints(projectId: projectId);
  }

  Future<Endpoint> cloneEndpoint(Endpoint endpoint) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = endpoint.toJson();
      data.remove('id'); // Remove original ID
      data['name'] = '${endpoint.name} copy';

      final created = await _endpointRepository.createEndpoint(data);
      await loadEndpoints(projectId: endpoint.projectId);
      _isLoading = false;
      notifyListeners();
      return created;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
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
      final created = await _endpointRepository.createEndpoint(data);
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
      final updated = await _endpointRepository.updateEndpoint(id, data);
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
      await _endpointRepository.deleteEndpoint(id);
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
      await _endpointRepository.uploadEndpoints(filePath: filePath, projectId: projectId);
      await loadEndpoints(projectId: projectId);
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<Endpoint> getEndpoint(int id) async {
    return await _endpointRepository.getEndpointDetail(id);
  }

  Future<Map<String, dynamic>> executeEndpoint(
    int endpointId,
    Map<String, dynamic> body,
  ) async {
    _isExecuting = true;
    notifyListeners();

    try {
      final result = await _endpointRepository.executeEndpoint(endpointId, body);
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
