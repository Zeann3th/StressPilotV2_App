import 'dart:async';
import 'package:flutter/material.dart' hide Flow;
import 'package:provider/provider.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/core/domain/entities/flow.dart';
import 'package:stress_pilot/features/projects/presentation/provider/flow_provider.dart';

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
    final colors = Theme.of(context).colorScheme;

    return Dialog(
      backgroundColor: colors.surface,
      surfaceTintColor: colors.surfaceTint,
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configure Subflow',
              style: AppTypography.title.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 16),
            Text(
              'Select a flow to execute as a subflow.',
              style: AppTypography.caption.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                labelText: 'Search Flow Name',
                hintText: 'Type flow name...',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _selectedFlow = null;
                            _filteredFlows = [];
                          });
                        },
                      )
                    : null,
              ),
            ),
            if (_filteredFlows.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  border: Border.all(color: colors.outlineVariant),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _filteredFlows.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final flow = _filteredFlows[index];
                    return ListTile(
                      title: Text(flow.name),
                      onTap: () {
                        setState(() {
                          _selectedFlow = flow;
                          _searchController.text = flow.name;
                          _filteredFlows = [];
                        });
                      },
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                if (_selectedFlow != null)
                  OutlinedButton.icon(
                    onPressed: () {
                      context.read<FlowProvider>().selectFlow(_selectedFlow!);
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('Navigate to Flow'),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _selectedFlow == null
                      ? null
                      : () {
                          Navigator.of(context).pop(_selectedFlow!);
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
