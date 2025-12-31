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
      ..translateByDouble(x, y, 0, 1.0)
      ..scaleByDouble(_initialScale, _initialScale, _initialScale, 1.0);
  }

  void _zoom(double factor) {
    final matrix = _transformController.value.clone();
    // Zoom towards the center of the viewport
    final viewportSize = MediaQuery.of(context).size;
    final center = Offset(viewportSize.width / 2, viewportSize.height / 2);

    // Translate to center, scale, translate back
    matrix.translateByDouble(center.dx, center.dy, 0, 1.0);
    matrix.scaleByDouble(factor, factor, factor, 1.0);
    matrix.translateByDouble(-center.dx, -center.dy, 0, 1.0);

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
                    return Listener(
                      onPointerMove: (event) {
                        if (canvasProvider.canvasMode == CanvasMode.connect &&
                            canvasProvider.selectedSourceNodeId != null) {
                          final RenderBox box =
                              _canvasKey.currentContext!.findRenderObject()
                                  as RenderBox;
                          final localPos = box.globalToLocal(event.position);
                          canvasProvider.updateCursorPosition(localPos);
                        }
                      },
                      child: GestureDetector(
                        onTap: () {
                          // Background tap to deselect?
                          if (canvasProvider.canvasMode == CanvasMode.connect) {
                            canvasProvider.setCanvasMode(
                              CanvasMode.connect,
                            ); // Resets selection
                          }
                        },
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
                                      color: colors.onSurface.withValues(
                                        alpha: 0.05,
                                      ), // Updated to withValues
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
                                          canvasProvider.selectedSourceNodeId,
                                      tempSourceHandle:
                                          canvasProvider.selectedSourceHandle,
                                      tempEndPos:
                                          canvasProvider.tempDragPosition,
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
                                    onTap: () => canvasProvider
                                        .removeConnection(conn.id),
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

    final flowProvider = context.read<FlowProvider>();

    showDialog(
      context: context,
      builder: (_) {
        return ChangeNotifierProvider.value(
          value: flowProvider,
          child: RunFlowDialog(flowId: flowId),
        );
      },
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
                    Text(
                      'Edit Condition',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(null),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Provide the expression used to evaluate the branch (e.g. "user.age > 18")',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
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
      context.read<CanvasProvider>().updateNodeData(node.id, {
        'condition': result,
      });
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
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildModeButton(
                  context,
                  provider,
                  CanvasMode.move,
                  Icons.pan_tool_rounded,
                  'Move',
                ),
                const SizedBox(width: 4),
                _buildModeButton(
                  context,
                  provider,
                  CanvasMode.connect,
                  Icons.cable_rounded,
                  'Connect',
                ),
              ],
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

  Widget _buildModeButton(
    BuildContext context,
    CanvasProvider provider,
    CanvasMode mode,
    IconData icon,
    String label,
  ) {
    final isSelected = provider.canvasMode == mode;
    final colors = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => provider.setCanvasMode(mode),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colors.primaryContainer : null,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? colors.primary : colors.onSurfaceVariant,
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.primary,
                ),
              ),
            ],
          ],
        ),
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
      onTap: () {
        if (provider.canvasMode == CanvasMode.connect) {
          if (provider.selectedSourceNodeId != null) {
            // Allow connecting to any node (including self)
            provider.connectToTarget(node.id);
          } else {
            provider.selectSourceNode(node.id);
          }
        }
      },
      onPanUpdate: (details) {
        if (provider.canvasMode == CanvasMode.move) {
          provider.updateNodePosition(node.id, node.position + details.delta);
        }
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          RepaintBoundary(child: nodeContent),
          if (provider.selectedSourceNodeId == node.id)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.primary, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.surface,
            Color.lerp(colors.surface, methodColor, 0.05)!,
          ],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Left accent bar
          Positioned(
            left: 0,
            top: 12,
            bottom: 12,
            width: 4,
            child: Container(
              decoration: BoxDecoration(
                color: methodColor,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(4),
                  bottomRight: Radius.circular(4),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
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
                        border: Border.all(
                          color: methodColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        node.data['method'] ?? 'GET',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: methodColor,
                          letterSpacing: 0.5,
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
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Delete - Top Right (Floating)
          Positioned(
            top: -8,
            right: -8,
            child: InkWell(
              onTap: () => provider.removeNode(node.id),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: colors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.outlineVariant),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.close,
                  size: 14,
                  color: colors.onSurfaceVariant.withValues(alpha: 0.8),
                ),
              ),
            ),
          ),

          // Ports removed
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
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colors.primary, colors.tertiary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          // Output port removed

          // Delete
          Positioned(
            top: -12,
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
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
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
          // Diamond Shape (Gradient & Glow)
          Transform.rotate(
            angle: 0.785398, // 45 deg
            child: Container(
              width: diamondSize,
              height: diamondSize,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colors.surface,
                    colors.surfaceContainerHighest.withValues(alpha: 0.5),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colors.primary.withValues(alpha: 0.5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
            ),
          ),

          // Icon in center
          const Icon(
            Icons.call_split_rounded,
            size: 20,
            color: Colors.grey, // Subtle icon in center
          ),

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
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.close,
                  size: 12,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          ),

          // Input port removed

          // True Button
          Positioned(
            right: -8, // Slightly more offset for better hit area
            top: 0,
            bottom: 0,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  if (provider.canvasMode == CanvasMode.connect) {
                    provider.selectSourceNode(node.id, 'true');
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color:
                        provider.selectedSourceNodeId == node.id &&
                            provider.selectedSourceHandle == 'true'
                        ? colors.primaryContainer
                        : colors.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color:
                          provider.selectedSourceNodeId == node.id &&
                              provider.selectedSourceHandle == 'true'
                          ? colors.primary
                          : colors.primary.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                    boxShadow: [
                      if (provider.selectedSourceNodeId == node.id &&
                          provider.selectedSourceHandle == 'true')
                        BoxShadow(
                          color: colors.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                        ),
                    ],
                  ),
                  child: Text(
                    "T",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: colors.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // False Button
          Positioned(
            bottom: -8,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  if (provider.canvasMode == CanvasMode.connect) {
                    provider.selectSourceNode(node.id, 'false');
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color:
                        provider.selectedSourceNodeId == node.id &&
                            provider.selectedSourceHandle == 'false'
                        ? colors.errorContainer
                        : colors.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color:
                          provider.selectedSourceNodeId == node.id &&
                              provider.selectedSourceHandle == 'false'
                          ? colors.error
                          : colors.error.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                    boxShadow: [
                      if (provider.selectedSourceNodeId == node.id &&
                          provider.selectedSourceHandle == 'false')
                        BoxShadow(
                          color: colors.error.withValues(alpha: 0.3),
                          blurRadius: 8,
                        ),
                    ],
                  ),
                  child: Text(
                    "F",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: colors.error,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
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

    // Optimization: Create a map for O(1) lookups
    final nodeMap = {for (final node in nodes) node.id: node};

    for (final conn in connections) {
      final source = nodeMap[conn.sourceNodeId];
      final target = nodeMap[conn.targetNodeId];
      if (source == null || target == null) continue;

      _drawSmartConnection(canvas, source, target, conn.sourceHandle, paint);
    }

    // Draw "Live" connection line
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
    // 1. Determine Start Point
    // If handle is provided (Branch), force that side.
    // Otherwise, allow any side for source.
    final (startPos, startDir) = _getStartPoint(
      source,
      sourceHandle,
      target.position,
    );

    // 2. Determine End Point
    // Allow any side for target that is "facing" the start point or convenient.
    final (endPos, endDir) = _getBestEndPoint(target, startPos);

    // 3. Draw Orthogonal Line
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

    // For live connection, we don't have a target node orientation yet,
    // so we infer "arrival" direction based on relative position.
    AxisDirection endDir = AxisDirection.left; // Default
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

    // For standard nodes, choose the side closest to the target
    final center = node.position + Offset(node.width / 2, node.height / 2);
    final dx = targetCenter.dx - center.dx;
    final dy = targetCenter.dy - center.dy;

    if (dx.abs() > dy.abs()) {
      // Horizontal preference
      if (dx > 0) {
        return (
          node.position + Offset(node.width, node.height / 2),
          AxisDirection.right,
        );
      } else {
        return (node.position + Offset(0, node.height / 2), AxisDirection.left);
      }
    } else {
      // Vertical preference
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

    // We want to enter from the side facing the start position
    if (dx.abs() > dy.abs()) {
      if (dx > 0) {
        // Start is to the right, so we enter from right (pointing left)
        return (
          node.position + Offset(node.width, node.height / 2),
          AxisDirection.right,
        );
      } else {
        // Start is to the left, so we enter from left (pointing right)
        return (node.position + Offset(0, node.height / 2), AxisDirection.left);
      }
    } else {
      if (dy > 0) {
        // Start is below, enter from bottom (pointing up)
        return (
          node.position + Offset(node.width / 2, node.height),
          AxisDirection.down,
        );
      } else {
        // Start is above, enter from top (pointing down)
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

    // Ensure we actually reach the end point exactly
    if (points.isNotEmpty && points.last != end) {
      path.lineTo(end.dx, end.dy);
    }

    canvas.drawPath(path, paint);

    // Draw Arrowhead
    // Use the last segment direction
    final prevPoint = points.isNotEmpty ? points.last : start;
    _drawArrowHead(canvas, end, prevPoint, paint.color);
  }

  List<Offset> _getOrthogonalPoints(
    Offset start,
    Offset end,
    AxisDirection startDir,
    AxisDirection endDir,
  ) {
    // Improved Manhattan routing
    // 1. Move out from start
    // 2. Move out from end (acting as approach point)
    // 3. Connect them

    const double margin = 20.0;

    Offset p1 = _moveInDirection(start, startDir, margin);

    Offset p2 = _moveInDirection(end, endDir, margin);

    List<Offset> points = [p1];

    // Now connect p1 to p2 orthogonally
    // We essentially have a new start (p1) and end (p2) but we can turn freely now?
    // Not exactly, we prefer minimizing turns.

    double midX = (p1.dx + p2.dx) / 2;
    double midY = (p1.dy + p2.dy) / 2;

    bool startVertical =
        startDir == AxisDirection.up || startDir == AxisDirection.down;
    bool endVertical =
        endDir == AxisDirection.up || endDir == AxisDirection.down;

    // Heuristic:
    // If we are vertical at start, we usually want to move horizontally next.
    // If we are horizontal at start, we usually want to move vertically next.

    if (startVertical == endVertical) {
      // Both starting vertical (e.g. Top -> Bottom)
      // Connect via horizontal mid segment
      // Z path: Vertical -> Horizontal -> Vertical
      if (startVertical) {
        points.add(Offset(p1.dx, midY));
        points.add(Offset(p2.dx, midY));
      } else {
        // Both horizontal
        points.add(Offset(midX, p1.dy));
        points.add(Offset(midX, p2.dy));
      }
    } else {
      // Perpendicular (e.g. Right -> Bottom)
      // L path: Horizontal -> Vertical or V -> H
      if (startVertical) {
        // Moving Vertically first.
        // Can we go straight to p2.y?
        points.add(Offset(p1.dx, p2.dy));
      } else {
        // Moving Horizontally first
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
    if ((tip - prevPoint).distance < 1.0) return; // Prevention

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
