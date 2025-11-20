import 'package:flutter/material.dart';
import 'package:stress_pilot/features/projects/domain/flow.dart' as flow;

class WorkspaceCanvas extends StatelessWidget {
  final flow.Flow? selectedFlow;
  const WorkspaceCanvas({super.key, required this.selectedFlow});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (selectedFlow == null) {
      return Container(
        color: colors.surface,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.layers_outlined,
                size: 64,
                color: colors.onSurfaceVariant.withAlpha(128),
              ),
              const SizedBox(height: 16),
              Text(
                'Select a flow to get started',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose a flow from the sidebar or create a new one',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant.withAlpha(180),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Container(
      color: colors.surface,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: colors.outlineVariant, width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedFlow!.name,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (selectedFlow!.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          selectedFlow!.description!,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Configure coming soon')),
                    );
                  },
                  icon: const Icon(Icons.settings_outlined, size: 18),
                  label: const Text('Configure'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Run coming soon')),
                    );
                  },
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text('Run'),
                ),
              ],
            ),
          ),
          Expanded(
            child: DragTarget<Map<String, String>>(
              onAcceptWithDetails: (details) {
                final endpoint = details.data;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Added ${endpoint['name']} to flow'),
                    duration: const Duration(seconds: 2),
                  ),
                );
                // TODO: Add endpoint to flow at drop position
              },
              builder: (context, candidateData, rejectedData) {
                final isHovering = candidateData.isNotEmpty;
                return Container(
                  margin: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isHovering
                        ? colors.primaryContainer.withAlpha(30)
                        : colors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isHovering
                          ? colors.primary
                          : colors.outlineVariant,
                      width: isHovering ? 2 : 1,
                    ),
                  ),
                  child: Stack(
                    children: [
                      CustomPaint(
                        size: Size.infinite,
                        painter: GridPainter(
                          color: colors.outlineVariant.withAlpha(50),
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isHovering
                                  ? Icons.add_circle_outline
                                  : Icons.account_tree_outlined,
                              size: 64,
                              color: isHovering
                                  ? colors.primary
                                  : colors.onSurfaceVariant.withAlpha(128),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              isHovering
                                  ? 'Drop endpoint here'
                                  : 'Drag endpoints from sidebar',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: isHovering
                                        ? colors.primary
                                        : colors.onSurfaceVariant,
                                    fontWeight: isHovering
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isHovering
                                  ? 'Release to add to flow'
                                  : 'Build your flow by connecting endpoints',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: colors.onSurfaceVariant.withAlpha(
                                      180,
                                    ),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  final Color color;
  GridPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const spacing = 20.0;
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

