import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stress_pilot/features/projects/presentation/provider/flow_provider.dart';
import 'package:stress_pilot/features/projects/domain/flow.dart' as flow_domain;
import 'package:stress_pilot/features/projects/presentation/widgets/flow_dialog.dart';

class WorkspaceSidebar extends StatelessWidget {
  final Function(flow_domain.Flow) onFlowSelected;

  const WorkspaceSidebar({super.key, required this.onFlowSelected});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        border: Border(
          right: BorderSide(color: colors.outlineVariant, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Flows',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: 'Create Flow',
                  onPressed: () => _handleCreateFlow(context),
                  style: IconButton.styleFrom(
                    backgroundColor: colors.primaryContainer,
                    foregroundColor: colors.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Flow List
          Expanded(
            child: Consumer<FlowProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.error != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: colors.error,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Error loading flows',
                            style: TextStyle(color: colors.error),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => provider.loadFlows(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (provider.flows.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.layers_outlined,
                            size: 48,
                            color: colors.onSurfaceVariant,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No flows yet',
                            style: TextStyle(color: colors.onSurfaceVariant),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: () => _handleCreateFlow(context),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Create Flow'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: provider.flows.length,
                  itemBuilder: (context, index) {
                    final flowItem = provider.flows[index];
                    final isSelected = provider.selectedFlow?.id == flowItem.id;

                    return _FlowListItem(
                      flow: flowItem,
                      isSelected: isSelected,
                      onTap: () => onFlowSelected(flowItem),
                      onEdit: () => _handleEditFlow(context, flowItem),
                      onDelete: () => _handleDeleteFlow(context, flowItem),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _handleCreateFlow(BuildContext context) {
    FlowDialog.showCreateDialog(
      context,
      onCreate: (name, description, projectId) async {
        final request = flow_domain.CreateFlowRequest(
          name: name,
          description: description,
          projectId: projectId,
        );
        await context.read<FlowProvider>().createFlow(request);
      },
    );
  }

  void _handleEditFlow(BuildContext context, flow_domain.Flow flowItem) {
    FlowDialog.showEditDialog(
      context,
      flow: flowItem,
      onUpdate: (id, name, description) async {
        await context.read<FlowProvider>().updateFlow(
          flowId: id,
          name: name,
          description: description,
        );
      },
    );
  }

  void _handleDeleteFlow(BuildContext context, flow_domain.Flow flowItem) {
    FlowDialog.showDeleteDialog(
      context,
      flow: flowItem,
      onDelete: (id) async {
        await context.read<FlowProvider>().deleteFlow(id);
      },
    );
  }
}

class _FlowListItem extends StatelessWidget {
  final flow_domain.Flow flow;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _FlowListItem({
    required this.flow,
    required this.isSelected,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? colors.primaryContainer : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          Icons.layers_outlined,
          size: 20,
          color: isSelected
              ? colors.onPrimaryContainer
              : colors.onSurfaceVariant,
        ),
        title: Text(
          flow.name,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? colors.onPrimaryContainer : null,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: flow.description != null
            ? Text(
                flow.description!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSelected
                      ? colors.onPrimaryContainer.withValues(alpha: 0.7)
                      : null,
                ),
              )
            : null,
        trailing: PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert,
            size: 18,
            color: isSelected ? colors.onPrimaryContainer : null,
          ),
          onSelected: (value) {
            if (value == 'edit') {
              onEdit();
            } else if (value == 'delete') {
              onDelete();
            }
          },
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
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outlined, size: 18),
                  SizedBox(width: 8),
                  Text('Delete'),
                ],
              ),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
