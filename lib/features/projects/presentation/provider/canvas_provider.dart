import 'package:flutter/material.dart' hide Flow;
import 'package:stress_pilot/core/domain/entities/flow.dart';
import 'package:stress_pilot/features/projects/presentation/provider/flow_provider.dart';
import 'package:stress_pilot/core/domain/entities/endpoint.dart' as domain_endpoint;
import 'package:uuid/uuid.dart';

import '../../../../core/domain/entities/canvas.dart';


enum CanvasMode { move, connect }

class CanvasProvider extends ChangeNotifier {
  List<CanvasNode> _nodes = [];
  List<CanvasConnection> _connections = [];

  CanvasMode _canvasMode = CanvasMode.move;
  String? _selectedSourceNodeId;
  String? _selectedSourceHandle;

  bool _isLoading = false;
  bool _isSaving = false;

  /// Tracks the flow that is currently loaded so loadFlowLayout never
  /// wipes the canvas on a redundant call (e.g. triggered by a save notify).
  String? _loadedFlowId;

  List<CanvasNode> get nodes => _nodes;
  List<CanvasConnection> get connections => _connections;

  CanvasMode get canvasMode => _canvasMode;
  String? get selectedSourceNodeId => _selectedSourceNodeId;
  String? get selectedSourceHandle => _selectedSourceHandle;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;

