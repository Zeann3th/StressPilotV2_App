import 'package:flutter/material.dart';
import '../../../domain/canvas.dart';

class GridPainter extends CustomPainter {
  final Color color;
  final double scale;

  GridPainter({required this.color, this.scale = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0 / scale
      ..strokeCap = StrokeCap.round;

    const spacing = 20.0;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        if ((x / spacing).round() % 2 == 0 && (y / spacing).round() % 2 == 0) {
          canvas.drawCircle(Offset(x, y), 1.0 / scale, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ConnectionPainter extends CustomPainter {
  final List<CanvasConnection> connections;
  final List<CanvasNode> nodes;
  final String? tempSourceId;
  final String? tempSourceHandle;
  final Offset? tempEndPos;
  final Color lineColor;
  final Color activeColor;

  ConnectionPainter({
    required this.connections,
    required this.nodes,
    this.tempSourceId,
    this.tempSourceHandle,
    this.tempEndPos,
    required this.lineColor,
    required this.activeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final activePaint = Paint()
      ..color = activeColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final nodeMap = {for (final node in nodes) node.id: node};

    for (final conn in connections) {
      final source = nodeMap[conn.sourceNodeId];
      final target = nodeMap[conn.targetNodeId];
      if (source == null || target == null) continue;

      _drawSmartConnection(canvas, source, target, conn.sourceHandle, paint);
    }

    if (tempSourceId != null && tempEndPos != null) {
      final source = nodeMap[tempSourceId];
      if (source != null) {
        _drawSmartLiveConnection(
          canvas,
          source,
          tempSourceHandle,
          tempEndPos!,
          activePaint,
        );
      }
    }
  }

  void _drawSmartConnection(
    Canvas canvas,
    CanvasNode source,
    CanvasNode target,
    String? sourceHandle,
    Paint paint,
  ) {
    final (startPos, startDir) = _getStartPoint(
      source,
      sourceHandle,
      target.position,
    );

    final (endPos, endDir) = _getBestEndPoint(target, startPos);

    _drawOrthogonalLine(canvas, startPos, endPos, startDir, endDir, paint);
  }

  void _drawSmartLiveConnection(
    Canvas canvas,
    CanvasNode source,
    String? sourceHandle,
    Offset endPos,
    Paint paint,
  ) {
    final (startPos, startDir) = _getStartPoint(source, sourceHandle, endPos);

    AxisDirection endDir = AxisDirection.left;
    if ((endPos.dx - startPos.dx).abs() > (endPos.dy - startPos.dy).abs()) {
      endDir = endPos.dx > startPos.dx
          ? AxisDirection.left
          : AxisDirection.right;
    } else {
      endDir = endPos.dy > startPos.dy ? AxisDirection.up : AxisDirection.down;
    }

    _drawOrthogonalLine(canvas, startPos, endPos, startDir, endDir, paint);
  }

  (Offset, AxisDirection) _getStartPoint(
    CanvasNode node,
    String? handle,
    Offset targetCenter,
  ) {
    if (node.type == FlowNodeType.branch) {
      if (handle == 'true') {
        return (
          node.position + Offset(node.width, node.height / 2),
          AxisDirection.right,
        );
      } else if (handle == 'false') {
        return (
          node.position + Offset(node.width / 2, node.height),
          AxisDirection.down,
        );
      }
    }

    final center = node.position + Offset(node.width / 2, node.height / 2);
    final dx = targetCenter.dx - center.dx;
    final dy = targetCenter.dy - center.dy;

    if (dx.abs() > dy.abs()) {
      if (dx > 0) {
        return (
          node.position + Offset(node.width, node.height / 2),
          AxisDirection.right,
        );
      } else {
        return (node.position + Offset(0, node.height / 2), AxisDirection.left);
      }
    } else {
      if (dy > 0) {
        return (
          node.position + Offset(node.width / 2, node.height),
          AxisDirection.down,
        );
      } else {
        return (node.position + Offset(node.width / 2, 0), AxisDirection.up);
      }
    }
  }

  (Offset, AxisDirection) _getBestEndPoint(CanvasNode node, Offset startPos) {
    final center = node.position + Offset(node.width / 2, node.height / 2);
    final dx = startPos.dx - center.dx;
    final dy = startPos.dy - center.dy;

    if (dx.abs() > dy.abs()) {
      if (dx > 0) {
        return (
          node.position + Offset(node.width, node.height / 2),
          AxisDirection.right,
        );
      } else {
        return (node.position + Offset(0, node.height / 2), AxisDirection.left);
      }
    } else {
      if (dy > 0) {
        return (
          node.position + Offset(node.width / 2, node.height),
          AxisDirection.down,
        );
      } else {
        return (node.position + Offset(node.width / 2, 0), AxisDirection.up);
      }
    }
  }

  void _drawOrthogonalLine(
    Canvas canvas,
    Offset start,
    Offset end,
    AxisDirection startDir,
    AxisDirection endDir,
    Paint paint,
  ) {
    final path = Path();
    path.moveTo(start.dx, start.dy);

    final points = _getOrthogonalPoints(start, end, startDir, endDir);
    for (final point in points) {
      path.lineTo(point.dx, point.dy);
    }

    if (points.isNotEmpty && points.last != end) {
      path.lineTo(end.dx, end.dy);
    }

    canvas.drawPath(path, paint);

    final prevPoint = points.isNotEmpty ? points.last : start;
    _drawArrowHead(canvas, end, prevPoint, paint.color);
  }

  List<Offset> _getOrthogonalPoints(
    Offset start,
    Offset end,
    AxisDirection startDir,
    AxisDirection endDir,
  ) {
    const double margin = 20.0;

    Offset p1 = _moveInDirection(start, startDir, margin);

    Offset p2 = _moveInDirection(end, endDir, margin);

    List<Offset> points = [p1];

    double midX = (p1.dx + p2.dx) / 2;
    double midY = (p1.dy + p2.dy) / 2;

    bool startVertical =
        startDir == AxisDirection.up || startDir == AxisDirection.down;
    bool endVertical =
        endDir == AxisDirection.up || endDir == AxisDirection.down;

    if (startVertical == endVertical) {
      if (startVertical) {
        points.add(Offset(p1.dx, midY));
        points.add(Offset(p2.dx, midY));
      } else {
        points.add(Offset(midX, p1.dy));
        points.add(Offset(midX, p2.dy));
      }
    } else {
      if (startVertical) {
        points.add(Offset(p1.dx, p2.dy));
      } else {
        points.add(Offset(p2.dx, p1.dy));
      }
    }

    points.add(p2);
    points.add(end);

    return points;
  }

  Offset _moveInDirection(Offset p, AxisDirection dir, double distance) {
    switch (dir) {
      case AxisDirection.left:
        return p + Offset(-distance, 0);
      case AxisDirection.right:
        return p + Offset(distance, 0);
      case AxisDirection.up:
        return p + Offset(0, -distance);
      case AxisDirection.down:
        return p + Offset(0, distance);
    }
  }

  void _drawArrowHead(
    Canvas canvas,
    Offset tip,
    Offset prevPoint,
    Color color,
  ) {
    if ((tip - prevPoint).distance < 1.0) return;

    final angle = (tip - prevPoint).direction;
    const arrowSize = 6.0;

    final arrowPath = Path();
    arrowPath.moveTo(tip.dx, tip.dy);
    arrowPath.lineTo(tip.dx - arrowSize * 1.5 * 0.8, tip.dy - arrowSize * 0.8);
    arrowPath.lineTo(tip.dx - arrowSize * 1.5 * 0.8, tip.dy + arrowSize * 0.8);
    arrowPath.close();

    canvas.save();
    canvas.translate(tip.dx, tip.dy);
    canvas.rotate(angle);
    canvas.translate(-tip.dx, -tip.dy);

    canvas.drawPath(
      arrowPath,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
