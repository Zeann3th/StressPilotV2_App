import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stress_pilot/features/projects/domain/flow.dart' as flow;
import 'package:stress_pilot/features/projects/presentation/provider/canvas_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/canvas.dart';

class WorkspaceCanvas extends StatelessWidget {
  final flow.Flow? selectedFlow;

  const WorkspaceCanvas({super.key, required this.selectedFlow});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (selectedFlow == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.touch_app_outlined, size: 64, color: colors.outline),
            const SizedBox(height: 16),
            Text(
              'Select a flow to start designing',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return ChangeNotifierProvider.value(
      value: context.read<CanvasProvider>(),
      child: _CanvasContent(flowId: selectedFlow!.id.toString()),
    );
  }
}

class _CanvasContent extends StatefulWidget {
  final String flowId;

  const _CanvasContent({required this.flowId});

  @override
  State<_CanvasContent> createState() => _CanvasContentState();
}

class _CanvasContentState extends State<_CanvasContent> {
  final GlobalKey _canvasKey = GlobalKey();
  final TransformationController _transformController =
      TransformationController();

  static const double _canvasSize = 5000.0;
  static const double _initialScale = 1.0;

  DateTime? _lastDropTime;
  bool _isLocked = false;
  CanvasProvider? _canvasProvider;

  @override
  void initState() {
    super.initState();
    _canvasProvider = context.read<CanvasProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _canvasProvider?.loadFlowLayout(widget.flowId);
        _centerCanvas();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _canvasProvider = context.read<CanvasProvider>();
  }

