import 'package:flutter/material.dart';
import 'package:stress_pilot/features/projects/presentation/provider/flow_provider.dart';
import 'package:stress_pilot/features/projects/domain/flow.dart' as flow;
import '../flow_dialog.dart';

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
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                'FLOWS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: colors.onSurfaceVariant,
                  letterSpacing: 1.0,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add, size: 18),
                tooltip: 'Create Flow',
                onPressed: () {
                  FlowDialog.showCreateDialog(
                    context,
                    onCreate: (name, description, projectId) async {
                      await flowProvider.createFlow(
                        flow.CreateFlowRequest(
                          projectId: projectId,
                          name: name,
                          description: description,
                        ),
                      );
                    },
                  );
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ),
        Expanded(
          child: flowProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : flowProvider.flows.isEmpty
              ? Center(
                  child: Text(
                    'No flows',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: flowProvider.flows.length,
                  itemBuilder: (context, index) {
                    final flowItem = flowProvider.flows[index];
                    final isSelected = selectedFlow?.id == flowItem.id;

                    return Container(
                      decoration: BoxDecoration(
                        border: isSelected
                            ? Border(
                                left: BorderSide(
                                  color: colors.primary,
                                  width: 3,
                                ),
                              )
                            : null,
                      ),
                      child: InkWell(
                        onTap: () {
                          onFlowSelected(flowItem);
                          flowProvider.selectFlow(flowItem);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.subdirectory_arrow_right,
                                size: 16,
                                color: isSelected
                                    ? colors.primary
                                    : colors.onSurfaceVariant,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  flowItem.name,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? colors.onSurface
                                        : colors.onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isSelected)
                                GestureDetector(
                                  onTap: () => _showOptions(
                                    context,
                                    flowItem,
                                    flowProvider,
                                  ),
                                  child: Icon(
                                    Icons.more_horiz,
                                    size: 16,
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                            ],
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

  void _showOptions(
    BuildContext context,
    flow.Flow flowItem,
    FlowProvider provider,
  ) {}
}
