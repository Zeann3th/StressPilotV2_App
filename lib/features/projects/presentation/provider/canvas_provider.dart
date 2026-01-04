import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  

  Future<void> saveFlowConfiguration(
    int flowId,
    FlowProvider flowProvider,
  ) async {
    _isSaving = true;
    notifyListeners();

    try {
      
      final steps = generateFlowConfiguration();

      
      final updatedSteps = await flowProvider.configureFlow(flowId, steps);

      
      syncWithBackend(updatedSteps);

      
      await saveFlowLayout(flowId.toString(), silent: true);
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

  
  
  void syncWithBackend(List<FlowStep> responseSteps) {
    Map<String, String> idMap = {}; 

    
    for (var step in responseSteps) {
      final oldId = step.preProcessor?['_temp_sync_id'];
      if (oldId != null && oldId is String) {
        idMap[oldId] = step.id;
      }
    }

    
    for (int i = 0; i < _nodes.length; i++) {
      final oldId = _nodes[i].id;
      if (idMap.containsKey(oldId)) {
        final newId = idMap[oldId]!;

        
        final Map<String, dynamic> updatedData = Map.from(_nodes[i].data);
        if (updatedData.containsKey('preProcessor')) {
          final pre = Map<String, dynamic>.from(updatedData['preProcessor']);
          pre.remove('_temp_sync_id');
          updatedData['preProcessor'] = pre;
        }

        _nodes[i] = _nodes[i].copyWith(id: newId, data: updatedData);
      }
    }

    
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
