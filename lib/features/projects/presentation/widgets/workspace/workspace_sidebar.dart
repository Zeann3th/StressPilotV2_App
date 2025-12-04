import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stress_pilot/features/projects/presentation/provider/flow_provider.dart';
import 'package:stress_pilot/features/projects/presentation/provider/project_provider.dart';
import 'package:stress_pilot/features/projects/domain/flow.dart' as flow;
import 'package:stress_pilot/features/projects/presentation/widgets/workspace/workspace_flow_list.dart';
import 'package:stress_pilot/features/projects/presentation/widgets/workspace/workspace_endpoints_list.dart';

import '../../../domain/canvas.dart';

class WorkspaceSidebar extends StatefulWidget {
  final SidebarTab sidebarTab;
  final ValueChanged<SidebarTab> onTabChanged;
  final flow.Flow? selectedFlow;
  final ValueChanged<flow.Flow?> onFlowSelected;

  const WorkspaceSidebar({
    super.key,
    required this.sidebarTab,
    required this.onTabChanged,
    required this.selectedFlow,
    required this.onFlowSelected,
  });

  @override
  State<WorkspaceSidebar> createState() => _WorkspaceSidebarState();
}

class _WorkspaceSidebarState extends State<WorkspaceSidebar> {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final flowProvider = context.watch<FlowProvider>();
    // Get the current project ID from ProjectProvider
    final projectProvider = context.watch<ProjectProvider>();
    final projectId = projectProvider.selectedProject?.id ?? 0; // Default to 0 or handle null appropriately

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
          // Tab Selector
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: colors.outlineVariant, width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton(
                    label: 'Flows',
                    icon: Icons.alt_route,
                    isActive: widget.sidebarTab == SidebarTab.flows,
                    onTap: () => widget.onTabChanged(SidebarTab.flows),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTabButton(
                    label: 'Nodes', // Đổi tên thành Nodes để bao gồm cả Logic Nodes
                    icon: Icons.dns_outlined,
                    isActive: widget.sidebarTab == SidebarTab.endpoints,
                    onTap: () => widget.onTabChanged(SidebarTab.endpoints),
                  ),
                ),
              ],
            ),
          ),
          // Content based on active tab
          Expanded(
            child: widget.sidebarTab == SidebarTab.flows
                ? WorkspaceFlowList(
              flowProvider: flowProvider,
              selectedFlow: widget.selectedFlow,
              onFlowSelected: widget.onFlowSelected,
            )
                : Column(
              children: [
                // Logic Nodes Section (Start, Branch)
                _buildLogicNodesSection(context),
                const Divider(height: 1),
                // Endpoints List
                Expanded(
                  child: WorkspaceEndpointsList(
                    selectedFlow: widget.selectedFlow,
                    projectId: projectId, // Pass the projectId here
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogicNodesSection(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LOGIC',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Bọc Draggable bằng Expanded
              Expanded(
                child: _buildDraggableLogicNode(
                  context,
                  FlowNodeType.start,
                  'Start',
                  Icons.play_circle_outline,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDraggableLogicNode(
                  context,
                  FlowNodeType.branch,
                  'Branch',
                  Icons.call_split,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDraggableLogicNode(
      BuildContext context,
      FlowNodeType type,
      String label,
      IconData icon,
      Color color,
      ) {
    final colors = Theme.of(context).colorScheme;
    final dragData = DragData(type: type, payload: {'name': label});

    // Loại bỏ Expanded khỏi đây
    return Draggable<DragData>(
      data: dragData,
      feedback: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 100,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color, width: 2),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
      child: Container( // Thay thế Expanded bằng Container
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Column(
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: isActive ? colors.primaryContainer : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isActive
                    ? colors.onPrimaryContainer
                    : colors.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive
                      ? colors.onPrimaryContainer
                      : colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}