  // ─── Node / connection mutations ──────────────────────────────────────────

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
      final merged = Map<String, dynamic>.from(_nodes[index].data)
        ..addAll(newData);
      _nodes[index] = _nodes[index].copyWith(data: merged);
      notifyListeners();
    }
  }

  void removeNode(String id) {
    _nodes.removeWhere((n) => n.id == id);
    _connections.removeWhere(
            (c) => c.sourceNodeId == id || c.targetNodeId == id);
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
    notifyListeners();
  }

  void selectSourceNode(String nodeId, [String handle = 'default']) {
    if (_canvasMode != CanvasMode.connect) return;
    if (_selectedSourceNodeId == nodeId && _selectedSourceHandle == handle) {
      _selectedSourceNodeId = null;
      _selectedSourceHandle = null;
    } else {
      _selectedSourceNodeId = nodeId;
      _selectedSourceHandle = handle;
    }
    notifyListeners();
  }

  void connectToTarget(String targetNodeId) {
    if (_canvasMode != CanvasMode.connect || _selectedSourceNodeId == null) {
      return;
    }

    ConnectionType connType = ConnectionType.defaultType;
    if (_selectedSourceHandle == 'true') connType = ConnectionType.trueType;
    if (_selectedSourceHandle == 'false') connType = ConnectionType.falseType;

    // Remove any existing connection from the same handle.
    _connections.removeWhere((c) =>
    c.sourceNodeId == _selectedSourceNodeId &&
        c.sourceHandle == _selectedSourceHandle);

    _connections.add(CanvasConnection(
      id: const Uuid().v4(),
      sourceNodeId: _selectedSourceNodeId!,
      targetNodeId: targetNodeId,
      sourceHandle: _selectedSourceHandle ?? 'default',
      type: connType,
    ));

    notifyListeners();
  }

  // ─── Load ─────────────────────────────────────────────────────────────────

  /// Loads the canvas for [flowId]. Idempotent — if this flow is already
  /// loaded it returns immediately so FlowProvider save-notifications do
  /// not wipe the canvas.
  Future<void> loadFlowLayout(
      String flowId,
      FlowProvider flowProvider, [
        List<domain_endpoint.Endpoint>? endpoints,
      ]) async {
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
      // Leave canvas empty on error.
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Save ─────────────────────────────────────────────────────────────────

  /// Saves the canvas to the backend.
  ///
  /// Key rules that match the backend's `configureFlow` validation:
  ///   1. Exactly one START node is required.
  ///   2. Every non-terminal node must eventually reach an ENDPOINT or SUBFLOW.
  ///   3. Canvas positions are embedded in preProcessor only for non-START nodes
  ///      so they survive the round-trip without polluting the START step.
  ///
  /// We snapshot the current canvas before the API call so we can restore it
  /// if the call fails, preventing the canvas from going blank on a bad save.
  Future<void> saveFlowConfiguration(
      int flowId,
      FlowProvider flowProvider, {
        List<domain_endpoint.Endpoint>? endpoints,
        List<Flow>? flows,
      }) async {
    _isSaving = true;
    notifyListeners();

    // Snapshot so we can roll back if the backend rejects the configuration.
    final snapshotNodes = List<CanvasNode>.from(_nodes);
    final snapshotConnections = List<CanvasConnection>.from(_connections);

    try {
      final steps = generateFlowConfiguration();
      final updatedSteps =
      await flowProvider.configureFlow(flowId, steps);
      // Rebuild from the server response to stay in sync, preserving positions.
      rebuildFromSteps(updatedSteps, endpoints, flows);
    } catch (e) {
      // Restore the canvas snapshot so the user does not lose their work.
      _nodes = snapshotNodes;
      _connections = snapshotConnections;
      notifyListeners();
      rethrow;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // ─── Configuration generation ─────────────────────────────────────────────

  /// Converts the current canvas to [FlowStep] objects for the backend.
  ///
  /// Canvas position metadata (_canvas_x / _canvas_y) is stored in
  /// preProcessor for ENDPOINT, BRANCH, and SUBFLOW nodes only.
  /// START nodes must not carry preProcessor data because the backend
  /// `detectInfiniteLoop` marks any START with no outgoing connections
  /// as an invalid terminal node — adding preProcessor does not change that
  /// logic, but keeping START clean avoids any future backend issues.
  ///
  /// IMPORTANT: The backend requires that every non-terminal node eventually
  /// reaches an ENDPOINT or SUBFLOW terminal. A canvas with only a START node
  /// and no connections will be rejected with ER0004. The UI should warn the
  /// user before saving such a configuration.
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

      for (final conn
      in _connections.where((c) => c.sourceNodeId == node.id)) {
        if (node.type == FlowNodeType.branch) {
          if (conn.sourceHandle == 'true') nextIfTrue = conn.targetNodeId;
          if (conn.sourceHandle == 'false') nextIfFalse = conn.targetNodeId;
        } else {
          nextIfTrue = conn.targetNodeId;
        }
      }

      // Embed canvas coordinates in preProcessor so positions survive a
      // save → load round-trip.  We skip this for START nodes: they have
      // no preProcessor semantics and keeping them null avoids sending
      // unexpected data to the backend for a node type that is only a
      // graph anchor.
      Map<String, dynamic>? preProcessor;
      if (node.type != FlowNodeType.start) {
        preProcessor = node.data['preProcessor'] != null
            ? Map<String, dynamic>.from(node.data['preProcessor'])
            : {};
        preProcessor['_canvas_x'] = node.position.dx;
        preProcessor['_canvas_y'] = node.position.dy;
      }

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

  /// Updates display fields on endpoint nodes when the endpoint list changes.
  /// Never touches positions or connections.
  void syncEndpointsMetadata(List<domain_endpoint.Endpoint> endpoints) {
    bool changed = false;
    for (int i = 0; i < _nodes.length; i++) {
      if (_nodes[i].type != FlowNodeType.endpoint) continue;
      final endpointId = _nodes[i].data['id'];
      if (endpointId == null) continue;

      final endpoint =
          endpoints.where((e) => e.id == endpointId).firstOrNull;
      if (endpoint == null) continue;

      final newData = Map<String, dynamic>.from(_nodes[i].data);
      bool dirty = false;

      void sync(String key, dynamic value) {
        if (newData[key] != value) {
          newData[key] = value;
          dirty = true;
        }
      }

      sync('name', endpoint.name);
      sync('url', endpoint.url);
      sync('type', endpoint.type);
      sync('method', endpoint.httpMethod);

      if (dirty) {
        _nodes[i] = _nodes[i].copyWith(data: newData);
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  /// Updates display names on subflow nodes when the flow list changes.
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

  /// Rebuilds the canvas from a list of [FlowStep] objects returned by the
  /// backend.  Positions are recovered in this priority order:
  ///   1. `_canvas_x` / `_canvas_y` embedded in preProcessor (round-trip)
  ///   2. Current in-memory position (user moved node since last load)
  ///   3. Auto-layout grid (new node with no position history)
  void rebuildFromSteps(
      List<FlowStep> steps, [
        List<domain_endpoint.Endpoint>? endpoints,
        List<Flow>? flows,
      ]) {
    final Map<String, Offset> oldPositions = {
      for (final node in _nodes) node.id: node.position,
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
      switch (step.type.toUpperCase()) {
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

      // Recover saved canvas position from preProcessor metadata.
      final double? savedX =
      (step.preProcessor?['_canvas_x'] as num?)?.toDouble();
      final double? savedY =
      (step.preProcessor?['_canvas_y'] as num?)?.toDouble();

      final double x = savedX ??
          oldPositions[step.id]?.dx ??
          (startX + (i % 4) * spacingX);
      final double y = savedY ??
          oldPositions[step.id]?.dy ??
          (startY + (i ~/ 4) * spacingY);

      Map<String, dynamic> nodeData = {};

      if (step.endpointId != null) nodeData['id'] = step.endpointId;
      if (step.condition != null) {
        nodeData[type == FlowNodeType.subflow ? 'subflowId' : 'condition'] =
            step.condition;
      }
      if (step.preProcessor != null) nodeData['preProcessor'] = step.preProcessor;
      if (step.postProcessor != null) nodeData['postProcessor'] = step.postProcessor;

      // Enrich endpoint nodes with display metadata.
      // Priority:
      //   1. Inline fields on FlowStep — backend returns a full nested endpoint
      //      object, so FlowStep.fromJson parses name/url/type/method directly.
      //      Always available right after save/load, no endpoint list needed.
      //   2. Live endpoint list — fallback for first load or missing inline data.
      if (type == FlowNodeType.endpoint) {
        if (step.endpointName != null) {
          nodeData['name']   = step.endpointName;
          nodeData['url']    = step.endpointUrl;
          nodeData['type']   = step.endpointType;
          nodeData['method'] = step.endpointMethod;
        } else if (step.endpointId != null && endpoints != null) {
          final endpoint =
              endpoints.where((e) => e.id == step.endpointId).firstOrNull;
          if (endpoint != null) {
            nodeData['name']   = endpoint.name;
            nodeData['url']    = endpoint.url;
            nodeData['type']   = endpoint.type;
            nodeData['method'] = endpoint.httpMethod;
          }
        }
      }

      // Enrich subflow nodes with their display name.
      if (type == FlowNodeType.subflow &&
          step.condition != null &&
          flows != null) {
        final flow = flows
            .where((f) => f.id.toString() == step.condition.toString())
            .firstOrNull;
        if (flow != null) nodeData['flowName'] = flow.name;
      }

      _nodes.add(CanvasNode(
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
      ));
    }

    // Rebuild connections from nextIfTrue / nextIfFalse references.
    for (final step in steps) {
      if (step.nextIfTrue != null &&
          _nodes.any((n) => n.id == step.nextIfTrue)) {
        _connections.add(CanvasConnection(
          id: const Uuid().v4(),
          sourceNodeId: step.id,
          targetNodeId: step.nextIfTrue!,
          sourceHandle: step.type.toUpperCase() == 'BRANCH' ? 'true' : 'default',
          type: step.type.toUpperCase() == 'BRANCH'
              ? ConnectionType.trueType
              : ConnectionType.defaultType,
        ));
      }
      if (step.nextIfFalse != null &&
          step.type.toUpperCase() == 'BRANCH' &&
          _nodes.any((n) => n.id == step.nextIfFalse)) {
        _connections.add(CanvasConnection(
          id: const Uuid().v4(),
          sourceNodeId: step.id,
          targetNodeId: step.nextIfFalse!,
          sourceHandle: 'false',
          type: ConnectionType.falseType,
        ));
      }
    }

    notifyListeners();
  }

  // ─── Misc ─────────────────────────────────────────────────────────────────

  Future<void> saveFlowLayout(String flowId, {bool silent = false}) async {}

  void syncWithBackend(
      List<FlowStep> responseSteps, [
        List<domain_endpoint.Endpoint>? endpoints,
        List<Flow>? flows,
      ]) {
    rebuildFromSteps(responseSteps, endpoints, flows);
  }

  void applyConfiguration(List<FlowStep> steps) {
    for (final step in steps) {
      final index = _nodes.indexWhere((n) => n.id == step.id);
      if (index == -1) continue;

      final node = _nodes[index];
      final newData = Map<String, dynamic>.from(node.data);

      if (step.preProcessor != null) newData['preProcessor'] = step.preProcessor;
      if (step.postProcessor != null) newData['postProcessor'] = step.postProcessor;
      if (node.type == FlowNodeType.branch && step.condition != null) {
        newData['condition'] = step.condition;
      }
      if (node.type == FlowNodeType.subflow && step.condition != null) {
        newData['subflowId'] = step.condition;
      }

      _nodes[index] = node.copyWith(data: newData);
    }

    _connections.clear();
    for (final step in steps) {
      if (step.nextIfTrue != null &&
          _nodes.any((n) => n.id == step.nextIfTrue)) {
        final isBranch = _nodes
            .any((n) => n.id == step.id && n.type == FlowNodeType.branch);
        _connections.add(CanvasConnection(
          id: const Uuid().v4(),
          sourceNodeId: step.id,
          targetNodeId: step.nextIfTrue!,
          sourceHandle: isBranch ? 'true' : 'default',
          type: isBranch ? ConnectionType.trueType : ConnectionType.defaultType,
        ));
      }
      if (step.nextIfFalse != null &&
          _nodes.any((n) => n.id == step.nextIfFalse)) {
        _connections.add(CanvasConnection(
          id: const Uuid().v4(),
          sourceNodeId: step.id,
          targetNodeId: step.nextIfFalse!,
          sourceHandle: 'false',
          type: ConnectionType.falseType,
        ));
      }
    }

    notifyListeners();
  }
}