import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/features/workspace/presentation/provider/workspace_tab_provider.dart';
import 'package:stress_pilot/features/endpoints/domain/models/endpoint.dart';
import 'package:stress_pilot/features/projects/domain/models/flow.dart' as flow_domain;
import 'package:stress_pilot/features/endpoints/presentation/provider/endpoint_provider.dart';
import 'package:stress_pilot/features/projects/presentation/provider/flow_provider.dart';

class WorkspaceTabBar extends StatelessWidget {
  const WorkspaceTabBar({super.key});

  @override
  Widget build(BuildContext context) {
    final tabProvider = context.watch<WorkspaceTabProvider>();
    final tabs = tabProvider.tabs;
    final activeTab = tabProvider.activeTab;

    return Container(
      height: AppSpacing.tabBarHeight,
      color: Colors.transparent,
      child: Row(
        children: [
          Expanded(
            child: ReorderableListView.builder(
              scrollDirection: Axis.horizontal,
              onReorder: tabProvider.reorderTabs,
              itemCount: tabs.length,
              proxyDecorator: (child, index, animation) => Material(
                color: Colors.transparent,
                child: child,
              ),
              buildDefaultDragHandles: false, // Remove default handles
              itemBuilder: (context, index) {
                final tab = tabs[index];
                return ReorderableDragStartListener(
                  key: ValueKey('${tab.type}_${tab.id}'),
                  index: index,
                  child: _WorkspaceTabWidget(
                    tab: tab,
                    isActive: activeTab == tab,
                    onTap: () => tabProvider.selectTab(tab),
                    onClose: () => tabProvider.closeTab(tab),
                  ),
                );
              },
            ),
          ),
          if (tabs.isNotEmpty)
            PopupMenuButton<WorkspaceTab>(
              icon: Icon(LucideIcons.chevronDown, size: 16, color: AppColors.textSecondary),
              tooltip: 'Show all tabs',
              onSelected: (tab) => tabProvider.selectTab(tab),
              offset: const Offset(0, 40),
              itemBuilder: (context) => tabs.map((tab) {
                return PopupMenuItem<WorkspaceTab>(
                  value: tab,
                  child: Row(
                    children: [
                      Icon(
                        tab.type == WorkspaceTabType.flow ? LucideIcons.gitFork : LucideIcons.link,
                        size: 14,
                        color: activeTab == tab ? AppColors.accent : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          tab.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.body.copyWith(
                            fontSize: 13,
                            color: activeTab == tab ? AppColors.textPrimary : AppColors.textSecondary,
                            fontWeight: activeTab == tab ? FontWeight.w500 : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _WorkspaceTabWidget extends StatefulWidget {
  final WorkspaceTab tab;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const _WorkspaceTabWidget({
    required this.tab,
    required this.isActive,
    required this.onTap,
    required this.onClose,
  });

  @override
  State<_WorkspaceTabWidget> createState() => _WorkspaceTabWidgetState();
}

class _WorkspaceTabWidgetState extends State<_WorkspaceTabWidget> {
  bool _isHovered = false;
  bool _isEditing = false;
  late TextEditingController _editCtrl;

  @override
  void initState() {
    super.initState();
    _editCtrl = TextEditingController(text: widget.tab.name);
  }

  @override
  void dispose() {
    _editCtrl.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
      _editCtrl.text = widget.tab.name;
    });
  }

  void _submitRename() {
    final newName = _editCtrl.text.trim();
    if (newName.isNotEmpty && newName != widget.tab.name) {
      final tabProvider = context.read<WorkspaceTabProvider>();
      tabProvider.renameTab(widget.tab.id, widget.tab.type, newName);
      
      // Update underlying data based on type
      if (widget.tab.type == WorkspaceTabType.endpoint) {
        final endpoint = widget.tab.data as Endpoint;
        context.read<EndpointProvider>().updateEndpoint(endpoint.id, {'name': newName});
      } else {
        final flow = widget.tab.data as flow_domain.Flow;
        context.read<FlowProvider>().updateFlow(flowId: flow.id, name: newName);
      }
    }
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onDoubleTap: _startEditing,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: widget.isActive ? AppColors.activeItem : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: widget.isActive ? AppColors.accent : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.tab.type == WorkspaceTabType.flow ? LucideIcons.gitFork : LucideIcons.link,
                size: 13,
                color: widget.isActive ? AppColors.accent : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              if (_isEditing)
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: _editCtrl,
                    autofocus: true,
                    style: AppTypography.body.copyWith(fontSize: 12),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _submitRename(),
                    onTapOutside: (_) => _submitRename(),
                  ),
                )
              else
                Text(
                  widget.tab.name,
                  style: AppTypography.body.copyWith(
                    color: widget.isActive ? AppColors.textPrimary : AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: widget.isActive ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              const SizedBox(width: 8),
              if ((_isHovered || widget.isActive) && !_isEditing)
                GestureDetector(
                  onTap: widget.onClose,
                  child: Icon(LucideIcons.x, size: 12, color: AppColors.textSecondary),
                )
              else
                const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }
}
