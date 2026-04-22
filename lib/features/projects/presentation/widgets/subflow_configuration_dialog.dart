import 'dart:async';
import 'package:flutter/material.dart' hide Flow;
import 'package:provider/provider.dart';
import 'package:stress_pilot/core/themes/components/components.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/features/projects/domain/models/flow.dart';
import 'package:stress_pilot/features/shared/presentation/provider/flow_provider.dart';

class SubflowConfigurationDialog extends StatefulWidget {
  final String? initialFlowId;

  const SubflowConfigurationDialog({super.key, this.initialFlowId});

  @override
  State<SubflowConfigurationDialog> createState() =>
      _SubflowConfigurationDialogState();
}

class _SubflowConfigurationDialogState extends State<SubflowConfigurationDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Flow> _filteredFlows = [];
  Timer? _debounce;
  Flow? _selectedFlow;

  @override
  void initState() {
    super.initState();
    _loadInitialFlow();
  }

  Future<void> _loadInitialFlow() async {
    if (widget.initialFlowId == null) return;

    final flowProvider = context.read<FlowProvider>();
    final flows = flowProvider.flows;
    final found = flows.where((f) => f.id.toString() == widget.initialFlowId).firstOrNull;

    if (found != null) {
      setState(() {
        _selectedFlow = found;
        _searchController.text = found.name;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _filterFlows(query);
    });
  }

  void _filterFlows(String query) {
    final flowProvider = context.read<FlowProvider>();
    final flows = flowProvider.flows;

    setState(() {
      if (query.isEmpty) {
        _filteredFlows = [];
      } else {
        _filteredFlows = flows
            .where((f) => f.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PilotDialog(
      title: 'Configure Subflow',
      maxWidth: 480,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select a flow to execute as a subflow.',
            style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          PilotInput(
            controller: _searchController,
            placeholder: 'Search flow by name...',
            prefixIcon: Icons.search,
            onChanged: _onSearchChanged,
          ),
          if (_filteredFlows.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: AppRadius.br8,
                color: AppColors.elevated,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _filteredFlows.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: AppColors.border,
                ),
                itemBuilder: (context, index) {
                  final flow = _filteredFlows[index];
                  return ListTile(
                    title: Text(flow.name, style: AppTypography.body),
                    onTap: () {
                      setState(() {
                        _selectedFlow = flow;
                        _searchController.text = flow.name;
                        _filteredFlows = [];
                      });
                    },
                    hoverColor: AppColors.accent.withValues(alpha: 0.1),
                  );
                },
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (_selectedFlow != null)
          PilotButton.ghost(
            label: 'Navigate',
            icon: Icons.open_in_new,
            onPressed: () {
              context.read<FlowProvider>().selectFlow(_selectedFlow!);
              Navigator.of(context).pop();
            },
          ),
        PilotButton.ghost(
          label: 'Cancel',
          onPressed: () => Navigator.of(context).pop(),
        ),
        PilotButton.primary(
          label: 'Apply',
          onPressed: _selectedFlow == null
              ? null
              : () {
                  Navigator.of(context).pop(_selectedFlow!);
                },
        ),
      ],
    );
  }
}
