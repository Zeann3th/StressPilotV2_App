import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stress_pilot/features/projects/domain/flow.dart' as flow;
import 'package:stress_pilot/features/projects/presentation/provider/canvas_provider.dart';
import 'package:stress_pilot/features/projects/presentation/provider/flow_provider.dart';
import 'package:stress_pilot/features/projects/presentation/widgets/run_flow_dialog.dart';
import 'package:stress_pilot/features/projects/presentation/widgets/node_configuration_dialog.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

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
      _canvasProvider!.saveFlowLayout(widget.flowId, silent: true);
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
      ..translate(x, y, 0)
      ..scale(_initialScale);
  }

  void _zoom(double factor) {
    final matrix = _transformController.value.clone();
    // Zoom towards the center of the viewport
    final viewportSize = MediaQuery.of(context).size;
    final center = Offset(viewportSize.width / 2, viewportSize.height / 2);

    // Translate to center, scale, translate back
    matrix.translate(center.dx, center.dy);
    matrix.scale(factor);
    matrix.translate(-center.dx, -center.dy);

    final newScale = matrix.getMaxScaleOnAxis();
    if (newScale < 0.1 || newScale > 5.0) return;

    _transformController.value = matrix;
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
                              child: RepaintBoundary(
                                child: CustomPaint(
                                  painter: GridPainter(
                                    color: colors.onSurface.withAlpha(15),
                                    scale: 1.0,
                                  ),
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: RepaintBoundary(
                                child: CustomPaint(
                                  painter: ConnectionPainter(
                                    connections: canvasProvider.connections,
                                    nodes: canvasProvider.nodes,
                                    tempSourceId:
                                        canvasProvider.tempSourceNodeId,
                                    tempSourceHandle:
                                        canvasProvider.tempSourceHandle,
                                    tempEndPos: canvasProvider.tempDragPosition,
                                    lineColor: colors.onSurface,
                                    activeColor: colors.primary,
                                  ),
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
                                  // Double-tap behavior:
                                  // - Start node: no-op (indicator only)
                                  // - Branch node: open a small dialog to edit the condition expression
                                  // - Endpoint/other: open full node configuration
                                  onDoubleTap: node.type == FlowNodeType.start
                                      ? null
                                      : node.type == FlowNodeType.branch
                                          ? () => _showBranchConditionDialog(node)
                                          : () => _showNodeConfiguration(node),
                                ),
                              );
                            }),
                            // Connection Delete Buttons
                            ...canvasProvider.connections.map((conn) {
                              final source = canvasProvider.nodes.firstWhere(
                                (n) => n.id == conn.sourceNodeId,
                              );
                              final target = canvasProvider.nodes.firstWhere(
                                (n) => n.id == conn.targetNodeId,
                              );

                              // Calculate midpoint for delete button
                              Offset start;
                              if (source.type == FlowNodeType.branch) {
                                if (conn.sourceHandle == 'true') {
                                  start =
                                      source.position +
                                      Offset(source.width, source.height / 2);
                                } else {
                                  start =
                                      source.position +
                                      Offset(source.width / 2, source.height);
                                }
                              } else {
                                start =
                                    source.position +
                                    Offset(source.width, source.height / 2);
                              }

                              final end =
                                  target.position +
                                  Offset(0, target.height / 2);

                              // Simple midpoint approximation
                              final midX = (start.dx + end.dx) / 2;
                              final midY = (start.dy + end.dy) / 2;

                              return Positioned(
                                left: midX - 10,
                                top: midY - 10,
                                child: InkWell(
                                  onTap: () =>
                                      canvasProvider.removeConnection(conn.id),
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: colors.surface,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: colors.outlineVariant,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: colors.shadow.withValues(
                                            alpha: 0.1,
                                          ),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.close,
                                      size: 12,
                                      color: colors.error,
                                    ),
                                  ),
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

  void _showRunDialog(BuildContext context) {
    final flowId = int.parse(widget.flowId);
    showDialog(
      context: context,
      builder: (context) => RunFlowDialog(flowId: flowId),
    );
  }

  void _showJsonPayload(BuildContext context) {
    final provider = context.read<CanvasProvider>();
    final steps = provider.generateFlowConfiguration();
    final jsonEncoder = const JsonEncoder.withIndent('  ');
    final controller = TextEditingController(
      text: jsonEncoder.convert(steps.map((s) => s.toJson()).toList()),
    );

    showDialog(
      context: context,
      builder: (context) {
        final colors = Theme.of(context).colorScheme;
        return Dialog(
          backgroundColor: colors.surface,
          surfaceTintColor: colors.surfaceTint,
          child: Container(
            width: 800,
            height: 600,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Edit Flow Payload',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Warning: Modifying IDs or structure may break the visual layout.',
                  style: TextStyle(color: colors.error, fontSize: 12),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest.withValues(
                        alpha: 0.3,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colors.outlineVariant),
                    ),
                    child: TextField(
                      controller: controller,
                      maxLines: null,
                      expands: true,
                      style: const TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 12,
                      ),
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.all(16),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        try {
                          final List<dynamic> jsonList = jsonDecode(
                            controller.text,
                          );
                          final newSteps = jsonList
                              .map((e) => flow.FlowStep.fromJson(e))
                              .toList();

                          provider.applyConfiguration(newSteps);
                          Navigator.of(context).pop();

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Flow configuration updated'),
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Invalid JSON: $e'),
                              backgroundColor: colors.error,
                            ),
                          );
                        }
                      },
                      child: const Text('Apply Changes'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showNodeConfiguration(CanvasNode node) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => NodeConfigurationDialog(node: node),
    );

    if (result != null && mounted) {
      context.read<CanvasProvider>().updateNodeData(node.id, result);
    }
  }

  Future<void> _showBranchConditionDialog(CanvasNode node) async {
    final initial = node.data['condition']?.toString() ?? 'true';
    final controller = TextEditingController(text: initial);

    final result = await showDialog<String?>(
      context: context,
      builder: (context) {
        final colors = Theme.of(context).colorScheme;
        return Dialog(
          backgroundColor: colors.surface,
          surfaceTintColor: colors.surfaceTint,
          child: Container(
            width: 480,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Edit Condition', style: Theme.of(context).textTheme.titleMedium),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(null),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Provide the expression used to evaluate the branch (e.g. "user.age > 18")', style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12)),
                const SizedBox(height: 8),
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(null),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        final value = controller.text.trim();
                        Navigator.of(context).pop(value);
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (result != null && mounted) {
      context.read<CanvasProvider>().updateNodeData(node.id, {'condition': result});
    }
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
                    final flowId = int.parse(widget.flowId);
                    final flowProvider = context.read<FlowProvider>();

                    try {
                      await provider.saveFlowConfiguration(
                        flowId,
                        flowProvider,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Flow saved successfully!"),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Error saving flow: $e")),
                        );
                      }
                    }
                  },
            icon: provider.isSaving
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.save, size: 18, color: colors.onSurface),
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
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: () => _showRunDialog(context),
            icon: const Icon(Icons.play_arrow, size: 18),
            label: const Text("Run"),
            style: FilledButton.styleFrom(
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
            tooltip: 'Show JSON Payload',
            onPressed: () => _showJsonPayload(context),
            icon: Icon(Icons.data_object, color: colors.primary, size: 20),
          ),
          Divider(
            indent: 8,
            endIndent: 8,
            height: 1,
            color: colors.outlineVariant,
          ),
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
  final VoidCallback? onDoubleTap;

  const DraggableNodeWidget({
    super.key,
    required this.node,
    required this.canvasKey,
    required this.transformController,
    this.onDoubleTap,
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
        nodeContent = _buildStandardNode(context, provider, colors);
        break;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onDoubleTap: onDoubleTap,
      onPanUpdate: (details) {
        // Since GestureDetector is inside InteractiveViewer, details.delta
        // is already in the local coordinate space (scaled).
        // We don't need to divide by scale again.
        provider.updateNodePosition(node.id, node.position + details.delta);
      },
      child: RepaintBoundary(child: nodeContent),
    );
  }

  Widget _buildStandardNode(
    BuildContext context,
    CanvasProvider provider,
    ColorScheme colors,
  ) {
    final methodColor = _getMethodColor(node.data['method']);

    return Container(
      width: node.width,
      constraints: BoxConstraints(minHeight: node.height),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant, width: 1),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Colored top strip
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 4,
            child: Container(
              decoration: BoxDecoration(
                color: methodColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: methodColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        node.data['method'] ?? 'GET',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: methodColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  node.data['url'] ?? "Action node",
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.onSurface,
                    fontFamily: 'JetBrains Mono',
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Delete - Top Right
          Positioned(
            top: 8,
            right: 8,
            child: InkWell(
              onTap: () => provider.removeNode(node.id),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: colors.onSurfaceVariant.withValues(alpha: 0.7),
                ),
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
                colors.onSurfaceVariant,
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
          // Start Circle
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: colors.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          // Output port only
          Positioned(
            right: -6,
            child: _buildPortHandle(
              context,
              provider,
              'default',
              colors.onSurfaceVariant,
            ),
          ),
          // Delete
          Positioned(
            top: -12,
            child: InkWell(
              onTap: () => provider.removeNode(node.id),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: colors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.outlineVariant),
                ),
                child: Icon(
                  Icons.close,
                  size: 12,
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
    // Ensure diamond is always square based on the smaller dimension
    final size = node.width < node.height ? node.width : node.height;
    final diamondSize = size * 0.7; // Slightly larger to fill space better

    return SizedBox(
      width: node.width,
      height: node.height,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Diamond Shape (slightly tinted, stronger border and softer shadow)
          Transform.rotate(
            angle: 0.785398, // 45 deg
            child: Container(
              width: diamondSize,
              height: diamondSize,
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest.withValues(alpha: 0.06),
                border: Border.all(color: colors.primary, width: 1.8),
                borderRadius: BorderRadius.circular(
                  4,
                ), // Smaller radius for diamond
                boxShadow: [
                  BoxShadow(
                    color: colors.shadow.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
            ),
          ),

          // Intentionally empty center: show only the diamond shape and the T/F ports.
          const SizedBox.shrink(),

          // Delete button
          Positioned(
            top: 0,
            right: 0,
            child: InkWell(
              onTap: () => provider.removeNode(node.id),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: colors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.outlineVariant),
                ),
                child: Icon(
                  Icons.close,
                  size: 12,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          ),

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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
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
            bottom: -6,
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

    for (final conn in connections) {
      final source = _findNode(conn.sourceNodeId);
      final target = _findNode(conn.targetNodeId);
      if (source == null || target == null) continue;
      Offset start = _getOutputPos(source, conn.sourceHandle);
      Offset end = _getInputPos(target);
      _drawBezier(canvas, start, end, paint);
    }

    if (tempSourceId != null && tempEndPos != null) {
      final source = _findNode(tempSourceId!);
      if (source != null) {
        Offset start = _getOutputPos(source, tempSourceHandle);
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
      if (handle == 'true') {
        // Right side, centered vertically
        return node.position + Offset(node.width, node.height / 2);
      } else if (handle == 'false') {
        // Bottom side, centered horizontally
        return node.position + Offset(node.width / 2, node.height);
      }
    }
    if (node.type == FlowNodeType.start) {
      // Right side, centered vertically
      return node.position + Offset(node.width, node.height / 2);
    }
    // Standard node: Right side, centered vertically
    return node.position + Offset(node.width, node.height / 2);
  }

  Offset _getInputPos(CanvasNode node) {
    // Left side, centered vertically
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
