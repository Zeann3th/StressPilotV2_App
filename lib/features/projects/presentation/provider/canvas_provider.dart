import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../domain/canvas.dart';

class CanvasProvider extends ChangeNotifier {
  List<CanvasNode> _nodes = [];
  List<CanvasConnection> _connections = [];

  // State nối dây
  String? _tempSourceNodeId;
  Offset? _tempDragPosition;
  String? _tempSourceHandle;

  // State File I/O
  bool _isSaving = false;
  bool _isLoading = false;

  List<CanvasNode> get nodes => _nodes;
  List<CanvasConnection> get connections => _connections;
  String? get tempSourceNodeId => _tempSourceNodeId;
  Offset? get tempDragPosition => _tempDragPosition;
  bool get isSaving => _isSaving;
  bool get isLoading => _isLoading;

  final _uuid = const Uuid();

  // --- PATH UTILS ---

  /// Lấy đường dẫn thư mục lưu trữ: ~/.pilot/client/layouts
  /// Sử dụng Platform.pathSeparator để đảm bảo đúng format trên Windows/Mac/Linux
  Future<String> _getLayoutDirectory() async {
    String home = "";
    Map<String, String> envVars = Platform.environment;

    if (Platform.isMacOS || Platform.isLinux) {
      home = envVars['HOME'] ?? '/';
    } else if (Platform.isWindows) {
      home = envVars['UserProfile'] ?? 'C:\\';
    }

    final sep = Platform.pathSeparator;
    // Xử lý trường hợp home path có thể kết thúc bằng separator hoặc không
    if (home.endsWith(sep)) {
      home = home.substring(0, home.length - 1);
    }

    // Xây dựng đường dẫn: home/.pilot/client/layouts
    final directoryPath = '$home$sep.pilot${sep}client${sep}layouts';
    final directory = Directory(directoryPath);

    if (!await directory.exists()) {
      await directory.create(recursive: true);
      debugPrint("Created directory: $directoryPath");
    }

    return directoryPath;
  }

  Future<File> _getLayoutFile(String flowId) async {
    final dir = await _getLayoutDirectory();
    final sep = Platform.pathSeparator;
    return File('$dir$sep$flowId.json');
  }

  // --- PERSISTENCE (SAVE/LOAD TO DISK) ---

  /// Lưu layout hiện tại xuống file json
  Future<void> saveFlowLayout(String flowId) async {
    _isSaving = true;
    notifyListeners();

    try {
      final layoutData = {
        'nodes': _nodes.map((n) => n.toJson()).toList(),
        'connections': _connections.map((c) => c.toJson()).toList(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      final jsonString = jsonEncode(layoutData);
      final file = await _getLayoutFile(flowId);

      await file.writeAsString(jsonString);
      debugPrint("✅ SAVED LAYOUT TO: ${file.path}");
    } catch (e) {
      debugPrint("❌ Error saving layout: $e");
      rethrow;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Load layout từ file json
  Future<void> loadFlowLayout(String flowId) async {
    _isLoading = true;
    // Clear state cũ trước khi load
    _nodes = [];
    _connections = [];
    notifyListeners(); // Update UI để hiện loading spinner nếu cần

    try {
      final file = await _getLayoutFile(flowId);
      debugPrint("Attempting to load layout from: ${file.path}");

      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final decoded = jsonDecode(jsonString);

        _nodes = (decoded['nodes'] as List)
            .map((e) => CanvasNode.fromJson(e))
            .toList();

        _connections = (decoded['connections'] as List)
            .map((e) => CanvasConnection.fromJson(e))
            .toList();

        debugPrint("✅ Loaded layout successfully with ${_nodes.length} nodes");
      } else {
        debugPrint("ℹ️ No existing layout file for flow: $flowId");
      }
    } catch (e) {
      debugPrint("❌ Error loading layout: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- NODE OPERATIONS ---

  void addNode(CanvasNode node) {
    _nodes.add(node);
    notifyListeners();
  }

  void updateNodePosition(String id, Offset newPosition) {
    final index = _nodes.indexWhere((n) => n.id == id);
    if (index != -1) {
      _nodes[index] = _nodes[index].copyWith(position: newPosition);
      notifyListeners();
    }
  }

  void removeNode(String id) {
    _nodes.removeWhere((n) => n.id == id);
    _connections.removeWhere((c) => c.sourceNodeId == id || c.targetNodeId == id);
    notifyListeners();
  }

  // --- CONNECTION OPERATIONS ---

  void startConnection(String nodeId, String? handle, Offset position) {
    _tempSourceNodeId = nodeId;
    _tempSourceHandle = handle;
    _tempDragPosition = position;
    notifyListeners();
  }

  void updateTempConnection(Offset position) {
    _tempDragPosition = position;
    notifyListeners();
  }

  void endConnection(String targetNodeId) {
    if (_tempSourceNodeId != null && _tempSourceNodeId != targetNodeId) {
      final exists = _connections.any((c) =>
      c.sourceNodeId == _tempSourceNodeId && c.targetNodeId == targetNodeId);

      if (!exists) {
        _connections.add(CanvasConnection(
          id: _uuid.v4(),
          sourceNodeId: _tempSourceNodeId!,
          targetNodeId: targetNodeId,
          sourceHandle: _tempSourceHandle,
        ));
      }
    }
    cancelConnection();
  }

  void cancelConnection() {
    _tempSourceNodeId = null;
    _tempDragPosition = null;
    _tempSourceHandle = null;
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

  // Method cũ để debug console (nếu cần giữ)
  String saveLayout() {
    final layout = {
      'nodes': _nodes.map((n) => n.toJson()).toList(),
      'connections': _connections.map((c) => c.toJson()).toList(),
    };
    return jsonEncode(layout);
  }
}