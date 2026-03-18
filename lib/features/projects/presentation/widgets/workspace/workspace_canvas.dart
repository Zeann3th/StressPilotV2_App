import 'package:flutter/material.dart' hide Flow;
import 'package:provider/provider.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:stress_pilot/core/utils/tutorial_helper.dart';
import 'package:stress_pilot/core/navigation/app_router.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/core/domain/entities/flow.dart' as flow;
import 'package:stress_pilot/core/themes/components/components.dart';
import 'package:stress_pilot/features/projects/presentation/provider/canvas_provider.dart';
import 'package:stress_pilot/features/projects/presentation/provider/flow_provider.dart';
import 'package:stress_pilot/features/endpoints/presentation/provider/endpoint_provider.dart';
import 'package:stress_pilot/features/projects/presentation/widgets/run_flow_dialog.dart';
import 'package:stress_pilot/features/projects/presentation/widgets/node_configuration_dialog.dart';
import 'package:stress_pilot/features/projects/presentation/widgets/subflow_configuration_dialog.dart';
import 'package:stress_pilot/features/common/presentation/provider/run_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;
import 'dart:convert';
import 'dart:ui';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:highlight/languages/json.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';

import '../../../../../core/domain/entities/canvas.dart';
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
      child: _CanvasContent(

        key: ValueKey(selectedFlow!.id),
        flowId: selectedFlow!.id.toString(),
      ),
    );
  }
}

class _CanvasContent extends StatefulWidget {
  final String flowId;

  const _CanvasContent({super.key, required this.flowId});

  @override
  State<_CanvasContent> createState() => _CanvasContentState();
}

