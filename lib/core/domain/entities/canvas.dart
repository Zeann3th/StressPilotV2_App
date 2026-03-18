import 'package:flutter/material.dart';

enum FlowNodeType { start, endpoint, branch, subflow }

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
    this.width = 160,
    this.height = 90,
  }) : actualWidth = type == FlowNodeType.branch ? 80 : (type == FlowNodeType.start ? 56 : width),
       actualHeight = type == FlowNodeType.branch ? 80 : (type == FlowNodeType.start ? 56 : height);

  final double actualWidth;
  final double actualHeight;

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

    return CanvasNode(
      id: json['id'],
      type: type,
      position: Offset(
        (json['position']['x'] as num).toDouble(),
        (json['position']['y'] as num).toDouble(),
      ),
      data: json['data'] ?? {},
      width: (json['width'] as num?)?.toDouble() ?? 160,
      height: (json['height'] as num?)?.toDouble() ?? 90,
    );
  }
}

enum ConnectionType { defaultType, trueType, falseType }

class CanvasConnection {
  final String id;
  final String sourceNodeId;
  final String targetNodeId;
  final String? sourceHandle;
  final ConnectionType type;

  CanvasConnection({
    required this.id,
    required this.sourceNodeId,
    required this.targetNodeId,
    this.sourceHandle,
    this.type = ConnectionType.defaultType,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'sourceNodeId': sourceNodeId,
        'targetNodeId': targetNodeId,
        'sourceHandle': sourceHandle,
        'type': type.toString().split('.').last,
      };

  factory CanvasConnection.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'];
    final type = ConnectionType.values.firstWhere(
      (e) => e.toString().split('.').last == typeStr,
      orElse: () => ConnectionType.defaultType,
    );

    return CanvasConnection(
      id: json['id'],
      sourceNodeId: json['sourceNodeId'],
      targetNodeId: json['targetNodeId'],
      sourceHandle: json['sourceHandle'],
      type: type,
    );
  }
}

class DragData {
  final FlowNodeType type;
  final Map<String, dynamic> payload;

  DragData({required this.type, required this.payload});
}
