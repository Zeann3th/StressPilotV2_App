import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stress_pilot/features/projects/domain/flow.dart';
import 'package:stress_pilot/features/projects/presentation/provider/flow_provider.dart';
import 'package:uuid/uuid.dart';

import '../../domain/canvas.dart';

class CanvasProvider extends ChangeNotifier {
  List<CanvasNode> _nodes = [];
  List<CanvasConnection> _connections = [];

  // Dragging state
  String? _tempSourceNodeId;
  String? _tempSourceHandle;
  Offset? _tempDragPosition;

  bool _isLoading = false;
  bool _isSaving = false;

  List<CanvasNode> get nodes => _nodes;

  List<CanvasConnection> get connections => _connections;

  String? get tempSourceNodeId => _tempSourceNodeId;
  String? get tempSourceHandle => _tempSourceHandle;

  Offset? get tempDragPosition => _tempDragPosition;

  bool get isLoading => _isLoading;

  bool get isSaving => _isSaving;

  // --- Node Management ---

  void addNode(CanvasNode node) {
    _nodes.add(node);
    notifyListeners();
  }

  void updateNodePosition(String id, Offset newPos) {
    final index = _nodes.indexWhere((n) => n.id == id);
    if (index != -1) {
      _nodes[index] = _nodes[index].copyWith(position: newPos);
      notifyListeners();
    }
  }

  void removeNode(String id) {
    _nodes.removeWhere((n) => n.id == id);
    _connections.removeWhere(
      (c) => c.sourceNodeId == id || c.targetNodeId == id,
    );
    notifyListeners();
  }

  void removeConnection(String connectionId) {
    _connections.removeWhere((c) => c.id == connectionId);
    notifyListeners();
  }

  void clearCanvas() {
    _nodes.clear();
    _connections.clear();
    notifyListeners();
  }

  // --- Connection Management ---

  void startConnection(String nodeId, String handleId, Offset startPos) {
    _tempSourceNodeId = nodeId;
    _tempSourceHandle = handleId;
    _tempDragPosition = startPos;
    notifyListeners();
  }

  void updateTempConnection(Offset currentPos) {
    _tempDragPosition = currentPos;
    notifyListeners();
  }

  void endConnection(String targetNodeId) {
    if (_tempSourceNodeId != null && _tempSourceNodeId != targetNodeId) {
      _connections.removeWhere(
        (c) =>
            c.sourceNodeId == _tempSourceNodeId &&
            c.sourceHandle == _tempSourceHandle,
      );

      _connections.add(
        CanvasConnection(
          id: const Uuid().v4(),
          sourceNodeId: _tempSourceNodeId!,
          sourceHandle: _tempSourceHandle,
          targetNodeId: targetNodeId,
        ),
      );
    }
    cancelConnection();
  }

  void cancelConnection() {
    _tempSourceNodeId = null;
    _tempSourceHandle = null;
    _tempDragPosition = null;
    notifyListeners();
  }

  // --- Storage (Local Layout) ---

