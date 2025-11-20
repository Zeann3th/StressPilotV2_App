import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stress_pilot/features/projects/presentation/provider/flow_provider.dart';
import 'package:stress_pilot/features/projects/domain/flow.dart' as flow;
import 'package:stress_pilot/features/projects/presentation/widgets/workspace/workspace_flow_list.dart';
import 'package:stress_pilot/features/projects/presentation/widgets/workspace/workspace_endpoints_list.dart';

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
                    label: 'Endpoints',
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
                : WorkspaceEndpointsList(selectedFlow: widget.selectedFlow),
          ),
        ],
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