class _CanvasContentState extends State<_CanvasContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final TransformationController _transformationController =
  TransformationController();

  CanvasProvider? _canvasProvider;

  bool _initialLoadScheduled = false;

  final GlobalKey _toolbarKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _canvasProvider = context.read<CanvasProvider>();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _transformationController.value = Matrix4.identity()
      ..setTranslationRaw(-3500.0, -3500.0, 0.0);

    _scheduleInitialLoad();
    _showTutorial();
  }

  void _showTutorial() {
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      TutorialHelper.showTutorialIfFirstTime(
        context: context,
        prefKey: 'tutorial_canvas',
        targets: [
          TargetFocus(
            identify: "CanvasToolbar",
            keyTarget: _toolbarKey,
            alignSkip: Alignment.topRight,
            shape: ShapeLightFocus.RRect,
            contents: [
              TargetContent(
                align: ContentAlign.top,
                builder: (context, controller) {
                  return const Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "Canvas Toolbar",
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      Text(
                        "Switch between Pan and Link modes, zoom in/out, and save or run your flow here.",
                        style: TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ],
      );
    });
  }

  void _scheduleInitialLoad() {
    if (_initialLoadScheduled) return;
    _initialLoadScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final flowProvider = context.read<FlowProvider>();
      final endpointProvider = context.read<EndpointProvider>();
      await _canvasProvider?.loadFlowLayout(
        widget.flowId,
        flowProvider,
        endpointProvider.endpoints,
      );

      if (mounted) {
        context.read<RunProvider>().checkRunStatus(int.parse(widget.flowId));
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

    final endpoints = context.read<EndpointProvider>().endpoints;
    final flows = context.read<FlowProvider>().flows;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (endpoints.isNotEmpty) {
        _canvasProvider?.syncEndpointsMetadata(endpoints);
      }
      if (flows.isNotEmpty) {
        _canvasProvider?.syncFlowsMetadata(flows);
      }
    });
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
                transformationController: _transformationController,
                panEnabled: !canvasProvider.isLocked && canvasProvider.canvasMode == CanvasMode.move,
                scaleEnabled: !canvasProvider.isLocked,
                boundaryMargin: const EdgeInsets.all(4000),
                minScale: 0.1,
                maxScale: 2.0,
                constrained: false,
                child: Container(
                  width: 8000,
                  height: 8000,
                  color: Colors.transparent,
                  child: Stack(
                    children: [

                      Positioned.fill(
                        child: AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            return CustomPaint(
                              painter: _EdgeOverlayPainter(
                                nodes: canvasProvider.nodes,
                                connections: canvasProvider.connections,
                                animationOffset:
                                _animationController.value * 14.0,
                                colors: colors,
                              ),
                            );
                          },
                        ),
                      ),

                      ...canvasProvider.nodes.map(
                            (node) =>
                            _buildNodeWidget(node, canvasProvider, colors),
                      ),
                    ],
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
            child: Container(
              key: _toolbarKey,
              child: _buildUnifiedToolbar(context, colors, canvasProvider),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNodeWidget(
      CanvasNode node, CanvasProvider provider, ColorScheme colors) {
    return Positioned(
      left: node.position.dx,
      top: node.position.dy,
      width: node.actualWidth,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
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
        child: MouseRegion(
          cursor: provider.canvasMode == CanvasMode.move
              ? SystemMouseCursors.grab
              : SystemMouseCursors.click,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onPanUpdate: provider.canvasMode == CanvasMode.move
                    ? (details) {
                  final scale = _transformationController.value.getMaxScaleOnAxis();
                  provider.updateNodePosition(
                    node.id,
                    node.position + (details.delta / scale),
                  );
                }
                    : null,
                child:
                _NodeBody(node: node, provider: provider, colors: colors),
              ),
              if (provider.selectedSourceNodeId == node.id)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          node.type == FlowNodeType.branch ? 8 : 16,
                        ),
                        border:
                        Border.all(color: colors.primary, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: colors.primary.withValues(alpha: 0.3),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
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

  void _handleDrop(
      DragTargetDetails<DragData> details, BuildContext context) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Offset localOffset = renderBox.globalToLocal(details.offset);
    final Matrix4 transform = _transformationController.value;
    Offset canvasPosition;

    if (transform.determinant() != 0.0) {
      final Matrix4 inverse = Matrix4.inverted(transform);
      final Vector3 transformed =
      inverse.transform3(Vector3(localOffset.dx, localOffset.dy, 0));
      canvasPosition = Offset(transformed.x, transformed.y);
    } else {
      canvasPosition = localOffset;
    }

    final type = details.data.type;
    final newNode = CanvasNode(
      id: const Uuid().v4(),
      type: type,
      position: canvasPosition,
      data: details.data.payload,
      width: type == FlowNodeType.start
          ? 56
          : (type == FlowNodeType.branch
          ? 160
          : (type == FlowNodeType.subflow ? 180 : 160)),
      height: type == FlowNodeType.start
          ? 56
          : (type == FlowNodeType.branch
          ? 100
          : (type == FlowNodeType.subflow ? 64 : 100)),
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
      final endpointProvider = context.read<EndpointProvider>();

      canvasProvider.updateNodeData(node.id, result);

      final scaffoldMessenger =
          AppNavigator.scaffoldMessengerKey.currentState;
      final theme = Theme.of(context);

      try {
        await canvasProvider.saveFlowConfiguration(
          int.parse(widget.flowId),
          flowProvider,
          endpoints: endpointProvider.endpoints,
          flows: flowProvider.flows,
        );
        scaffoldMessenger?.showSnackBar(
          const SnackBar(content: Text('Node configuration saved')),
        );
      } catch (e) {
        scaffoldMessenger?.showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    }
  }

  void _showSubflowConfiguration(CanvasNode node) async {
    final initialId = node.data['subflowId']?.toString();
    final result = await showDialog<flow.Flow?>(
      context: context,
      builder: (context) =>
          SubflowConfigurationDialog(initialFlowId: initialId),
    );

    if (result != null && mounted) {
      final canvasProvider = context.read<CanvasProvider>();
      final flowProvider = context.read<FlowProvider>();
      final endpointProvider = context.read<EndpointProvider>();

      canvasProvider.updateNodeData(node.id, {
        'subflowId': result.id.toString(),
        'flowName': result.name,
      });

      final scaffoldMessenger =
          AppNavigator.scaffoldMessengerKey.currentState;
      final theme = Theme.of(context);

      try {
        await canvasProvider.saveFlowConfiguration(
          int.parse(widget.flowId),
          flowProvider,
          endpoints: endpointProvider.endpoints,
          flows: flowProvider.flows,
        );
        scaffoldMessenger?.showSnackBar(
          const SnackBar(content: Text('Subflow configuration saved')),
        );
      } catch (e) {
        scaffoldMessenger?.showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _showBranchConditionDialog(CanvasNode node) async {
    final controller = TextEditingController(
      text: node.data['condition']?.toString() ?? 'true',
    );
    final result = await showDialog<String?>(
      context: context,
      builder: (context) => _BranchDialog(controller: controller),
    );
    if (result != null && mounted) {
      context
          .read<CanvasProvider>()
          .updateNodeData(node.id, {'condition': result});
    }
  }

  void _showJsonPayload(BuildContext context) {
    final provider = context.read<CanvasProvider>();
    final steps = provider.generateFlowConfiguration();
    final initialValue = const JsonEncoder.withIndent('  ')
        .convert(steps.map((s) => s.toJson(includeMetadata: false)).toList());
    showDialog(
      context: context,
      builder: (context) =>
          _JsonPayloadDialog(initialValue: initialValue, provider: provider),
    );
  }

  void _showRunDialog(BuildContext context) {
    final flowProvider = context.read<FlowProvider>();
    showDialog(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: flowProvider,
        child: RunFlowDialog(flowId: int.parse(widget.flowId)),
      ),
    );
  }

  Widget _buildUnifiedToolbar(
      BuildContext context,
      ColorScheme colors,
      CanvasProvider provider,
      ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor =
    isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor =
    isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return ClipRRect(
      borderRadius: AppRadius.br16,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: surfaceColor.withValues(alpha: 0.92),
            borderRadius: AppRadius.br16,
            border: Border.all(color: borderColor.withValues(alpha: 0.3), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildModeButton(
                  provider, CanvasMode.move, Icons.pan_tool_rounded, 'Pan'),
              const SizedBox(width: 4),
              _buildModeButton(
                  provider, CanvasMode.connect, Icons.cable_rounded, 'Link'),
              _ToolbarDivider(borderColor: borderColor.withValues(alpha: 0.3)),
              _ToolbarIcon(
                tooltip: provider.isLocked ? 'Unlock Canvas' : 'Lock Canvas',
                onTap: () => provider.toggleLock(),
                icon: provider.isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
                color: provider.isLocked ? AppColors.accent : AppColors.textMuted,
              ),
              _ToolbarIcon(
                tooltip: 'Focus Graph',
                onTap: () => _focusGraph(),
                icon: Icons.filter_center_focus_rounded,
                color: AppColors.textMuted,
              ),
              _ToolbarIcon(
                tooltip: 'Zoom In',
                onTap: () => _zoom(1.2),
                icon: Icons.add_rounded,
                color: AppColors.textMuted,
              ),
              _ToolbarIcon(
                tooltip: 'Zoom Out',
                onTap: () => _zoom(0.8),
                icon: Icons.remove_rounded,
                color: AppColors.textMuted,
              ),
              _ToolbarDivider(borderColor: borderColor),
              _ToolbarIcon(
                tooltip: 'Show JSON',
                onTap: () => _showJsonPayload(context),
                icon: Icons.code_rounded,
                color: AppColors.textMuted,
              ),
              _ToolbarIcon(
                tooltip: 'Clear Canvas',
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: colors.surface,
                      title: const Text('Clear Canvas?'),
                      content: const Text(
                          'This will remove all nodes and connections.'),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: colors.error,
                            foregroundColor: colors.onError,
                          ),
                          onPressed: () =>
                              Navigator.of(context).pop(true),
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
                  final flowProvider =
                  context.read<FlowProvider>();
                  final endpointProvider =
                  context.read<EndpointProvider>();
                  final scaffoldMessenger =
                      AppNavigator.scaffoldMessengerKey.currentState;
                  try {
                    await provider.saveFlowConfiguration(
                      int.parse(widget.flowId),
                      flowProvider,
                      endpoints: endpointProvider.endpoints,
                      flows: flowProvider.flows,
                    );
                    scaffoldMessenger?.showSnackBar(
                      const SnackBar(content: Text('Flow saved.')),
                    );
                  } catch (e) {
                    scaffoldMessenger?.showSnackBar(
                      SnackBar(content: Text('Error saving: $e')),
                    );
                  }
                },
                icon: Icons.save_outlined,
                color: provider.isSaving
                    ? AppColors.textMuted
                    : AppColors.textSecondary,
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

  void _zoom(double factor) {
    final Matrix4 current = _transformationController.value;

    final Size size = MediaQuery.of(context).size;
    final Offset center = Offset(size.width / 2, size.height / 2);

    final Matrix4 zoomMatrix = Matrix4.identity()
      ..multiply(Matrix4.translationValues(center.dx, center.dy, 0.0))
      ..multiply(Matrix4.diagonal3Values(factor, factor, 1.0))
      ..multiply(Matrix4.translationValues(-center.dx, -center.dy, 0.0));

    final Matrix4 next = zoomMatrix * current;

    final double nextScale = next.getMaxScaleOnAxis();
    if (nextScale < 0.1 || nextScale > 5.0) return;

    setState(() {
      _transformationController.value = next;
    });
  }

  void _focusGraph() {
    final provider = context.read<CanvasProvider>();
    if (provider.nodes.isEmpty) return;

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final node in provider.nodes) {
      if (node.position.dx < minX) minX = node.position.dx;
      if (node.position.dy < minY) minY = node.position.dy;
      if (node.position.dx + node.width > maxX) maxX = node.position.dx + node.width;
      if (node.position.dy + node.height > maxY) maxY = node.position.dy + node.height;
    }

    final double graphWidth = maxX - minX;
    final double graphHeight = maxY - minY;
    final Offset graphCenter = Offset(minX + graphWidth / 2, minY + graphHeight / 2);

    final Size viewportSize = MediaQuery.of(context).size;
    final Offset viewportCenter = Offset(viewportSize.width / 2, viewportSize.height / 2);

    final double scaleX = (viewportSize.width * 0.8) / graphWidth;
    final double scaleY = (viewportSize.height * 0.8) / graphHeight;
    double scale = scaleX < scaleY ? scaleX : scaleY;
    scale = scale.clamp(0.2, 1.5);

    final Matrix4 matrix = Matrix4.identity()
      ..multiply(Matrix4.translationValues(viewportCenter.dx, viewportCenter.dy, 0.0))
      ..multiply(Matrix4.diagonal3Values(scale, scale, 1.0))
      ..multiply(Matrix4.translationValues(-graphCenter.dx, -graphCenter.dy, 0.0));

    setState(() {
      _transformationController.value = matrix;
    });
  }

  Widget _buildModeButton(
      CanvasProvider provider,
      CanvasMode mode,
      IconData icon,
      String label,
      ) {
    final isSelected = provider.canvasMode == mode;
    return Tooltip(
      message: label,
      child: GestureDetector(
        onTap: () => provider.setCanvasMode(mode),
        child: AnimatedContainer(
          duration: AppDurations.micro,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.accent.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: AppRadius.br8,
            border: Border.all(
              color: isSelected
                  ? AppColors.accent.withValues(alpha: 0.5)
                  : Colors.transparent,
            ),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isSelected ? AppColors.accent : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

class _HoverableNodeWrapper extends StatefulWidget {
  final CanvasNode node;
  final CanvasProvider provider;
  final Widget child;

  const _HoverableNodeWrapper({
    required this.node,
    required this.provider,
    required this.child,
  });

  @override
  State<_HoverableNodeWrapper> createState() => _HoverableNodeWrapperState();
}

class _HoverableNodeWrapperState extends State<_HoverableNodeWrapper> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          widget.child,
          if (_hovered && !widget.provider.isLocked)
            Positioned(
              top: -8,
              right: -8,
              child: GestureDetector(
                onTap: () => widget.provider.removeNode(widget.node.id),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 12, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EdgeOverlayPainter extends CustomPainter {
  final List<CanvasNode> nodes;
  final List<CanvasConnection> connections;
  final double animationOffset;
  final ColorScheme colors;

  _EdgeOverlayPainter({
    required this.nodes,
    required this.connections,
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
      final sourceNode =
          nodes.where((n) => n.id == conn.sourceNodeId).firstOrNull;
      final targetNode =
          nodes.where((n) => n.id == conn.targetNodeId).firstOrNull;
      if (sourceNode == null || targetNode == null) continue;

      final start = sourceNode.position +
          Offset(sourceNode.actualWidth / 2, sourceNode.actualHeight / 2);
      final end = targetNode.position +
          Offset(targetNode.actualWidth / 2, targetNode.actualHeight / 2);

      _drawAnimatedDashes(canvas, start, end, paint);

      if (sourceNode.type == FlowNodeType.branch) {
        _drawLabel(
          canvas,
          start,
          end,
          conn.type == ConnectionType.trueType ? 'T' : 'F',
        );
      }
    }
  }

  void _drawAnimatedDashes(
      Canvas canvas, Offset start, Offset end, Paint paint) {
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..lineTo(end.dx, end.dy);

    const dashWidth = 8.0;
    const dashSpace = 6.0;

    for (final metric in path.computeMetrics()) {
      double distance = -animationOffset % (dashWidth + dashSpace);
      while (distance < metric.length) {
        final s = distance.clamp(0.0, metric.length);
        final e = (distance + dashWidth).clamp(0.0, metric.length);
        if (s < e) canvas.drawPath(metric.extractPath(s, e), paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  void _drawLabel(
      Canvas canvas, Offset start, Offset end, String text) {
    final mid = Offset(
      (start.dx * 3 + end.dx) / 4,
      (start.dy * 3 + end.dy) / 4,
    );
    final tp = TextPainter(
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
    )..layout();
    tp.paint(canvas, mid - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _EdgeOverlayPainter old) => true;
}

class _NodeBody extends StatelessWidget {
  final CanvasNode node;
  final CanvasProvider provider;
  final ColorScheme colors;

  const _NodeBody(
      {required this.node, required this.provider, required this.colors});

  @override
  Widget build(BuildContext context) {
    switch (node.type) {
      case FlowNodeType.start:
        return _buildStart(context);
      case FlowNodeType.branch:
        return _buildBranch();
      case FlowNodeType.subflow:
        return _buildSubflow();
      case FlowNodeType.endpoint:
        return _buildStandard();
    }
  }

  Widget _buildStandard() {
    final type = node.data['type'] ?? 'HTTP';
    final methodColor = _getTypeColor(type);
    final hasPre = node.data['preProcessor'] != null &&
        (node.data['preProcessor'] as Map).isNotEmpty;
    final hasPost = node.data['postProcessor'] != null &&
        (node.data['postProcessor'] as Map).isNotEmpty;

    return Container(
      width: node.width,
      constraints: BoxConstraints(minHeight: node.height),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: colors.outlineVariant.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
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
                      ),
                    ),
                  ),
                  if (node.data['method'] != null) ...[
                    const SizedBox(width: 4),
                    Text(
                      node.data['method'].toString().toUpperCase(),
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: colors.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
              IconButton(
                onPressed: () => provider.removeNode(node.id),
                icon: const Icon(Icons.close, size: 14),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            node.data['name'] ?? 'Endpoint',
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            node.data['url'] ?? 'Action node',
            style: TextStyle(
              fontSize: 10,
              color: colors.onSurfaceVariant,
              fontFamily: 'JetBrains Mono',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              if (hasPre)
                _InfoBadge(
                    icon: Icons.login_rounded,
                    label: 'PRE',
                    color: Colors.orange),
              if (hasPost)
                _InfoBadge(
                    icon: Icons.logout_rounded,
                    label: 'POST',
                    color: Colors.purple),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubflow() {
    return Container(
      width: node.width,
      height: node.height,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.br12,
        border: Border.all(color: colors.secondary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Stack(
        children: [

          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 4,
            child: Container(
              decoration: BoxDecoration(
                color: colors.secondary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: colors.secondary.withValues(alpha: 0.1),
                    borderRadius: AppRadius.br8,
                  ),
                  child: Icon(Icons.account_tree_rounded,
                      size: 20, color: colors.secondary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'SUBFLOW',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: colors.secondary,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Text(
                        node.data['flowName'] ?? 'Select flow...',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    size: 16, color: colors.onSurfaceVariant.withValues(alpha: 0.5)),
              ],
            ),
          ),

          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              onPressed: () => provider.removeNode(node.id),
              icon: const Icon(Icons.close, size: 14),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              splashRadius: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStart(BuildContext context) {
    return _HoverableNodeWrapper(
      node: node,
      provider: provider,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: AppGradients.green(Theme.of(context).brightness == Brightness.dark),
          borderRadius: AppRadius.br16,
          border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.lightGreenStart.withValues(alpha: 0.3),
              blurRadius: 12,
              spreadRadius: 2,
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
            Text(
              'START',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w900,
                color: Colors.white.withValues(alpha: 0.9),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBranch() {
    return SizedBox(
      width: node.actualWidth,
      height: node.actualHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // The Rotated Square (Diamond)
          Transform.rotate(
            angle: 3.14159 / 4, // 45 degrees
            child: Container(
              width: node.actualWidth * 0.7, // Fit within bounds when rotated
              height: node.actualHeight * 0.7,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.primary.withValues(alpha: 0.5), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.1),
                    blurRadius: 8,
                  )
                ],
              ),
            ),
          ),
          
          // Label content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.call_split_rounded, size: 16, color: colors.primary),
              const SizedBox(height: 2),
              Text(
                'BRANCH',
                style: AppTypography.label.copyWith(
                  fontWeight: FontWeight.w900,
                  color: colors.primary,
                ),
              ),
            ],
          ),

          // TRUE Pipe (Left)
          Positioned(
            left: -12,
            child: _BranchHandle(
              label: 'TRUE',
              shortLabel: 'T',
              color: Colors.green,
              isSelected: provider.selectedSourceNodeId == node.id &&
                  provider.selectedSourceHandle == 'true',
              onTap: () => provider.selectSourceNode(node.id, 'true'),
            ),
          ),

          // FALSE Pipe (Right)
          Positioned(
            right: -12,
            child: _BranchHandle(
              label: 'FALSE',
              shortLabel: 'F',
              color: Colors.red,
              isSelected: provider.selectedSourceNodeId == node.id &&
                  provider.selectedSourceHandle == 'false',
              onTap: () => provider.selectSourceNode(node.id, 'false'),
            ),
          ),

          // Close Button
          Positioned(
            top: -12,
            right: -12,
            child: IconButton(
              onPressed: () => provider.removeNode(node.id),
              icon: const Icon(Icons.close, size: 14),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              splashRadius: 12,
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
      default:
        return Colors.blueGrey;
    }
  }
}

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoBadge(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 2),
          Text(label,
              style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: color)),
        ],
      ),
    );
  }
}

class _BranchHandle extends StatelessWidget {
  final String label;
  final String shortLabel;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _BranchHandle({
    required this.label,
    required this.shortLabel,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isSelected ? color : color.withValues(alpha: 0.1),
            border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: isSelected ? color.withValues(alpha: 0.4) : Colors.black12,
                blurRadius: isSelected ? 8 : 4,
                spreadRadius: isSelected ? 1 : 0,
              )
            ],
          ),
          child: Center(
            child: Text(
              shortLabel,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: isSelected ? Colors.white : color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BranchDialog extends StatelessWidget {
  final TextEditingController controller;
  const _BranchDialog({required this.controller});

  @override
  Widget build(BuildContext context) {
    return PilotDialog(
      title: 'Edit Branch Condition',
      maxWidth: 400,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enter the expression to evaluate. "response" and "env" variables are available.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          PilotInput(
            controller: controller,
            placeholder: 'e.g. response.status == 200',
            autofocus: true,
          ),
        ],
      ),
      actions: [
        PilotButton.ghost(
          label: 'Cancel',
          onPressed: () => Navigator.pop(context),
        ),
        PilotButton.primary(
          label: 'Save',
          onPressed: () => Navigator.pop(context, controller.text),
        ),
      ],
    );
  }
}

class _JsonPayloadDialog extends StatefulWidget {
  final String initialValue;
  final CanvasProvider provider;

  const _JsonPayloadDialog(
      {required this.initialValue, required this.provider});

  @override
  State<_JsonPayloadDialog> createState() => _JsonPayloadDialogState();
}

class _JsonPayloadDialogState extends State<_JsonPayloadDialog> {
  late CodeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CodeController(
      text: widget.initialValue,
      language: json,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _formatJson() {
    try {
      final obj = jsonDecode(_controller.text);
      const encoder = JsonEncoder.withIndent('  ');
      setState(() {
        _controller.text = encoder.convert(obj);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid JSON: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final size = MediaQuery.of(context).size;

    return Dialog(
      backgroundColor: colors.surface,
      child: Container(
        width: size.width * 0.8,
        height: size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Edit Flow JSON', style: AppTypography.title),
                const Spacer(),
                PilotButton.ghost(
                  label: 'Auto Format',
                  icon: Icons.format_align_left_rounded,
                  onPressed: _formatJson,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: colors.outlineVariant),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CodeTheme(
                  data: CodeThemeData(styles: monokaiSublimeTheme),
                  child: CodeField(
                    controller: _controller,
                    expands: true,
                    maxLines: null,
                    minLines: null,
                    gutterStyle: GutterStyle(
                      showLineNumbers: true,
                      showFoldingHandles: true,
                      background: isDark ? AppColors.darkElevated : Colors.grey[100]!,
                    ),
                    textStyle: const TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: () {
                    try {
                      final List<dynamic> jsonList =
                      jsonDecode(_controller.text);
                      final newSteps = jsonList
                          .map((e) => flow.FlowStep.fromJson(e))
                          .toList();
                      widget.provider.applyConfiguration(newSteps);
                      Navigator.pop(context);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Invalid JSON: $e'),
                            backgroundColor: colors.error),
                      );
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
    return Container(
      width: 1,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: borderColor,
    );
  }
}

class _ToolbarIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback? onTap;
  final bool loading;

  const _ToolbarIcon({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
    this.loading = false,
  });

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
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _hovered
                  ? widget.color.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: AppRadius.br8,
            ),
            child: widget.loading
                ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 1.5),
            )
                : Icon(widget.icon, size: 16, color: widget.color),
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
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
      ),
    );
  }
}
