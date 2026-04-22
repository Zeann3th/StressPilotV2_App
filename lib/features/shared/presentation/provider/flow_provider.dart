import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:stress_pilot/core/navigation/navigation_tracker.dart';
import 'package:stress_pilot/features/projects/domain/models/flow.dart' as flow_domain;
import 'package:stress_pilot/features/shared/domain/models/paged_response.dart';
import 'package:stress_pilot/features/projects/domain/repositories/flow_repository.dart';
import 'package:stress_pilot/features/projects/data/repositories/flow_repository_impl.dart';

class FlowProvider extends ChangeNotifier {
  final FlowRepository _flowRepository = FlowRepositoryImpl();

  List<flow_domain.Flow> _flows = [];
  flow_domain.Flow? _selectedFlow;
  bool _isLoading = false;
  String? _error;

  List<flow_domain.Flow> get flows => _flows;

  flow_domain.Flow? get selectedFlow => _selectedFlow;

  bool get isLoading => _isLoading;

  String? get error => _error;

  bool get hasSelectedFlow => _selectedFlow != null;

  static const String _selectedFlowKey = 'selected_flow_json';

  Future<void> initialize() async {
    await _loadSelectedFlow();
  }

  Future<void> loadFlows({int? projectId, String? name}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final PagedResponse<flow_domain.Flow> response = await _flowRepository
          .getFlows(projectId: projectId, name: name, page: 0, size: 20);
      _flows = response.content;
    } catch (e) {
      _error = e.toString();
      _flows = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectFlow(flow_domain.Flow flowItem) async {
    _selectedFlow = flowItem;
    notifyListeners();

    NavigationTracker.trackFlow(flowItem.name, flowItem.description, flowItem.toJson());

    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(flowItem.toJson());
    await prefs.setString(_selectedFlowKey, jsonString);
  }

  Future<void> clearFlow() async {
    _selectedFlow = null;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_selectedFlowKey);
  }

  Future<void> _loadSelectedFlow() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_selectedFlowKey);

    if (jsonString != null) {
      try {
        final Map<String, dynamic> json = jsonDecode(jsonString);
        _selectedFlow = flow_domain.Flow.fromJson(json);
        notifyListeners();
      } catch (e) {
        await prefs.remove(_selectedFlowKey);
      }
    }
  }

  Future<flow_domain.Flow> createFlow(
    flow_domain.CreateFlowRequest request,
  ) async {
    try {
      final created = await _flowRepository.createFlow(request);
      _flows.insert(0, created);
      await selectFlow(created);
      return created;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<flow_domain.Flow> updateFlow({
    required int flowId,
    String? name,
    String? description,
  }) async {
    try {
      final updated = await _flowRepository.updateFlow(
        flowId: flowId,
        name: name,
        description: description,
      );

      final index = _flows.indexWhere((f) => f.id == flowId);
      if (index != -1) _flows[index] = updated;

      if (_selectedFlow?.id == flowId) {
        _selectedFlow = updated;

        final prefs = await SharedPreferences.getInstance();
        final jsonString = jsonEncode(updated.toJson());
        await prefs.setString(_selectedFlowKey, jsonString);
      }

      notifyListeners();
      return updated;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteFlow(int flowId) async {
    try {
      final isDeletingSelected = _selectedFlow?.id == flowId;

      await _flowRepository.deleteFlow(flowId);
      _flows.removeWhere((f) => f.id == flowId);

      if (isDeletingSelected) {
        if (_flows.isNotEmpty) {
          _selectedFlow = _flows.first;
          final prefs = await SharedPreferences.getInstance();
          final jsonString = jsonEncode(_selectedFlow!.toJson());
          await prefs.setString(_selectedFlowKey, jsonString);
        } else {
          _selectedFlow = null;
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove(_selectedFlowKey);
        }

        notifyListeners();
      } else {
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<flow_domain.Flow> getFlow(int flowId) async {
    try {
      final flow = await _flowRepository.getFlowDetail(flowId);

      final index = _flows.indexWhere((f) => f.id == flowId);
      if (index != -1) {
        _flows[index] = flow;
      }

      if (_selectedFlow?.id == flowId) {
        _selectedFlow = flow;
      }

      notifyListeners();
      return flow;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<List<flow_domain.FlowStep>> configureFlow(
    int flowId,
    List<flow_domain.FlowStep> steps,
  ) async {
    try {
      final updatedSteps = await _flowRepository.configureFlow(flowId, steps);

      final index = _flows.indexWhere((f) => f.id == flowId);
      if (index != -1) {
        _flows[index] = _flows[index].copyWith(steps: updatedSteps);
      }

      if (_selectedFlow?.id == flowId) {
        _selectedFlow = _selectedFlow!.copyWith(steps: updatedSteps);
      }

      notifyListeners();
      return updatedSteps;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<String> runFlow({
    required int flowId,
    required flow_domain.RunFlowRequest runFlowRequest,
    MultipartFile? file,
  }) async {
    try {
      return await _flowRepository.runFlow(
        flowId: flowId,
        runFlowRequest: runFlowRequest,
        file: file,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();

      try {
        final notification = LocalNotification(
          title: 'Stress Test Failed',
          body: 'Flow ID $flowId failed to run.',
        );
        await notification.show();
      } catch (_) {}

      rethrow;
    }
  }
}
