import 'package:flutter/material.dart' hide Flow;
import 'package:stress_pilot/core/domain/entities/canvas.dart';
import 'package:stress_pilot/features/projects/presentation/provider/flow_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/domain/entities/endpoint.dart' as domain_endpoint;
import '../../../../core/domain/entities/flow.dart';

enum CanvasMode { move, connect }

class CanvasProvider extends ChangeNotifier {
  List<CanvasNode> _nodes = [];
  List<CanvasConnection> _connections = [];

  String? _tempSourceNodeId;
  String? _tempSourceHandle;
  Offset? _tempDragPosition;

  CanvasMode _canvasMode = CanvasMode.move;
  String? _selectedSourceNodeId;
  String? _selectedSourceHandle;

  bool _isLoading = false;
  bool _isSaving = false;

  // Tracks the flow that is currently loaded so we never accidentally
  // reload the same flow twice (e.g. when FlowProvider notifies after a save).
  String? _loadedFlowId;

  List<CanvasNode> get nodes => _nodes;

  List<CanvasConnection> get connections => _connections;

  String? get tempSourceNodeId => _tempSourceNodeId;

  String? get tempSourceHandle => _tempSourceHandle;

  Offset? get tempDragPosition => _tempDragPosition;

  CanvasMode get canvasMode => _canvasMode;

  String? get selectedSourceNodeId => _selectedSourceNodeId;

  String? get selectedSourceHandle => _selectedSourceHandle;

  bool get isLoading => _isLoading;

  bool get isSaving => _isSaving;

  // ─── Node / Connection mutations ──────────────────────────────────────────

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

