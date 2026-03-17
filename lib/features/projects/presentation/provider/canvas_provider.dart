import 'package:flutter/material.dart' hide Flow;
import 'package:graphview/graphview.dart' as gv;
import 'package:stress_pilot/features/projects/domain/flow.dart';
import 'package:stress_pilot/features/projects/presentation/provider/flow_provider.dart';
import 'package:stress_pilot/features/endpoints/domain/endpoint.dart' as domain_endpoint;
import 'package:uuid/uuid.dart';

import '../../domain/canvas.dart';

enum CanvasMode { move, connect }

class CanvasProvider extends ChangeNotifier {
  List<CanvasNode> _nodes = [];
  List<CanvasConnection> _connections = [];
  final gv.Graph graph = gv.Graph();

  String? _tempSourceNodeId;
  String? _tempSourceHandle;
  Offset? _tempDragPosition;

  CanvasMode _canvasMode = CanvasMode.move;
  String? _selectedSourceNodeId;
  String? _selectedSourceHandle;

  bool _isLoading = false;
  bool _isSaving = false;

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

  void addNode(CanvasNode node) {
    _nodes.add(node);
    _syncGraph();
    notifyListeners();
  }

  void _syncGraph() {
    graph.nodes.clear();
    graph.edges.clear();

    final gvNodes = <String, gv.Node>{};
    for (final node in _nodes) {
      final gvNode = node.toGraphNode();
      gvNodes[node.id] = gvNode;
      graph.addNode(gvNode);
    }

    for (final conn in _connections) {
      final source = gvNodes[conn.sourceNodeId];
      final target = gvNodes[conn.targetNodeId];
      if (source != null && target != null) {
        graph.addEdge(source, target);
      }
    }
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
    _syncGraph();
    notifyListeners();
  }

  void removeConnection(String connectionId) {
    _connections.removeWhere((c) => c.id == connectionId);
    _syncGraph();
    notifyListeners();
  }

  void clearCanvas() {
    _nodes.clear();
    _connections.clear();
    _syncGraph();
    notifyListeners();
  }

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

