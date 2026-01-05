import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stress_pilot/features/projects/domain/flow.dart' as flow;
import 'package:stress_pilot/features/projects/presentation/provider/canvas_provider.dart';
import 'package:stress_pilot/features/projects/presentation/provider/flow_provider.dart';
import 'package:stress_pilot/features/projects/presentation/widgets/run_flow_dialog.dart';
import 'package:stress_pilot/features/projects/presentation/widgets/node_configuration_dialog.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'dart:ui';

import '../../../domain/canvas.dart';
import 'canvas_painters.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        await _canvasProvider?.loadFlowLayout(widget.flowId);

        if (!mounted) return;

        // Load flow configuration from backend to get processor data
        final flowProvider = context.read<FlowProvider>();
        try {
          final flowId = int.parse(widget.flowId);
          final flow = await flowProvider.getFlow(flowId);

          // Merge processor data from backend into canvas nodes
          if (flow.steps.isNotEmpty) {
            debugPrint(
              '[Canvas Init] Syncing ${flow.steps.length} steps from backend',
            );
            for (var step in flow.steps) {
              debugPrint(
                '[Canvas Init] Step ${step.id}: pre=${step.preProcessor}, post=${step.postProcessor}',
              );
            }
            _canvasProvider?.syncWithBackend(flow.steps);
          }
        } catch (e) {
          debugPrint('Failed to load flow configuration: $e');
        }

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

    final viewportSize = MediaQuery.of(context).size;
    final center = Offset(viewportSize.width / 2, viewportSize.height / 2);

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

    return Stack(
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
            onAcceptWithDetails: (details) => _handleDrop(details, context),
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
                    if (canvasProvider.canvasMode == CanvasMode.connect) {
                      canvasProvider.setCanvasMode(CanvasMode.connect);
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
                                color: colors.onSurface.withValues(alpha: 0.1),
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
                              onDoubleTap: node.type == FlowNodeType.start
                                  ? null
                                  : node.type == FlowNodeType.branch
                                  ? () => _showBranchConditionDialog(node)
                                  : () => _showNodeConfiguration(node),
                            ),
                          );
                        }),

                        ...canvasProvider.connections.map((conn) {
                          final source = canvasProvider.nodes.firstWhere(
                            (n) => n.id == conn.sourceNodeId,
                          );
                          final target = canvasProvider.nodes.firstWhere(
                            (n) => n.id == conn.targetNodeId,
                          );

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
                              target.position + Offset(0, target.height / 2);

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
                ),
              );
            },
          ),
        ),

        Positioned(
          bottom: 32,
          left: 0,
          right: 0,
          child: Center(
            child: _buildUnifiedToolbar(context, colors, canvasProvider),
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
      final canvasProvider = context.read<CanvasProvider>();
      final flowProvider = context.read<FlowProvider>();

      // Update local state
      canvasProvider.updateNodeData(node.id, result);

      // Auto-save to backend
      try {
        final flowId = int.parse(widget.flowId);
        await canvasProvider.saveFlowConfiguration(flowId, flowProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Node configuration saved')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save configuration: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
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

  Future<void> _showClearConfirmation(
    BuildContext context,
    CanvasProvider provider,
  ) async {
    final colors = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surface,
        title: const Text('Clear Canvas?'),
        content: const Text(
          'This will remove all nodes and connections. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colors.error,
              foregroundColor: colors.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      provider.clearCanvas();
    }
  }

  Widget _buildUnifiedToolbar(
    BuildContext context,
    ColorScheme colors,
    CanvasProvider provider,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: colors.surface.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: colors.outlineVariant.withValues(alpha: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- Interaction Modes ---
              _buildModeButton(
                context,
                provider,
                CanvasMode.move,
                Icons.pan_tool_rounded,
                'Pan',
              ),
              const SizedBox(width: 8),
              _buildModeButton(
                context,
                provider,
                CanvasMode.connect,
                Icons.cable_rounded,
                'Link',
              ),

              Container(
                width: 1,
                height: 24,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                color: colors.outlineVariant,
              ),

              // --- View Controls ---
              IconButton(
                tooltip: _isLocked ? 'Unlock Canvas' : 'Lock Canvas',
                onPressed: _toggleLock,
                icon: Icon(
                  _isLocked ? Icons.lock : Icons.lock_open,
                  color: _isLocked ? colors.primary : colors.onSurfaceVariant,
                ),
              ),
              IconButton(
                tooltip: 'Zoom Out',
                onPressed: () => _zoom(0.9),
                icon: Icon(Icons.remove, color: colors.onSurface),
              ),
              IconButton(
                tooltip: 'Zoom In',
                onPressed: () => _zoom(1.1),
                icon: Icon(Icons.add, color: colors.onSurface),
              ),
              IconButton(
                tooltip: 'Reset View',
                onPressed: _centerCanvas,
                icon: Icon(Icons.center_focus_strong, color: colors.onSurface),
              ),

              Container(
                width: 1,
                height: 24,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                color: colors.outlineVariant,
              ),

              // --- Actions ---
              IconButton(
                tooltip: 'Show JSON',
                onPressed: () => _showJsonPayload(context),
                icon: Icon(Icons.code_rounded, color: colors.onSurfaceVariant),
              ),
              IconButton(
                onPressed: () => _showClearConfirmation(context, provider),
                icon: Icon(Icons.delete_sweep_outlined, color: colors.error),
                tooltip: 'Clear Canvas',
              ),
              const SizedBox(width: 8),
              IconButton(
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
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.save_outlined, color: colors.onSurface),
                tooltip: 'Save Flow',
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: () => _showRunDialog(context),
                icon: const Icon(Icons.play_arrow_rounded, size: 20),
                label: const Text("Run"),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ],
          ),
        ),
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
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primary
              : Colors.transparent, // High contrast active fill
          borderRadius: BorderRadius.circular(24),
          border: isSelected
              ? null
              : Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? colors.onPrimary
                  : colors.onSurface, // White icon on active
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.onPrimary, // White text on active
                ),
              ),
            ],
          ],
        ),
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
    final type = node.data['type'] ?? 'HTTP';
    final methodColor = _getTypeColor(type);

    return Container(
      width: node.width,
      constraints: BoxConstraints(minHeight: node.height),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.6),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: methodColor.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 12,
            bottom: 12,
            width: 3,
            child: Container(
              decoration: BoxDecoration(
                color: methodColor,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(3),
                  bottomRight: Radius.circular(3),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: methodColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        type.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: methodColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (node.data['name'] != null &&
                    node.data['name'].toString().isNotEmpty) ...[
                  Tooltip(
                    message: node.data['name'],
                    child: Text(
                      node.data['name'],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  node.data['url'] ?? "Action node",
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.onSurfaceVariant,
                    fontFamily: 'JetBrains Mono',
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          Positioned(
            top: -6,
            right: -6,
            child: InkWell(
              onTap: () => provider.removeNode(node.id),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: colors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colors.outlineVariant.withValues(alpha: 0.5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.close,
                  size: 12,
                  color: colors.onSurfaceVariant.withValues(alpha: 0.8),
                ),
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
    final size = node.width < node.height ? node.width : node.height;
    final diamondSize = size * 0.7;

    return SizedBox(
      width: node.width,
      height: node.height,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: 0.785398,
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

          const Icon(Icons.call_split_rounded, size: 20, color: Colors.grey),

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

          Positioned(
            right: -8,
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

  Color _getTypeColor(String type) {
    switch (type.toUpperCase()) {
      case 'HTTP':
        return Colors.blue;
      case 'GRPC':
        return Colors.teal;
      case 'TCP':
        return Colors.orange;
      case 'JDBC':
        return Colors.purple;
      default:
        // Generate a random but consistent color based on the type name
        final int hash = type.hashCode;
        return HSLColor.fromAHSL(
          1.0,
          (hash % 360).toDouble(),
          0.7, // Saturation
          0.5, // Lightness
        ).toColor();
    }
  }
}
