import 'package:flutter/material.dart' hide Flow;
import 'package:graphview/graphview.dart' as gv;
import 'package:provider/provider.dart';
import 'package:stress_pilot/core/navigation/app_router.dart';
import 'package:stress_pilot/core/design/tokens.dart';
import 'package:stress_pilot/features/projects/domain/flow.dart' as flow;
import 'package:stress_pilot/features/projects/presentation/provider/canvas_provider.dart';
import 'package:stress_pilot/features/projects/presentation/provider/flow_provider.dart';
import 'package:stress_pilot/features/endpoints/presentation/provider/endpoint_provider.dart';
import 'package:stress_pilot/features/projects/presentation/widgets/run_flow_dialog.dart';
import 'package:stress_pilot/features/projects/presentation/widgets/node_configuration_dialog.dart';
import 'package:stress_pilot/features/projects/presentation/widgets/subflow_configuration_dialog.dart';
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
    if (selectedFlow == null) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                borderRadius: AppRadius.br12,
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1,
                ),
                color: isDark ? AppColors.darkElevated : AppColors.lightElevated,
              ),
              child: const Center(
                child: Icon(
                  Icons.account_tree_outlined,
                  size: 28,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No flow selected',
              style: AppTypography.bodyLg.copyWith(
                color: isDark ? AppColors.textPrimary : AppColors.textLight,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Pick a flow tab above or create a new one',
              style: AppTypography.body.copyWith(color: AppColors.textMuted),
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

class _CanvasContentState extends State<_CanvasContent> with SingleTickerProviderStateMixin {
  final gv.SugiyamaConfiguration configuration = gv.SugiyamaConfiguration()
    ..orientation = gv.SugiyamaConfiguration.ORIENTATION_LEFT_RIGHT
    ..nodeSeparation = 100
    ..levelSeparation = 150;

  late AnimationController _animationController;
  CanvasProvider? _canvasProvider;

  @override
  void initState() {
    super.initState();
    _canvasProvider = context.read<CanvasProvider>();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        await _canvasProvider?.loadFlowLayout(widget.flowId);
        if (!mounted) return;

        final flowProvider = context.read<FlowProvider>();
        final endpointProvider = context.read<EndpointProvider>();
        try {
          final flowId = int.parse(widget.flowId);
          final flow = await flowProvider.getFlow(flowId);
          if (flow.steps.isNotEmpty) {
            _canvasProvider?.syncWithBackend(
              flow.steps,
              endpointProvider.endpoints,
              flowProvider.flows,
            );
          }
        } catch (e) {
          debugPrint('Failed to load flow configuration: $e');
        }
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _canvasProvider = context.read<CanvasProvider>();

    final endpoints = context.watch<EndpointProvider>().endpoints;
    if (endpoints.isNotEmpty) {
      _canvasProvider?.syncEndpointsMetadata(endpoints);
    }

    final flows = context.watch<FlowProvider>().flows;
    if (flows.isNotEmpty) {
      _canvasProvider?.syncFlowsMetadata(flows);
    }
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
        // Grid background
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
          child: DragTarget<DragData>(
            onAcceptWithDetails: (details) => _handleDrop(details, context),
            builder: (context, candidateData, rejectedData) {
              return InteractiveViewer(
                panEnabled: canvasProvider.canvasMode == CanvasMode.move,
                boundaryMargin: const EdgeInsets.all(8000),
                minScale: 0.1,
                maxScale: 4.0,
                constrained: false,
                child: Container(
                  color: Colors.transparent,
                  constraints: BoxConstraints(
                    minWidth: MediaQuery.of(context).size.width,
                    minHeight: MediaQuery.of(context).size.height,
                  ),
                  child: Stack(
                    children: [
                      if (canvasProvider.graph.nodes.isNotEmpty)
                      gv.GraphView(
                        graph: canvasProvider.graph,
                        algorithm: gv.SugiyamaAlgorithm(configuration),
                        paint: Paint()
                          ..color = colors.onSurfaceVariant.withValues(alpha: 0.5)
                          ..strokeWidth = 2
                          ..style = PaintingStyle.stroke,
                        builder: (gv.Node node) {
                          final nodeId = node.key?.value as String?;
                          if (nodeId == null) return const SizedBox.shrink();

                          final canvasNode = canvasProvider.nodes
                              .where((n) => n.id == nodeId)
                              .firstOrNull;

                          if (canvasNode == null) return const SizedBox.shrink();

                          return _buildNodeWidget(canvasNode, canvasProvider, colors);
                        },
                      ),
                    
                    if (canvasProvider.graph.nodes.isNotEmpty)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: AnimatedBuilder(
                            animation: _animationController,
                            builder: (context, child) {
                              return CustomPaint(
                                painter: _EdgeOverlayPainter(
                                  nodes: canvasProvider.nodes,
                                  connections: canvasProvider.connections,
                                  graph: canvasProvider.graph,
                                  animationOffset: _animationController.value * 14.0,
                                  colors: colors,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ));
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

  Widget _buildNodeWidget(CanvasNode node, CanvasProvider provider, ColorScheme colors) {
    return GestureDetector(
      onDoubleTap: () => _handleNodeDoubleTap(node),
      onTap: () {
        if (provider.canvasMode == CanvasMode.connect) {
          if (provider.selectedSourceNodeId != null) {
            provider.connectToTarget(node.id);
          } else {
            provider.selectSourceNode(node.id);
          }
        }
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _NodeBody(node: node, provider: provider, colors: colors),
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

  void _handleNodeDoubleTap(CanvasNode node) {
    switch (node.type) {
      case FlowNodeType.start:
        break;
      case FlowNodeType.branch:
        _showBranchConditionDialog(node);
        break;
      case FlowNodeType.subflow:
        _showSubflowConfiguration(node);
        break;
      case FlowNodeType.endpoint:
        _showNodeConfiguration(node);
        break;
    }
  }

  void _handleDrop(DragTargetDetails<DragData> details, BuildContext context) {
    final newNode = CanvasNode(
      id: const Uuid().v4(),
      type: details.data.type,
      position: Offset.zero,
      data: details.data.payload,
    );
    context.read<CanvasProvider>().addNode(newNode);
  }

  void _showNodeConfiguration(CanvasNode node) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => NodeConfigurationDialog(node: node),
    );

    if (result != null && mounted) {
      final canvasProvider = context.read<CanvasProvider>();
      final flowProvider = context.read<FlowProvider>();
      canvasProvider.updateNodeData(node.id, result);
      
      final scaffoldMessenger = AppNavigator.scaffoldMessengerKey.currentState;
      final theme = Theme.of(context);
      
      try {
        final flowId = int.parse(widget.flowId);
        await canvasProvider.saveFlowConfiguration(flowId, flowProvider);
        scaffoldMessenger?.showSnackBar(const SnackBar(content: Text('Node configuration saved')));
      } catch (e) {
        scaffoldMessenger?.showSnackBar(SnackBar(content: Text('Failed to save: $e'), backgroundColor: theme.colorScheme.error));
      }
    }
  }

  void _showSubflowConfiguration(CanvasNode node) async {
    final initialId = node.data['subflowId']?.toString();
    final result = await showDialog<flow.Flow?>(
      context: context,
      builder: (context) => SubflowConfigurationDialog(initialFlowId: initialId),
    );

    if (result != null && mounted) {
      final canvasProvider = context.read<CanvasProvider>();
      final flowProvider = context.read<FlowProvider>();
      canvasProvider.updateNodeData(node.id, {'subflowId': result.id.toString(), 'flowName': result.name});
      
      final scaffoldMessenger = AppNavigator.scaffoldMessengerKey.currentState;
      final theme = Theme.of(context);
      
      try {
        final flowId = int.parse(widget.flowId);
        await canvasProvider.saveFlowConfiguration(flowId, flowProvider);
        scaffoldMessenger?.showSnackBar(const SnackBar(content: Text('Subflow configuration saved')));
      } catch (e) {
        scaffoldMessenger?.showSnackBar(SnackBar(content: Text('Failed to save: $e'), backgroundColor: theme.colorScheme.error));
      }
    }
  }

  Future<void> _showBranchConditionDialog(CanvasNode node) async {
    final initial = node.data['condition']?.toString() ?? 'true';
    final controller = TextEditingController(text: initial);
    final result = await showDialog<String?>(
      context: context,
      builder: (context) => _BranchDialog(controller: controller),
    );
    if (result != null && mounted) {
      context.read<CanvasProvider>().updateNodeData(node.id, {'condition': result});
    }
  }

  void _showJsonPayload(BuildContext context) {
    final provider = context.read<CanvasProvider>();
    final steps = provider.generateFlowConfiguration();
    final jsonEncoder = const JsonEncoder.withIndent('  ');
    final controller = TextEditingController(text: jsonEncoder.convert(steps.map((s) => s.toJson()).toList()));

    showDialog(
      context: context,
      builder: (context) => _JsonPayloadDialog(controller: controller, provider: provider),
    );
  }

  void _showRunDialog(BuildContext context) {
    final flowId = int.parse(widget.flowId);
    final flowProvider = context.read<FlowProvider>();
    showDialog(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(value: flowProvider, child: RunFlowDialog(flowId: flowId)),
    );
  }

  Widget _buildUnifiedToolbar(BuildContext context, ColorScheme colors, CanvasProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: surfaceColor.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildModeButton(provider, CanvasMode.move, Icons.pan_tool_rounded, 'Pan'),
              const SizedBox(width: 6),
              _buildModeButton(provider, CanvasMode.connect, Icons.cable_rounded, 'Link'),
              _ToolbarDivider(borderColor: borderColor),
              _ToolbarIcon(tooltip: 'Show JSON', onTap: () => _showJsonPayload(context), icon: Icons.code_rounded, color: AppColors.textMuted),
              _ToolbarIcon(
                tooltip: 'Clear Canvas',
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: colors.surface,
                      title: const Text('Clear Canvas?'),
                      content: const Text('This will remove all nodes and connections.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
                        FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: colors.error, foregroundColor: colors.onError),
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) provider.clearCanvas();
                },
                icon: Icons.delete_sweep_outlined,
                color: AppColors.error,
              ),
              _ToolbarIcon(
                tooltip: 'Save Flow',
                onTap: provider.isSaving
                    ? null
                    : () async {
                        final flowId = int.parse(widget.flowId);
                        final flowProvider = context.read<FlowProvider>();
                        final scaffoldMessenger = AppNavigator.scaffoldMessengerKey.currentState;
                        try {
                          await provider.saveFlowConfiguration(flowId, flowProvider);
                          scaffoldMessenger?.showSnackBar(const SnackBar(content: Text('Flow saved.')));
                        } catch (e) {
                          scaffoldMessenger?.showSnackBar(SnackBar(content: Text('Error saving: $e')));
                        }
                      },
                icon: Icons.save_outlined,
                color: provider.isSaving ? AppColors.textMuted : AppColors.textSecondary,
                loading: provider.isSaving,
              ),
              const SizedBox(width: 8),
              _RunButton(onTap: () => _showRunDialog(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeButton(CanvasProvider provider, CanvasMode mode, IconData icon, String label) {
    final isSelected = provider.canvasMode == mode;
    return GestureDetector(
      onTap: () => provider.setCanvasMode(mode),
      child: AnimatedContainer(
        duration: AppDurations.micro,
        padding: EdgeInsets.symmetric(horizontal: isSelected ? 12 : 10, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: AppRadius.br8,
          border: Border.all(color: isSelected ? AppColors.accent.withValues(alpha: 0.5) : Colors.transparent),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? AppColors.accent : AppColors.textMuted),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(label, style: AppTypography.caption.copyWith(color: AppColors.accent, fontWeight: FontWeight.w600)),
            ],
          ],
        ),
      ),
    );
  }
}

class _EdgeOverlayPainter extends CustomPainter {
  final List<CanvasNode> nodes;
  final List<CanvasConnection> connections;
  final gv.Graph graph;
  final double animationOffset;
  final ColorScheme colors;

  _EdgeOverlayPainter({
    required this.nodes,
    required this.connections,
    required this.graph,
    required this.animationOffset,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = colors.primary.withValues(alpha: 0.8)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final conn in connections) {
      final sourceGv = graph.nodes.where((n) => n.key?.value == conn.sourceNodeId).firstOrNull;
      final targetGv = graph.nodes.where((n) => n.key?.value == conn.targetNodeId).firstOrNull;
      
      if (sourceGv == null || targetGv == null) continue;

      final sourceNode = nodes.where((n) => n.id == conn.sourceNodeId).firstOrNull;
      if (sourceNode == null) continue;

      final start = Offset(sourceGv.x, sourceGv.y);
      final end = Offset(targetGv.x, targetGv.y);

      _drawAnimatedDashes(canvas, start, end, paint);

      if (sourceNode.type == FlowNodeType.branch) {
        _drawLabel(canvas, start, end, conn.type == ConnectionType.trueType ? 'T' : 'F');
      }
    }
  }

  void _drawAnimatedDashes(Canvas canvas, Offset start, Offset end, Paint paint) {
    final path = Path();
    path.moveTo(start.dx, start.dy);
    path.lineTo(end.dx, end.dy);

    const dashWidth = 8.0;
    const dashSpace = 6.0;
    final pathMetrics = path.computeMetrics();

    for (final metric in pathMetrics) {
      double distance = -animationOffset % (dashWidth + dashSpace);
      while (distance < metric.length) {
        final double startDist = distance.clamp(0.0, metric.length);
        final double endDist = (distance + dashWidth).clamp(0.0, metric.length);
        if (startDist < endDist) {
          canvas.drawPath(metric.extractPath(startDist, endDist), paint);
        }
        distance += dashWidth + dashSpace;
      }
    }
  }

  void _drawLabel(Canvas canvas, Offset start, Offset end, String text) {
    final mid = Offset((start.dx * 3 + end.dx) / 4, (start.dy * 3 + end.dy) / 4);
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: text == 'T' ? Colors.green : Colors.red,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          backgroundColor: colors.surface.withValues(alpha: 0.8),
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, mid - Offset(textPainter.width / 2, textPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant _EdgeOverlayPainter oldDelegate) => true;
}

class _NodeBody extends StatelessWidget {
  final CanvasNode node;
  final CanvasProvider provider;
  final ColorScheme colors;

  const _NodeBody({required this.node, required this.provider, required this.colors});

  @override
  Widget build(BuildContext context) {
    switch (node.type) {
      case FlowNodeType.start: return _buildStart(colors);
      case FlowNodeType.branch: return _buildBranch(colors);
      case FlowNodeType.subflow: return _buildSubflow(colors);
      case FlowNodeType.endpoint: return _buildStandard(colors);
    }
  }

  Widget _buildStandard(ColorScheme colors) {
    final type = node.data['type'] ?? 'HTTP';
    final methodColor = _getTypeColor(type);
    return Container(
      width: node.width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.6)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: methodColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                child: Text(type.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: methodColor)),
              ),
              IconButton(
                onPressed: () => provider.removeNode(node.id),
                icon: const Icon(Icons.close, size: 14),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(node.data['name'] ?? "Endpoint", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(node.data['url'] ?? "Action node", style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant, fontFamily: 'JetBrains Mono'), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildSubflow(ColorScheme colors) {
    return Container(
      width: node.width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.secondary.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Row(
        children: [
          Icon(Icons.sync_alt_rounded, size: 16, color: colors.secondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('SUBFLOW', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: colors.secondary)),
                Text(node.data['flowName'] ?? "Select...", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          IconButton(onPressed: () => provider.removeNode(node.id), icon: const Icon(Icons.close, size: 14), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
        ],
      ),
    );
  }

  Widget _buildStart(ColorScheme colors) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [colors.primary, colors.tertiary]),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [BoxShadow(color: colors.primary.withValues(alpha: 0.3), blurRadius: 8)],
      ),
      child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
    );
  }

  Widget _buildBranch(ColorScheme colors) {
    return Container(
      width: node.width,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.primary.withValues(alpha: 0.5), width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.call_split_rounded, size: 20, color: Colors.grey),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _BranchHandle(label: 'T', color: Colors.green, isSelected: provider.selectedSourceNodeId == node.id && provider.selectedSourceHandle == 'true', onTap: () => provider.selectSourceNode(node.id, 'true')),
              _BranchHandle(label: 'F', color: Colors.red, isSelected: provider.selectedSourceNodeId == node.id && provider.selectedSourceHandle == 'false', onTap: () => provider.selectSourceNode(node.id, 'false')),
            ],
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toUpperCase()) {
      case 'HTTP': return Colors.blue;
      case 'GRPC': return Colors.teal;
      default: return Colors.blueGrey;
    }
  }
}

class _BranchHandle extends StatelessWidget {
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _BranchHandle({required this.label, required this.color, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
          border: Border.all(color: isSelected ? color : color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
      ),
    );
  }
}

class _BranchDialog extends StatelessWidget {
  final TextEditingController controller;
  const _BranchDialog({required this.controller});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Dialog(
      backgroundColor: colors.surface,
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Edit Branch Condition', style: AppTypography.title),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'e.g. response.status == 200',
                labelText: 'Expression',
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                const SizedBox(width: 12),
                FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Save')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _JsonPayloadDialog extends StatelessWidget {
  final TextEditingController controller;
  final CanvasProvider provider;

  const _JsonPayloadDialog({required this.controller, required this.provider});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Dialog(
      backgroundColor: colors.surface,
      child: Container(
        width: 800,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Edit Flow JSON', style: AppTypography.title),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(border: Border.all(color: colors.outlineVariant), borderRadius: BorderRadius.circular(8)),
                child: TextField(
                  controller: controller,
                  maxLines: null,
                  expands: true,
                  style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12),
                  decoration: const InputDecoration(contentPadding: EdgeInsets.all(16), border: InputBorder.none),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: () {
                    try {
                      final List<dynamic> jsonList = jsonDecode(controller.text);
                      final newSteps = jsonList.map((e) => flow.FlowStep.fromJson(e)).toList();
                      provider.applyConfiguration(newSteps);
                      Navigator.pop(context);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invalid JSON: $e'), backgroundColor: colors.error));
                    }
                  },
                  child: const Text('Apply'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolbarDivider extends StatelessWidget {
  final Color borderColor;
  const _ToolbarDivider({required this.borderColor});
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 20, margin: const EdgeInsets.symmetric(horizontal: 10), color: borderColor);
  }
}

class _ToolbarIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback? onTap;
  final bool loading;
  const _ToolbarIcon({required this.icon, required this.color, required this.tooltip, required this.onTap, this.loading = false});
  @override
  State<_ToolbarIcon> createState() => _ToolbarIconState();
}

class _ToolbarIconState extends State<_ToolbarIcon> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: _hovered ? widget.color.withValues(alpha: 0.1) : Colors.transparent, borderRadius: AppRadius.br8),
            child: widget.loading ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.5)) : Icon(widget.icon, size: 16, color: widget.color),
          ),
        ),
      ),
    );
  }
}

class _RunButton extends StatelessWidget {
  final VoidCallback onTap;
  const _RunButton({required this.onTap});
  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.play_arrow_rounded, size: 16),
      label: const Text('Run'),
      style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.white),
    );
  }
}
