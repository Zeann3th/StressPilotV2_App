import 'package:flutter/material.dart' hide Flow;
import 'package:stress_pilot/features/projects/domain/models/flow.dart';
import 'package:stress_pilot/features/projects/presentation/provider/flow_provider.dart';
import 'package:stress_pilot/features/endpoints/domain/models/endpoint.dart' as domain_endpoint;
import 'package:uuid/uuid.dart';

import 'package:stress_pilot/features/workspace/domain/models/canvas.dart';

enum CanvasMode { move, connect }

enum ConnectionLineStyle { straight, curved, orthogonal }

class CanvasProvider extends ChangeNotifier {
  List<CanvasNode> _nodes = [];
  List<CanvasConnection> _connections = [];

  CanvasMode _canvasMode = CanvasMode.move;
  String? _selectedNodeId;
  String? _selectedSourceNodeId;
  String? _selectedSourceHandle;
  Offset? _tempEndPos;

  bool _isLoading = false;
  bool _isSaving = false;
  bool _isLocked = false;

  ConnectionLineStyle _lineStyle = ConnectionLineStyle.curved;

  String? _loadedFlowId;

  List<CanvasNode> get nodes => _nodes;
  List<CanvasConnection> get connections => _connections;

  CanvasMode get canvasMode => _canvasMode;
  String? get selectedNodeId => _selectedNodeId;
  String? get selectedSourceNodeId => _selectedSourceNodeId;
  String? get selectedSourceHandle => _selectedSourceHandle;
  Offset? get tempEndPos => _tempEndPos;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isLocked => _isLocked;
  ConnectionLineStyle get lineStyle => _lineStyle;

  void cycleLineStyle() {
    final styles = ConnectionLineStyle.values;
    _lineStyle = styles[(styles.indexOf(_lineStyle) + 1) % styles.length];
    notifyListeners();
  }

  void setTempEndPos(Offset? pos) {
    _tempEndPos = pos;
    notifyListeners();
  }

  void toggleLock() {
    _isLocked = !_isLocked;
    notifyListeners();
  }

  void selectNode(String? nodeId) {
    if (_isLocked) return;
    _selectedNodeId = nodeId;
    notifyListeners();
  }

  void addNode(CanvasNode node) {
    if (_isLocked) return;
    _nodes.add(node);
    notifyListeners();
  }

  void updateNodePosition(String id, Offset newPos) {
    if (_isLocked) return;
    final index = _nodes.indexWhere((n) => n.id == id);
    if (index != -1) {
      _nodes[index] = _nodes[index].copyWith(position: newPos);
      notifyListeners();
    }
  }

  void updateNodeData(String id, Map<String, dynamic> newData) {
    if (_isLocked) return;
    final index = _nodes.indexWhere((n) => n.id == id);
    if (index != -1) {
      final merged = Map<String, dynamic>.from(_nodes[index].data)
        ..addAll(newData);
      _nodes[index] = _nodes[index].copyWith(data: merged);
      notifyListeners();
    }
  }

  void removeNode(String id) {
    if (_isLocked) return;
    _nodes.removeWhere((n) => n.id == id);
    _connections.removeWhere(
            (c) => c.sourceNodeId == id || c.targetNodeId == id);
    if (_selectedNodeId == id) _selectedNodeId = null;
    if (_selectedSourceNodeId == id) _selectedSourceNodeId = null;
    notifyListeners();
  }

  void removeConnection(String connectionId) {
    if (_isLocked) return;
    _connections.removeWhere((c) => c.id == connectionId);
    notifyListeners();
  }

  void clearCanvas() {
    if (_isLocked) return;
    _nodes.clear();
    _connections.clear();
    _selectedNodeId = null;
    _selectedSourceNodeId = null;
    notifyListeners();
  }

  void setCanvasMode(CanvasMode mode) {
    if (_isLocked && mode == CanvasMode.connect) return;
    _canvasMode = mode;
    _selectedNodeId = null;
    _selectedSourceNodeId = null;
    _selectedSourceHandle = null;
    _tempEndPos = null;
    notifyListeners();
  }

  void selectSourceNode(String nodeId, [String handle = 'default']) {
    if (_isLocked || _canvasMode != CanvasMode.connect) return;
    if (_selectedSourceNodeId == nodeId && _selectedSourceHandle == handle) {
      _selectedSourceNodeId = null;
      _selectedSourceHandle = null;
      _tempEndPos = null;
    } else {
      _selectedSourceNodeId = nodeId;
      _selectedSourceHandle = handle;
    }
    notifyListeners();
  }