      _syncGraph();
      notifyListeners();
    }
  }

  void updateCursorPosition(Offset pos) {
    if (_canvasMode == CanvasMode.connect && _selectedSourceNodeId != null) {
      _tempDragPosition = pos;
      notifyListeners();
    }
  }

  Future<void> saveFlowLayout(String flowId, {bool silent = false}) async {
    return;
  }

  Future<void> loadFlowLayout(String flowId) async {
    _isLoading = true;
    _nodes = [];
    _connections = [];
    _syncGraph();
    notifyListeners();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> saveFlowConfiguration(
    int flowId,
    FlowProvider flowProvider,
  ) async {
    _isSaving = true;
    notifyListeners();

    try {
      final steps = generateFlowConfiguration();
      final updatedSteps = await flowProvider.configureFlow(flowId, steps);
      rebuildFromSteps(updatedSteps);
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

      Map<String, dynamic> preProcessor = {};
      if (node.data['preProcessor'] != null) {
        preProcessor = Map<String, dynamic>.from(node.data['preProcessor']);
      }
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

  void syncEndpointsMetadata(List<domain_endpoint.Endpoint> endpoints) {
    bool changed = false;
    for (int i = 0; i < _nodes.length; i++) {
      if (_nodes[i].type == FlowNodeType.endpoint) {
        final endpointId = _nodes[i].data['id'];
        if (endpointId != null) {
          final endpoint = endpoints.where((e) => e.id == endpointId).firstOrNull;
          if (endpoint != null) {
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
        }
      }
    }
    if (changed) notifyListeners();
  }

  void syncFlowsMetadata(List<Flow> flows) {
    bool changed = false;
    for (int i = 0; i < _nodes.length; i++) {
      if (_nodes[i].type == FlowNodeType.subflow) {
        final subflowId = _nodes[i].data['subflowId'];
        if (subflowId != null) {
          final flow = flows.where((f) => f.id.toString() == subflowId.toString()).firstOrNull;
          if (flow != null) {
            final newData = Map<String, dynamic>.from(_nodes[i].data);
            if (newData['flowName'] != flow.name) {
              newData['flowName'] = flow.name;
              _nodes[i] = _nodes[i].copyWith(data: newData);
              changed = true;
            }
          }
        }
      }
    }
    if (changed) notifyListeners();
  }

  void rebuildFromSteps(List<FlowStep> steps, [List<domain_endpoint.Endpoint>? endpoints, List<Flow>? flows]) {
    _nodes.clear();
    _connections.clear();

    if (steps.isEmpty) {
      _syncGraph();
      notifyListeners();
      return;
    }

    double startX = 100.0;
    double startY = 100.0;
    double spacingX = 250.0;
    double spacingY = 150.0;

    for (int i = 0; i < steps.length; i++) {
      final step = steps[i];
      FlowNodeType type;
      switch (step.type) {
        case 'START': type = FlowNodeType.start; break;
        case 'BRANCH': type = FlowNodeType.branch; break;
        case 'SUBFLOW': type = FlowNodeType.subflow; break;
        default: type = FlowNodeType.endpoint;
      }

      double x = startX + (i % 4) * spacingX;
      double y = startY + (i ~/ 4) * spacingY;

      Map<String, dynamic> nodeData = {
        if (step.endpointId != null) 'id': step.endpointId,
        if (step.condition != null) 
          type == FlowNodeType.subflow ? 'subflowId' : 'condition': step.condition,
        if (step.preProcessor != null) 'preProcessor': step.preProcessor,
        if (step.postProcessor != null) 'postProcessor': step.postProcessor,
      };

      if (step.endpointId != null && endpoints != null) {
        final endpoint = endpoints.where((e) => e.id == step.endpointId).firstOrNull;
        if (endpoint != null) {
          nodeData['name'] = endpoint.name;
          nodeData['url'] = endpoint.url;
          nodeData['type'] = endpoint.type;
          nodeData['method'] = endpoint.httpMethod;
        }
      }

      if (type == FlowNodeType.subflow && step.condition != null && flows != null) {
        final flow = flows.where((f) => f.id.toString() == step.condition.toString()).firstOrNull;
        if (flow != null) {
          nodeData['flowName'] = flow.name;
        }
      }

      final node = CanvasNode(
        id: step.id,
        type: type,
        position: Offset(x, y),
        data: nodeData,
        width: type == FlowNodeType.start ? 48 : (type == FlowNodeType.branch ? 80 : (type == FlowNodeType.subflow ? 180 : 160)),
        height: type == FlowNodeType.start ? 48 : (type == FlowNodeType.branch ? 80 : (type == FlowNodeType.subflow ? 64 : 90)),
      );
      _nodes.add(node);
    }

    for (var step in steps) {
      if (step.nextIfTrue != null) {
        if (_nodes.any((n) => n.id == step.nextIfTrue)) {
          _connections.add(CanvasConnection(
            id: const Uuid().v4(),
            sourceNodeId: step.id,
            targetNodeId: step.nextIfTrue!,
            sourceHandle: step.type == 'BRANCH' ? 'true' : 'default',
            type: step.type == 'BRANCH' ? ConnectionType.trueType : ConnectionType.defaultType,
          ));
        }
      }
      if (step.nextIfFalse != null && step.type == 'BRANCH') {
        if (_nodes.any((n) => n.id == step.nextIfFalse)) {
          _connections.add(CanvasConnection(
            id: const Uuid().v4(),
            sourceNodeId: step.id,
            targetNodeId: step.nextIfFalse!,
            sourceHandle: 'false',
            type: ConnectionType.falseType,
          ));
        }
      }
    }

    _syncGraph();
    notifyListeners();
  }

  void syncWithBackend(List<FlowStep> responseSteps, [List<domain_endpoint.Endpoint>? endpoints, List<Flow>? flows]) {
    rebuildFromSteps(responseSteps, endpoints, flows);
  }

  void applyConfiguration(List<FlowStep> steps) {
    for (var step in steps) {
      final index = _nodes.indexWhere((n) => n.id == step.id);
      if (index != -1) {
        final node = _nodes[index];
        final Map<String, dynamic> newData = Map.from(node.data);
        if (step.preProcessor != null) newData['preProcessor'] = step.preProcessor;
        if (step.postProcessor != null) newData['postProcessor'] = step.postProcessor;
        if (node.type == FlowNodeType.branch && step.condition != null) newData['condition'] = step.condition;
        if (node.type == FlowNodeType.subflow && step.condition != null) newData['subflowId'] = step.condition;
        _nodes[index] = node.copyWith(data: newData);
      }
    }

    _connections.clear();
    for (var step in steps) {
      if (step.nextIfTrue != null && _nodes.any((n) => n.id == step.nextIfTrue)) {
        final isBranch = _nodes.any((n) => n.id == step.id && n.type == FlowNodeType.branch);
        _connections.add(CanvasConnection(
          id: const Uuid().v4(),
          sourceNodeId: step.id,
          targetNodeId: step.nextIfTrue!,
          sourceHandle: isBranch ? 'true' : 'default',
          type: isBranch ? ConnectionType.trueType : ConnectionType.defaultType,
        ));
      }
      if (step.nextIfFalse != null && _nodes.any((n) => n.id == step.nextIfFalse)) {
        _connections.add(CanvasConnection(
          id: const Uuid().v4(),
          sourceNodeId: step.id,
          targetNodeId: step.nextIfFalse!,
          sourceHandle: 'false',
          type: ConnectionType.falseType,
        ));
      }
    }
    _syncGraph();
    notifyListeners();
  }
}