  void updateNodeData(String id, Map<String, dynamic> newData) {
    final index = _nodes.indexWhere((n) => n.id == id);
    if (index != -1) {
      final currentData = Map<String, dynamic>.from(_nodes[index].data);
      currentData.addAll(newData);
      _nodes[index] = _nodes[index].copyWith(data: currentData);
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

  // ─── Mode ─────────────────────────────────────────────────────────────────

  void setCanvasMode(CanvasMode mode) {
    _canvasMode = mode;
    _selectedSourceNodeId = null;
    _selectedSourceHandle = null;
    _tempDragPosition = null;
    notifyListeners();
  }

  void selectSourceNode(String nodeId, [String handle = 'default']) {
    if (_canvasMode == CanvasMode.connect) {
      if (_selectedSourceNodeId == nodeId && _selectedSourceHandle == handle) {
        _selectedSourceNodeId = null;
        _selectedSourceHandle = null;
        _tempDragPosition = null;
      } else {
        _selectedSourceNodeId = nodeId;
        _selectedSourceHandle = handle;
      }
      notifyListeners();
    }
  }

  void connectToTarget(String targetNodeId) {
    if (_canvasMode == CanvasMode.connect && _selectedSourceNodeId != null) {
      ConnectionType connType = ConnectionType.defaultType;
      if (_selectedSourceHandle == 'true') connType = ConnectionType.trueType;
      if (_selectedSourceHandle == 'false') connType = ConnectionType.falseType;

      // Remove existing connection from same handle if any
      _connections.removeWhere(
        (c) =>
            c.sourceNodeId == _selectedSourceNodeId &&
            c.sourceHandle == _selectedSourceHandle,
      );

      _connections.add(
        CanvasConnection(
          id: const Uuid().v4(),
          sourceNodeId: _selectedSourceNodeId!,
          targetNodeId: targetNodeId,
          sourceHandle: _selectedSourceHandle ?? 'default',
          type: connType,
        ),
      );

      notifyListeners();
    }
  }

  void updateCursorPosition(Offset pos) {
    if (_canvasMode == CanvasMode.connect && _selectedSourceNodeId != null) {
      _tempDragPosition = pos;
      notifyListeners();
    }
  }

  // ─── Load ─────────────────────────────────────────────────────────────────

  /// Loads the canvas for [flowId]. Safe to call multiple times — if the flow
  /// is already loaded it is a no-op, preventing the canvas from being wiped
  /// whenever FlowProvider notifies (e.g. after a save).
  Future<void> loadFlowLayout(
    String flowId,
    FlowProvider flowProvider, [
    List<domain_endpoint.Endpoint>? endpoints,
  ]) async {
    // Already loaded this flow — do nothing.
    if (_loadedFlowId == flowId && !_isLoading) return;

    _isLoading = true;
    _loadedFlowId = flowId;
    _nodes = [];
    _connections = [];
    notifyListeners();

    try {
      final flow = await flowProvider.getFlow(int.parse(flowId));
      rebuildFromSteps(flow.steps, endpoints, flowProvider.flows);
    } catch (_) {
      // Leave canvas empty on error; caller can show a snackbar if needed.
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Save ─────────────────────────────────────────────────────────────────

  /// Saves the current canvas to the backend.
  ///
  /// Critically, after the API responds we call [rebuildFromSteps] which
  /// re-positions nodes from the server response while preserving the
  /// canvas-position metadata we embedded in [generateFlowConfiguration].
  /// This keeps the canvas stable instead of wiping it.
  Future<void> saveFlowConfiguration(
    int flowId,
    FlowProvider flowProvider, {
    List<domain_endpoint.Endpoint>? endpoints,
    List<Flow>? flows,
  }) async {
    _isSaving = true;
    notifyListeners();

    try {
      final steps = generateFlowConfiguration();
      // configureFlow notifies FlowProvider listeners, but because
      // loadFlowLayout now guards on _loadedFlowId, that notification
      // will NOT trigger a canvas reload.
      final updatedSteps = await flowProvider.configureFlow(flowId, steps);
      // Re-apply server response to keep data in sync without losing positions.
      rebuildFromSteps(updatedSteps, endpoints, flows);
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // ─── Configuration generation ─────────────────────────────────────────────

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
        case FlowNodeType.subflow:
          type = 'SUBFLOW';
          condition = node.data['subflowId']?.toString();
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

      // Embed canvas position so we can restore it after a round-trip.
      Map<String, dynamic> preProcessor = {};
      if (node.data['preProcessor'] != null) {
        preProcessor = Map<String, dynamic>.from(node.data['preProcessor']);
      }
      preProcessor['_canvas_x'] = node.position.dx;
      preProcessor['_canvas_y'] = node.position.dy;
      preProcessor['_temp_sync_id'] = node.id;

      return FlowStep(
        id: node.id,
        type: type,
        endpointId: endpointId,
        nextIfTrue: nextIfTrue,
        nextIfFalse: nextIfFalse,
        condition: condition,
        preProcessor: preProcessor,
        postProcessor: node.data['postProcessor'],
      );
    }).toList();
  }

  // ─── Metadata sync ────────────────────────────────────────────────────────

  /// Called from [_CanvasContentState.didChangeDependencies] whenever the
  /// endpoint list changes. Updates display fields (name, url, type, method)
  /// without touching positions or connections.
  void syncEndpointsMetadata(List<domain_endpoint.Endpoint> endpoints) {
    bool changed = false;
    for (int i = 0; i < _nodes.length; i++) {
      if (_nodes[i].type != FlowNodeType.endpoint) continue;

      final endpointId = _nodes[i].data['id'];
      if (endpointId == null) continue;

      final endpoint = endpoints.where((e) => e.id == endpointId).firstOrNull;
      if (endpoint == null) continue;

      final newData = Map<String, dynamic>.from(_nodes[i].data);
      bool localChanged = false;

      if (newData['name'] != endpoint.name) {
        newData['name'] = endpoint.name;
        localChanged = true;
      }
      if (newData['url'] != endpoint.url) {
        newData['url'] = endpoint.url;
        localChanged = true;
      }
      if (newData['type'] != endpoint.type) {
        newData['type'] = endpoint.type;
        localChanged = true;
      }
      if (newData['method'] != endpoint.httpMethod) {
        newData['method'] = endpoint.httpMethod;
        localChanged = true;
      }

      if (localChanged) {
        _nodes[i] = _nodes[i].copyWith(data: newData);
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  /// Called from [_CanvasContentState.didChangeDependencies] whenever the
  /// flow list changes (e.g. after a rename). Only updates the display name
  /// on subflow nodes.
  void syncFlowsMetadata(List<Flow> flows) {
    bool changed = false;
    for (int i = 0; i < _nodes.length; i++) {
      if (_nodes[i].type != FlowNodeType.subflow) continue;

      final subflowId = _nodes[i].data['subflowId'];
      if (subflowId == null) continue;

      final flow = flows
          .where((f) => f.id.toString() == subflowId.toString())
          .firstOrNull;
      if (flow == null) continue;

      final newData = Map<String, dynamic>.from(_nodes[i].data);
      if (newData['flowName'] != flow.name) {
        newData['flowName'] = flow.name;
        _nodes[i] = _nodes[i].copyWith(data: newData);
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  // ─── Rebuild from server steps ────────────────────────────────────────────

  void rebuildFromSteps(
    List<FlowStep> steps, [
    List<domain_endpoint.Endpoint>? endpoints,
    List<Flow>? flows,
  ]) {
    // Preserve current positions so a save round-trip doesn't jump nodes.
    final Map<String, Offset> oldPositions = {
      for (var node in _nodes) node.id: node.position,
    };

    _nodes.clear();
    _connections.clear();

    if (steps.isEmpty) {
      notifyListeners();
      return;
    }

    const double startX = 100.0;
    const double startY = 100.0;
    const double spacingX = 250.0;
    const double spacingY = 150.0;

    for (int i = 0; i < steps.length; i++) {
      final step = steps[i];
      FlowNodeType type;
      switch (step.type) {
        case 'START': 
          type = FlowNodeType.start; 
          break;
        case 'BRANCH': 
          type = FlowNodeType.branch; 
          break;
        case 'SUBFLOW': 
          type = FlowNodeType.subflow; 
          break;
        default: 
          type = FlowNodeType.endpoint;
      }

      // Position priority: saved in preProcessor > old in-memory > grid default
      final double? savedX = (step.preProcessor?['_canvas_x'] as num?)
          ?.toDouble();
      final double? savedY = (step.preProcessor?['_canvas_y'] as num?)
          ?.toDouble();

      final double x =
          savedX ?? oldPositions[step.id]?.dx ?? (startX + (i % 4) * spacingX);
      final double y =
          savedY ?? oldPositions[step.id]?.dy ?? (startY + (i ~/ 4) * spacingY);

      Map<String, dynamic> nodeData = {
        if (step.endpointId != null) 'id': step.endpointId,
        if (step.condition != null)
          (type == FlowNodeType.subflow ? 'subflowId' : 'condition'):
              step.condition,
        if (step.preProcessor != null) 'preProcessor': step.preProcessor,
        if (step.postProcessor != null) 'postProcessor': step.postProcessor,
      };

      // Enrich endpoint nodes with live metadata.
      if (step.endpointId != null && endpoints != null) {
        final endpoint = endpoints
            .where((e) => e.id == step.endpointId)
            .firstOrNull;
        if (endpoint != null) {
          nodeData['name'] = endpoint.name;
          nodeData['url'] = endpoint.url;
          nodeData['type'] = endpoint.type;
          nodeData['method'] = endpoint.httpMethod;
        }
      }

      // Enrich subflow nodes with their display name.
      if (type == FlowNodeType.subflow &&
          step.condition != null &&
          flows != null) {
        final flow = flows
            .where((f) => f.id.toString() == step.condition.toString())
            .firstOrNull;
        if (flow != null) {
          nodeData['flowName'] = flow.name;
        }
      }

      _nodes.add(
        CanvasNode(
          id: step.id,
          type: type,
          position: Offset(x, y),
          data: nodeData,
          width: type == FlowNodeType.start
              ? 48
              : (type == FlowNodeType.branch
                    ? 120
                    : (type == FlowNodeType.subflow ? 180 : 160)),
          height: type == FlowNodeType.start
              ? 48
              : (type == FlowNodeType.branch
                    ? 120
                    : (type == FlowNodeType.subflow ? 64 : 100)),
        ),
      );
    }

    // Rebuild connections.
    for (var step in steps) {
      if (step.nextIfTrue != null &&
          _nodes.any((n) => n.id == step.nextIfTrue)) {
        _connections.add(
          CanvasConnection(
            id: const Uuid().v4(),
            sourceNodeId: step.id,
            targetNodeId: step.nextIfTrue!,
            sourceHandle: step.type == 'BRANCH' ? 'true' : 'default',
            type: step.type == 'BRANCH'
                ? ConnectionType.trueType
                : ConnectionType.defaultType,
          ),
        );
      }
      if (step.nextIfFalse != null &&
          step.type == 'BRANCH' &&
          _nodes.any((n) => n.id == step.nextIfFalse)) {
        _connections.add(
          CanvasConnection(
            id: const Uuid().v4(),
            sourceNodeId: step.id,
            targetNodeId: step.nextIfFalse!,
            sourceHandle: 'false',
            type: ConnectionType.falseType,
          ),
        );
      }
    }

    notifyListeners();
  }

  // ─── Misc ─────────────────────────────────────────────────────────────────

  Future<void> saveFlowLayout(String flowId, {bool silent = false}) async {
    return;
  }

  void syncWithBackend(
    List<FlowStep> responseSteps, [
    List<domain_endpoint.Endpoint>? endpoints,
    List<Flow>? flows,
  ]) {
    rebuildFromSteps(responseSteps, endpoints, flows);
  }

  void applyConfiguration(List<FlowStep> steps) {
    for (var step in steps) {
      final index = _nodes.indexWhere((n) => n.id == step.id);
      if (index != -1) {
        final node = _nodes[index];
        final Map<String, dynamic> newData = Map.from(node.data);
        if (step.preProcessor != null) {
          newData['preProcessor'] = step.preProcessor;
        }
        if (step.postProcessor != null) {
          newData['postProcessor'] = step.postProcessor;
        }
        if (node.type == FlowNodeType.branch && step.condition != null) {
          newData['condition'] = step.condition;
        }
        if (node.type == FlowNodeType.subflow && step.condition != null) {
          newData['subflowId'] = step.condition;
        }
        _nodes[index] = node.copyWith(data: newData);
      }
    }

    _connections.clear();
    for (var step in steps) {
      if (step.nextIfTrue != null &&
          _nodes.any((n) => n.id == step.nextIfTrue)) {
        final isBranch = _nodes.any(
          (n) => n.id == step.id && n.type == FlowNodeType.branch,
        );
        _connections.add(
          CanvasConnection(
            id: const Uuid().v4(),
            sourceNodeId: step.id,
            targetNodeId: step.nextIfTrue!,
            sourceHandle: isBranch ? 'true' : 'default',
            type: isBranch
                ? ConnectionType.trueType
                : ConnectionType.defaultType,
          ),
        );
      }
      if (step.nextIfFalse != null &&
          _nodes.any((n) => n.id == step.nextIfFalse)) {
        _connections.add(
          CanvasConnection(
            id: const Uuid().v4(),
            sourceNodeId: step.id,
            targetNodeId: step.nextIfFalse!,
            sourceHandle: 'false',
            type: ConnectionType.falseType,
          ),
        );
      }
    }
    notifyListeners();
  }
}