  @override
  void didUpdateWidget(covariant _CanvasContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.flowId != widget.flowId) {
      if (_canvasProvider != null && !_canvasProvider!.isLoading) {
        _canvasProvider!.saveFlowLayout(oldWidget.flowId);
      }
      _canvasProvider?.loadFlowLayout(widget.flowId);
    }
  }

  @override
  void dispose() {
    if (_canvasProvider != null && !_canvasProvider!.isLoading) {
      _canvasProvider!.saveFlowLayout(widget.flowId);
    }
    _transformController.dispose();
    super.dispose();
  }

  void _centerCanvas() {
    if (!mounted) return;
    final viewportSize = MediaQuery.of(context).size;
    final x = -(_canvasSize / 2 - viewportSize.width / 2);
    final y = -(_canvasSize / 2 - viewportSize.height / 2);

    _transformController.value = Matrix4.identity()
      ..translate(x, y)
      ..scale(_initialScale);
  }

  void _zoom(double factor) {
    final matrix = _transformController.value;
    final newScale = matrix.getMaxScaleOnAxis() * factor;
    if (newScale < 0.1 || newScale > 5.0) return;
    _transformController.value = matrix..scale(factor);
  }

  void _toggleLock() {
    setState(() => _isLocked = !_isLocked);
  }

  @override
  Widget build(BuildContext context) {
    final canvasProvider = context.watch<CanvasProvider>();
    final colors = Theme.of(context).colorScheme;

    if (canvasProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        _buildTopToolbar(context, colors, canvasProvider),
        Expanded(
          child: Stack(
            children: [
              InteractiveViewer(
                transformationController: _transformController,
                panEnabled: !_isLocked,
                scaleEnabled: !_isLocked,
                minScale: 0.1,
                maxScale: 5.0,
                boundaryMargin: const EdgeInsets.all(double.infinity),
                constrained: false,
                child: DragTarget<DragData>(
                  onAcceptWithDetails: (details) =>
                      _handleDrop(details, context),
                  builder: (context, candidateData, rejectedData) {
                    return GestureDetector(
                      onTap: () {},
                      child: Container(
                        key: _canvasKey,
                        width: _canvasSize,
                        height: _canvasSize,
                        color: colors.surface,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: CustomPaint(
                                painter: GridPainter(
                                  color: colors.onSurface.withAlpha(15),
                                  scale: 1.0,
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: CustomPaint(
                                painter: ConnectionPainter(
                                  connections: canvasProvider.connections,
                                  nodes: canvasProvider.nodes,
                                  tempSourceId: canvasProvider.tempSourceNodeId,
                                  tempEndPos: canvasProvider.tempDragPosition,
                                  lineColor: colors.onSurface,
                                  activeColor: colors.primary,
                                ),
                              ),
                            ),
                            ...canvasProvider.nodes.map((node) {
                              return Positioned(
                                left: node.position.dx,
                                top: node.position.dy,
                                child: DraggableNodeWidget(
                                  node: node,
                                  canvasKey: _canvasKey,
                                  transformController: _transformController,
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Positioned(bottom: 16, right: 16, child: _buildControls(colors)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopToolbar(
    BuildContext context,
    ColorScheme colors,
    CanvasProvider provider,
  ) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          bottom: BorderSide(color: colors.outlineVariant, width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.design_services_outlined,
            size: 20,
            color: colors.onSurface,
          ),
          const SizedBox(width: 8),
          Text(
            "Design Mode",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colors.onSurface,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () => provider.clearCanvas(),
            icon: Icon(
              Icons.delete_sweep_outlined,
              size: 18,
              color: colors.error,
            ),
            label: Text("Clear", style: TextStyle(color: colors.error)),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: provider.isSaving
                ? null
                : () async {
                    await provider.saveFlowLayout(widget.flowId);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Layout saved successfully!"),
                        ),
                      );
                    }
                  },
            icon: provider.isSaving
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.save_outlined, size: 18, color: colors.onSurface),
            label: Text(
              provider.isSaving ? "Saving..." : "Save",
              style: TextStyle(color: colors.onSurface),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: colors.outlineVariant),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(ColorScheme colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: _isLocked ? 'Unlock Canvas' : 'Lock Canvas',
            onPressed: _toggleLock,
            icon: Icon(
              _isLocked ? Icons.lock : Icons.lock_open,
              color: _isLocked ? colors.primary : colors.onSurfaceVariant,
              size: 20,
            ),
          ),
          Divider(
            indent: 8,
            endIndent: 8,
            height: 1,
            color: colors.outlineVariant,
          ),
          IconButton(
            tooltip: 'Zoom In',
            onPressed: () => _zoom(1.1),
            icon: Icon(Icons.add, color: colors.onSurface, size: 20),
          ),
          IconButton(
            tooltip: 'Zoom Out',
            onPressed: () => _zoom(0.9),
            icon: Icon(Icons.remove, color: colors.onSurface, size: 20),
          ),
          Divider(
            indent: 8,
            endIndent: 8,
            height: 1,
            color: colors.outlineVariant,
          ),
          IconButton(
            tooltip: 'Reset View',
            onPressed: _centerCanvas,
            icon: Icon(
              Icons.center_focus_strong,
              color: colors.onSurface,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  void _handleDrop(DragTargetDetails<DragData> details, BuildContext context) {
    final now = DateTime.now();
    if (_lastDropTime != null &&
        now.difference(_lastDropTime!) < const Duration(milliseconds: 300)) {
      return;
    }
    _lastDropTime = now;

    final RenderBox renderBox =
        _canvasKey.currentContext!.findRenderObject() as RenderBox;
    final localOffset = renderBox.globalToLocal(details.offset);

    double width = 160;
    double height = 90;
    Offset centerOffset = const Offset(80, 45);

    if (details.data.type == FlowNodeType.start) {
      width = 40;
      height = 40;
      centerOffset = const Offset(20, 20);
    } else if (details.data.type == FlowNodeType.branch) {
      width = 80;
      height = 80;
      centerOffset = const Offset(40, 40);
    }

    final newNode = CanvasNode(
      id: const Uuid().v4(),
      type: details.data.type,
      position: localOffset - centerOffset,
      width: width,
      height: height,
      data: details.data.payload,
    );

    context.read<CanvasProvider>().addNode(newNode);
  }
}

class DraggableNodeWidget extends StatelessWidget {
  final CanvasNode node;
  final GlobalKey canvasKey;
  final TransformationController transformController;

  const DraggableNodeWidget({
    super.key,
    required this.node,
    required this.canvasKey,
    required this.transformController,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.read<CanvasProvider>();
    final colors = Theme.of(context).colorScheme;

    Widget nodeContent;
    switch (node.type) {
      case FlowNodeType.start:
        nodeContent = _buildStartNode(context, provider, colors);
        break;
      case FlowNodeType.branch:
        nodeContent = _buildBranchNode(context, provider, colors);
        break;
      case FlowNodeType.endpoint:
      default:
        nodeContent = _buildStandardNode(context, provider, colors);
        break;
    }

    return GestureDetector(
      onPanUpdate: (details) {
        final double scale = transformController.value.getMaxScaleOnAxis();
        provider.updateNodePosition(
          node.id,
          node.position + details.delta / scale,
        );
      },
      child: nodeContent,
    );
  }

  Widget _buildStandardNode(
    BuildContext context,
    CanvasProvider provider,
    ColorScheme colors,
  ) {
    return Container(
      width: node.width,
      constraints: BoxConstraints(minHeight: node.height),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: colors.onSurface, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withAlpha(20),
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (node.type == FlowNodeType.endpoint)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _getMethodColor(node.data['method']).withAlpha(20),
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(
                        color: _getMethodColor(node.data['method']),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      node.data['method'] ?? 'GET',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _getMethodColor(node.data['method']),
                      ),
                    ),
                  ),
                const SizedBox(height: 6),
                Text(
                  node.data['url'] ?? "Action node",
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.onSurface,
                    fontFamily: 'monospace',
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Delete - Top Right
          Positioned(
            top: 2,
            right: 2,
            child: GestureDetector(
              onTap: () => provider.removeNode(node.id),
              child: Icon(
                Icons.close,
                size: 14,
                color: colors.onSurfaceVariant,
              ),
            ),
          ),

          // Ports - Centered vertically
          Positioned(
            left: -6,
            top: 0,
            bottom: 0,
            child: Center(child: _buildInputPort(context, provider)),
          ),
          Positioned(
            right: -6,
            top: 0,
            bottom: 0,
            child: Center(
              child: _buildPortHandle(
                context,
                provider,
                'default',
                colors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartNode(
    BuildContext context,
    CanvasProvider provider,
    ColorScheme colors,
  ) {
    return SizedBox(
      width: node.width,
      height: node.height,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Solid Black/White Circle (UML Start)
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: colors.onSurface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colors.shadow.withAlpha(40),
                  blurRadius: 4,
                  offset: const Offset(1, 1),
                ),
              ],
            ),
          ),
          // Output port only
          Positioned(
            right: -6,
            child: _buildPortHandle(
              context,
              provider,
              'default',
              colors.onSurface,
            ),
          ),
          // Delete
          Positioned(
            top: -12,
            child: GestureDetector(
              onTap: () => provider.removeNode(node.id),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: colors.surface.withAlpha(200),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  size: 14,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBranchNode(
    BuildContext context,
    CanvasProvider provider,
    ColorScheme colors,
  ) {
    return SizedBox(
      width: node.width,
      height: node.height,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Diamond Shape (UML Decision)
          Transform.rotate(
            angle: 0.785398, // 45 deg
            child: Container(
              width: node.width * 0.7,
              height: node.height * 0.7,
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border.all(color: colors.onSurface, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: colors.shadow.withAlpha(20),
                    blurRadius: 4,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
            ),
          ),
          // Question mark
          Center(
            child: Text(
              "?",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: colors.onSurface,
              ),
            ),
          ),

          // Delete button - Top Right corner of the bounding box
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => provider.removeNode(node.id),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: colors.surface.withAlpha(200),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  size: 14,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          ),

          // Input Port - Center Left
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Center(child: _buildInputPort(context, provider)),
          ),

          // Output "True" - Center Right
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 2),
                    child: Text(
                      "T",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: colors.primary,
                      ),
                    ),
                  ),
                  _buildPortHandle(context, provider, 'true', colors.primary),
                ],
              ),
            ),
          ),

          // Output "False" - Bottom Center
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "F",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: colors.error,
                    ),
                  ),
                  const SizedBox(height: 2),
                  _buildPortHandle(context, provider, 'false', colors.error),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputPort(BuildContext context, CanvasProvider provider) {
    final colors = Theme.of(context).colorScheme;
    return DragTarget<String>(
      onWillAcceptWithDetails: (details) => details.data != node.id,
      onAcceptWithDetails: (details) => provider.endConnection(node.id),
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: isHovering ? colors.primary : colors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: colors.onSurface, width: 2),
            boxShadow: isHovering
                ? [
                    BoxShadow(
                      color: colors.primary.withAlpha(100),
                      blurRadius: 4,
                    ),
                  ]
                : null,
          ),
        );
      },
    );
  }

  Widget _buildPortHandle(
    BuildContext context,
    CanvasProvider provider,
    String handleId,
    Color color,
  ) {
    final colors = Theme.of(context).colorScheme;
    return Draggable<String>(
      data: node.id,
      feedback: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: colors.primary,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(50), blurRadius: 4),
          ],
        ),
      ),
      onDragStarted: () {
        final RenderBox renderBox = context.findRenderObject() as RenderBox;
        final globalPos = renderBox.localToGlobal(Offset.zero);
        final RenderBox canvasBox =
            canvasKey.currentContext!.findRenderObject() as RenderBox;
        final localStartPos =
            canvasBox.globalToLocal(globalPos) + const Offset(6, 6);
        provider.startConnection(node.id, handleId, localStartPos);
      },
      onDragUpdate: (details) {
        final RenderBox canvasBox =
            canvasKey.currentContext!.findRenderObject() as RenderBox;
        final localPos = canvasBox.globalToLocal(details.globalPosition);
        provider.updateTempConnection(localPos);
      },
      onDragEnd: (details) => provider.cancelConnection(),
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: colors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
        ),
      ),
    );
  }

  Color _getMethodColor(String? method) {
    switch (method) {
      case 'POST':
        return Colors.green;
      case 'DELETE':
        return Colors.red;
      case 'PUT':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }
}

class GridPainter extends CustomPainter {
  final Color color;
  final double scale;

  GridPainter({required this.color, this.scale = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0 / scale;
    const spacing = 40.0; // Larger spacing
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ConnectionPainter extends CustomPainter {
  final List<CanvasConnection> connections;
  final List<CanvasNode> nodes;
  final String? tempSourceId;
  final Offset? tempEndPos;
  final Color lineColor;
  final Color activeColor;

  ConnectionPainter({
    required this.connections,
    required this.nodes,
    this.tempSourceId,
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
      ..strokeCap = StrokeCap.square;

    for (final conn in connections) {
      final source = _findNode(conn.sourceNodeId);
      final target = _findNode(conn.targetNodeId);
      if (source == null || target == null) continue;
      Offset start = _getOutputPos(source, conn.sourceHandle);
      Offset end = _getInputPos(target);
      // Orthogonal style for UML? No, Bezier is smoother for free canvas
      _drawBezier(canvas, start, end, paint);
    }

    if (tempSourceId != null && tempEndPos != null) {
      final source = _findNode(tempSourceId!);
      if (source != null) {
        Offset start = _getOutputPos(
          source,
          'default',
        ); // Default to center-right or similar
        // Try to guess handle based on proximity? Hard.
        // For dragging, we use the raw start position stored in provider usually,
        // but here we just re-calculate for visual simplicity if not passed.
        // Actually, we should probably use the exact drag start point if available,
        // but for now, let's just stick to the node center-right.
        // Better: logic for branch node dragging.
        if (source.type == FlowNodeType.branch) {
          start =
              source.position +
              Offset(source.width, source.height / 2); // Default T
          // If dragging downwards, maybe switch to F?
          // We don't know which handle was clicked here easily without storing it in provider.
          // Assuming T for now or letting the user see the line snap.
        }

        _drawBezier(canvas, start, tempEndPos!, activePaint);
      }
    }
  }

  CanvasNode? _findNode(String id) {
    try {
      return nodes.firstWhere((n) => n.id == id);
    } catch (e) {
      return null;
    }
  }

  Offset _getOutputPos(CanvasNode node, String? handle) {
    if (node.type == FlowNodeType.branch) {
      if (handle == 'true')
        return node.position + Offset(node.width, node.height / 2);
      else if (handle == 'false')
        return node.position + Offset(node.width / 2, node.height);
    }
    if (node.type == FlowNodeType.start) {
      return node.position + Offset(node.width, node.height / 2);
    }
    return node.position + Offset(node.width, node.height / 2);
  }

  Offset _getInputPos(CanvasNode node) {
    return node.position + Offset(0, node.height / 2);
  }

  void _drawBezier(Canvas canvas, Offset start, Offset end, Paint paint) {
    final path = Path();
    path.moveTo(start.dx, start.dy);
    double dist = (end.dx - start.dx).abs();
    // Adjust control points for vertical flow from bottom port
    // If start.dy < end.dy significantly and start.dx is close to end.dx, use vertical logic?
    // For now, standard horizontal-bias bezier
    final controlPoint1 = Offset(start.dx + dist * 0.5, start.dy);
    final controlPoint2 = Offset(end.dx - dist * 0.5, end.dy);
    path.cubicTo(
      controlPoint1.dx,
      controlPoint1.dy,
      controlPoint2.dx,
      controlPoint2.dy,
      end.dx,
      end.dy,
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
