import 'package:flutter/material.dart';
import 'package:stress_pilot/features/projects/presentation/provider/flow_provider.dart';
import 'package:stress_pilot/features/projects/domain/flow.dart' as flow;

enum SidebarTab { flows, endpoints }

class WorkspaceFlowList extends StatelessWidget {
  final FlowProvider flowProvider;
  final flow.Flow? selectedFlow;
  final ValueChanged<flow.Flow?> onFlowSelected;

  const WorkspaceFlowList({
    super.key,
    required this.flowProvider,
    required this.selectedFlow,
    required this.onFlowSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Text(
                'FLOWS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add, size: 18),
                tooltip: 'Create Flow',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Create flow coming soon')),
                  );
                },
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
        Expanded(
          child: flowProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : flowProvider.flows.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.alt_route,
                              size: 48,
                              color: colors.onSurfaceVariant.withAlpha(100),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No flows yet',
                              style: TextStyle(
                                color: colors.onSurfaceVariant,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: flowProvider.flows.length,
                      itemBuilder: (context, index) {
                        final flow = flowProvider.flows[index];
                        final isSelected = selectedFlow?.id == flow.id;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Material(
                            color: isSelected
                                ? colors.secondaryContainer
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            child: InkWell(
                              onTap: () {
                                onFlowSelected(flow);
                                flowProvider.selectFlow(flow);
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.layers_outlined,
                                      size: 18,
                                      color: isSelected
                                          ? colors.onSecondaryContainer
                                          : colors.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            flow.name,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: isSelected
                                                  ? FontWeight.w600
                                                  : FontWeight.w500,
                                              color: isSelected
                                                  ? colors.onSecondaryContainer
                                                  : colors.onSurface,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (flow.description != null) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              flow.description!,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isSelected
                                                    ? colors.onSecondaryContainer
                                                          .withAlpha(200)
                                                    : colors.onSurfaceVariant,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    PopupMenuButton(
                                      icon: Icon(
                                        Icons.more_vert,
                                        size: 18,
                                        color: colors.onSurfaceVariant,
                                      ),
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit_outlined, size: 18),
                                              SizedBox(width: 8),
                                              Text('Edit'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'duplicate',
                                          child: Row(
                                            children: [
                                              Icon(Icons.content_copy, size: 18),
                                              SizedBox(width: 8),
                                              Text('Duplicate'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete_outline, size: 18),
                                              SizedBox(width: 8),
                                              Text('Delete'),
                                            ],
                                          ),
                                        ),
                                      ],
                                      onSelected: (value) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('$value coming soon'),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