  void connectToTarget(String targetNodeId) {
    if (_isLocked || _canvasMode != CanvasMode.connect || _selectedSourceNodeId == null) {
      return;
    }

    ConnectionType connType = ConnectionType.defaultType;
    if (_selectedSourceHandle == 'true') connType = ConnectionType.trueType;
    if (_selectedSourceHandle == 'false') connType = ConnectionType.falseType;

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

    _selectedSourceNodeId = null;
    _selectedSourceHandle = null;
    _tempEndPos = null;
    notifyListeners();
  }

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

    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveFlowConfiguration(
      int flowId,
      FlowProvider flowProvider, {
        List<domain_endpoint.Endpoint>? endpoints,
        List<Flow>? flows,
      }) async {
    _isSaving = true;
    notifyListeners();

    final snapshotNodes = List<CanvasNode>.from(_nodes);
    final snapshotConnections = List<CanvasConnection>.from(_connections);

    try {
      final steps = generateFlowConfiguration();
      final updatedSteps =
      await flowProvider.configureFlow(flowId, steps);

      rebuildFromSteps(updatedSteps, endpoints, flows);
    } catch (e) {

      _nodes = snapshotNodes;
      _connections = snapshotConnections;
      notifyListeners();
      rethrow;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

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

      Map<String, dynamic>? preProcessor;
      preProcessor = node.data['preProcessor'] != null
          ? Map<String, dynamic>.from(node.data['preProcessor'])
          : {};

      if (node.type == FlowNodeType.endpoint) {
        preProcessor['endpoint_id'] = endpointId;
        preProcessor['endpoint_name'] = node.data['name'];
        preProcessor['endpoint_url'] = node.data['url'];
        preProcessor['endpoint_type'] = node.data['type'];
        preProcessor['endpoint_method'] = node.data['method'];
      }

      preProcessor['location'] = {
        'x': node.position.dx,
        'y': node.position.dy,
      };
      preProcessor['temp_sync_id'] = node.id;

      return FlowStep(
        id: node.id,
        type: type,
        endpointId: endpointId,
        endpointName: node.data['name'],
        endpointUrl: node.data['url'],
        endpointType: node.data['type'],
        endpointMethod: node.data['method'],
        nextIfTrue: nextIfTrue,
        nextIfFalse: nextIfFalse,
        condition: condition,
        preProcessor: preProcessor,
        postProcessor: node.data['postProcessor'],
      );
    }).toList();
  }

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

    const double startX = 3800.0;
    const double startY = 3800.0;
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

      final dynamic loc = step.preProcessor?['location'];
      final String? tempSyncId = step.preProcessor?['temp_sync_id']?.toString();

      double? savedX;
      double? savedY;

      if (loc is Map) {
        savedX = (loc['x'] as num?)?.toDouble();
        savedY = (loc['y'] as num?)?.toDouble();
      }

      savedX ??= (step.preProcessor?['_canvas_x'] as num?)?.toDouble();
      savedY ??= (step.preProcessor?['_canvas_y'] as num?)?.toDouble();

      final double x = savedX ??
          (tempSyncId != null ? oldPositions[tempSyncId]?.dx : null) ??
          oldPositions[step.id]?.dx ??
          (startX + (i % 4) * spacingX);
      final double y = savedY ??
          (tempSyncId != null ? oldPositions[tempSyncId]?.dy : null) ??
          oldPositions[step.id]?.dy ??
          (startY + (i ~/ 4) * spacingY);

      Map<String, dynamic> nodeData = {};

      if (step.endpointId != null) {
        nodeData['id'] = step.endpointId;
      }
      if (step.condition != null) {
        nodeData[type == FlowNodeType.subflow ? 'subflowId' : 'condition'] =
            step.condition;
      }
      if (step.preProcessor != null) nodeData['preProcessor'] = step.preProcessor;
      if (step.postProcessor != null) nodeData['postProcessor'] = step.postProcessor;

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

      if (step.preProcessor != null) {
        final existingPre = newData['preProcessor'] as Map<String, dynamic>? ?? {};
        newData['preProcessor'] = Map<String, dynamic>.from(existingPre)
          ..addAll(step.preProcessor!);
      }
      if (step.postProcessor != null) {
        final existingPost = newData['postProcessor'] as Map<String, dynamic>? ?? {};
        newData['postProcessor'] = Map<String, dynamic>.from(existingPost)
          ..addAll(step.postProcessor!);
      }
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
