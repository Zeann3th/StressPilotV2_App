import 'package:flutter/material.dart';
import 'package:stress_pilot/features/projects/domain/flow.dart';
import 'package:stress_pilot/features/projects/presentation/provider/flow_provider.dart';
import 'package:uuid/uuid.dart';

import '../../domain/canvas.dart';

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
      _connections.add(
        CanvasConnection(
          id: const Uuid().v4(),
          sourceNodeId: _selectedSourceNodeId!,
          targetNodeId: targetNodeId,
          sourceHandle: _selectedSourceHandle ?? 'default',
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
    _selectedSourceNodeId = null;
    notifyListeners();
  }

  Future<void> saveFlowLayout(String flowId, {bool silent = false}) async {
    // Feature cancelled as per user request - we now load from DB every time
    return;
  }

  Future<void> loadFlowLayout(String flowId) async {
    _isLoading = true;
    _nodes = [];
    _connections = [];
    notifyListeners();
    
    // We don't load from SharedPreferences anymore
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
      
      // After saving configuration to backend, we rebuild to ensure sync
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
      // Keep _temp_sync_id for backend syncing if needed, though we rebuild now
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

  void rebuildFromSteps(List<FlowStep> steps) {
    _nodes.clear();
    _connections.clear();

    if (steps.isEmpty) {
      notifyListeners();
      return;
    }

    // Simple layout: Place nodes in a row or grid
    double startX = 2500.0;
    double startY = 2500.0;
    double spacingX = 250.0;
    double spacingY = 150.0;

    // First, create all nodes
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
        default:
          type = FlowNodeType.endpoint;
      }

      // Basic grid layout logic
      double x = startX + (i % 5) * spacingX;
      double y = startY + (i ~/ 5) * spacingY;

      final node = CanvasNode(
        id: step.id,
        type: type,
        position: Offset(x, y),
        data: {
          if (step.endpointId != null) 'id': step.endpointId,
          if (step.condition != null) 'condition': step.condition,
          if (step.preProcessor != null) 'preProcessor': step.preProcessor,
          if (step.postProcessor != null) 'postProcessor': step.postProcessor,
        },
      );
      _nodes.add(node);
    }

    // Then, create all connections
    for (var step in steps) {
      if (step.nextIfTrue != null) {
        String? sourceHandle;
        if (step.type == 'BRANCH') {
          sourceHandle = 'true';
        }

        if (_nodes.any((n) => n.id == step.nextIfTrue)) {
          _connections.add(
            CanvasConnection(
              id: const Uuid().v4(),
              sourceNodeId: step.id,
              targetNodeId: step.nextIfTrue!,
              sourceHandle: sourceHandle,
            ),
          );
        }
      }

      if (step.nextIfFalse != null && step.type == 'BRANCH') {
        if (_nodes.any((n) => n.id == step.nextIfFalse)) {
          _connections.add(
            CanvasConnection(
              id: const Uuid().v4(),
              sourceNodeId: step.id,
              targetNodeId: step.nextIfFalse!,
              sourceHandle: 'false',
            ),
          );
        }
      }
    }

    notifyListeners();
  }

  void syncWithBackend(List<FlowStep> responseSteps) {
    // Since we now want to load everything from DB and draw nodes, 
    // we use rebuildFromSteps instead of merging.
    rebuildFromSteps(responseSteps);
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

        _nodes[index] = node.copyWith(data: newData);
      }
    }

    _connections.clear();

    for (var step in steps) {
      if (step.nextIfTrue != null) {
        String? sourceHandle;

        final sourceNode = _nodes.where((n) => n.id == step.id).firstOrNull;
        if (sourceNode?.type == FlowNodeType.branch) {
          sourceHandle = 'true';
        }

        if (_nodes.any((n) => n.id == step.nextIfTrue)) {
          _connections.add(
            CanvasConnection(
              id: const Uuid().v4(),
              sourceNodeId: step.id,
              targetNodeId: step.nextIfTrue!,
              sourceHandle: sourceHandle,
            ),
          );
        }
      }

      if (step.nextIfFalse != null) {
        final sourceNode = _nodes.where((n) => n.id == step.id).firstOrNull;
        if (sourceNode?.type == FlowNodeType.branch) {
          if (_nodes.any((n) => n.id == step.nextIfFalse)) {
            _connections.add(
              CanvasConnection(
                id: const Uuid().v4(),
                sourceNodeId: step.id,
                targetNodeId: step.nextIfFalse!,
                sourceHandle: 'false',
              ),
            );
          }
        }
      }
    }

    notifyListeners();
  }
}
