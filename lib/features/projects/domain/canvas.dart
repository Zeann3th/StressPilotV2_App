import 'package:flutter/material.dart';

enum FlowNodeType { start, endpoint, branch }

class CanvasNode {
  final String id;
  final FlowNodeType type;
  final Offset position;
  final Map<String, dynamic> data;
  final double width;
  final double height;

  CanvasNode({
    required this.id,
    required this.type,
    required this.position,
    this.data = const {},
    this.width = 150,
    this.height = 80,
  });

  CanvasNode copyWith({
    String? id,
    FlowNodeType? type,
    Offset? position,
    Map<String, dynamic>? data,
    double? width,
    double? height,
  }) {
    return CanvasNode(
      id: id ?? this.id,
      type: type ?? this.type,
      position: position ?? this.position,
      data: data ?? this.data,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }

  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'position': {'x': position.dx, 'y': position.dy},
      'data': data,
      'width': width,
      'height': height,
    };
  }

  factory CanvasNode.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'];
    final type = FlowNodeType.values.firstWhere(
      (e) => e.toString().split('.').last == typeStr,
      orElse: () => FlowNodeType.endpoint,
    );

    
    double defaultWidth = 160;
    double defaultHeight = 90;

    if (type == FlowNodeType.start) {
      defaultWidth = 40;
      defaultHeight = 40;
    } else if (type == FlowNodeType.branch) {
      defaultWidth = 80;
      defaultHeight = 80;
    }

    return CanvasNode(
      id: json['id'],
      type: type,
      position: Offset(
        json['position']['x'] as double,
        json['position']['y'] as double,
      ),
      data: json['data'] ?? {},
      width: (json['width'] as num?)?.toDouble() ?? defaultWidth,
      height: (json['height'] as num?)?.toDouble() ?? defaultHeight,
    );
  }
}


class CanvasConnection {
  final String id;
  final String sourceNodeId;
  final String targetNodeId;
  final String? sourceHandle;
  final String? targetHandle;

  CanvasConnection({
    required this.id,
    required this.sourceNodeId,
    required this.targetNodeId,
    this.sourceHandle,
    this.targetHandle,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'sourceNodeId': sourceNodeId,
    'targetNodeId': targetNodeId,
    'sourceHandle': sourceHandle,
    'targetHandle': targetHandle,
  };

  factory CanvasConnection.fromJson(Map<String, dynamic> json) {
    return CanvasConnection(
      id: json['id'],
      sourceNodeId: json['sourceNodeId'],
      targetNodeId: json['targetNodeId'],
      sourceHandle: json['sourceHandle'],
      targetHandle: json['targetHandle'],
    );
  }
}

class DragData {
  final FlowNodeType type;
  final Map<String, dynamic> payload;

  DragData({required this.type, required this.payload});
}