  Future<void> saveFlowLayout(String flowId, {bool silent = false}) async {
    _isSaving = true;
    if (!silent) notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final layoutData = {
        'nodes': _nodes.map((n) => n.toJson()).toList(),
        'connections': _connections.map((c) => c.toJson()).toList(),
      };
      await prefs.setString('flow_layout_$flowId', jsonEncode(layoutData));
    } finally {
      _isSaving = false;
      if (!silent) notifyListeners();
    }
  }

  Future<void> loadFlowLayout(String flowId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('flow_layout_$flowId');

      if (jsonString != null) {
        final data = jsonDecode(jsonString);
        _nodes = (data['nodes'] as List)
            .map((e) => CanvasNode.fromJson(e))
            .toList();
        _connections = (data['connections'] as List)
            .map((e) => CanvasConnection.fromJson(e))
            .toList();
      } else {
        _nodes = [];
        _connections = [];
      }
    } catch (e) {
      debugPrint("Error loading layout: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Configuration Logic ---

  Future<void> saveFlowConfiguration(
    int flowId,
    FlowProvider flowProvider,
  ) async {
    _isSaving = true;
    notifyListeners();

    try {
      // 1. Generate configuration with smuggled IDs
      final steps = generateFlowConfiguration();

      // 2. Send to backend via FlowProvider
      final updatedSteps = await flowProvider.configureFlow(flowId, steps);

      // 3. Sync local nodes with backend IDs
      syncWithBackend(updatedSteps);

      // 4. Save local layout again with new IDs
      await saveFlowLayout(flowId.toString(), silent: true);
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// 1. Generate Configuration with "Smuggled" ID
  /// We inject the client-side `node.id` into `preProcessor['_temp_sync_id']`.
  /// The backend will save this blob and return it to us unchanged.
  List<FlowStep> generateFlowConfiguration() {
    return _nodes.map((node) {
      String type;
      int? endpointId;
      String? condition;

      switch (node.type) {
        case FlowNodeType.start:
          type = 'START';
          break;
        case FlowNodeType.branch:
          type = 'BRANCH';
          condition = node.data['condition']?.toString() ?? 'true';
          break;
        case FlowNodeType.endpoint:
          type = 'ENDPOINT';
          endpointId = node.data['id'];
          break;
      }

      String? nextIfTrue;
      String? nextIfFalse;

      final outgoing = _connections.where((c) => c.sourceNodeId == node.id);

      for (var conn in outgoing) {
        if (node.type == FlowNodeType.branch) {
          if (conn.sourceHandle == 'true') {
            nextIfTrue = conn.targetNodeId;
          } else if (conn.sourceHandle == 'false') {
            nextIfFalse = conn.targetNodeId;
          }
        } else {
          nextIfTrue = conn.targetNodeId;
        }
      }

      // Preserve existing preProcessor data if any, and add our sync ID
      Map<String, dynamic> preProcessor = {};
      if (node.data['preProcessor'] != null) {
        preProcessor = Map<String, dynamic>.from(node.data['preProcessor']);
      }
      preProcessor['_temp_sync_id'] = node.id;

      return FlowStep(
        id: node.id,
        // Backend will likely ignore/overwrite this
        type: type,
        endpointId: endpointId,
        nextIfTrue: nextIfTrue,
        nextIfFalse: nextIfFalse,
        condition: condition,
        preProcessor: preProcessor,
        // <--- ID hidden here
        postProcessor: node.data['postProcessor'],
      );
    }).toList();
  }

  /// 2. Sync Logic
  /// Read the `_temp_sync_id` from the response to map Backend IDs to Local Nodes
  void syncWithBackend(List<FlowStep> responseSteps) {
    Map<String, String> idMap = {}; // Map<OldId, NewId>

    // 1. Build the Map using the smuggled ID
    for (var step in responseSteps) {
      final oldId = step.preProcessor?['_temp_sync_id'];
      if (oldId != null && oldId is String) {
        idMap[oldId] = step.id;
      }
    }

    // 2. Update Nodes (ID + Data)
    for (int i = 0; i < _nodes.length; i++) {
      final oldId = _nodes[i].id;
      if (idMap.containsKey(oldId)) {
        final newId = idMap[oldId]!;

        // Clean up the temp ID from our local data to keep it clean
        final Map<String, dynamic> updatedData = Map.from(_nodes[i].data);
        if (updatedData.containsKey('preProcessor')) {
          final pre = Map<String, dynamic>.from(updatedData['preProcessor']);
          pre.remove('_temp_sync_id');
          updatedData['preProcessor'] = pre;
        }

        _nodes[i] = _nodes[i].copyWith(id: newId, data: updatedData);
      }
    }

    // 3. Update Connections (Source + Target)
    for (int i = 0; i < _connections.length; i++) {
      final conn = _connections[i];
      final newSource = idMap[conn.sourceNodeId] ?? conn.sourceNodeId;
      final newTarget = idMap[conn.targetNodeId] ?? conn.targetNodeId;

      if (newSource != conn.sourceNodeId || newTarget != conn.targetNodeId) {
        _connections[i] = CanvasConnection(
          id: conn.id,
          sourceNodeId: newSource,
          targetNodeId: newTarget,
          sourceHandle: conn.sourceHandle,
          targetHandle: conn.targetHandle,
        );
      }
    }

    notifyListeners();
  }
}
