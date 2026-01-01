import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stress_pilot/core/di/locator.dart';
import 'package:stress_pilot/core/navigation/app_router.dart';
import 'package:stress_pilot/features/results/data/run_service.dart';
import 'package:stress_pilot/features/results/domain/models/run.dart';

class RunsListPage extends StatefulWidget {
  final int? flowId;

  const RunsListPage({super.key, this.flowId});

  @override
  State<RunsListPage> createState() => _RunsListPageState();
}

class _RunsListPageState extends State<RunsListPage> {
  final _runService = getIt<RunService>();
  List<Run>? _runs;
  bool _isLoading = false;

  // Set to store IDs of runs currently being exported to show progress
  final Set<int> _exportingRunIds = {};

  @override
  void initState() {
    super.initState();
    _loadRuns();
  }

  Future<void> _loadRuns() async {
    setState(() => _isLoading = true);
    try {
      final runs = await _runService.getRuns(flowId: widget.flowId);
      // Sort by descending ID (newest first) since createdAt varies
      runs.sort((a, b) => b.id.compareTo(a.id));
      setState(() => _runs = runs);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load runs: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _exportRun(Run run) async {
    if (_exportingRunIds.contains(run.id)) return;

    setState(() {
      _exportingRunIds.add(run.id);
    });

    try {
      final File? file = await _runService.exportRun(run);
      if (mounted) {
        if (file == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Export returned empty')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Export saved to ${file.path}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _exportingRunIds.remove(run.id);
        });
      }
    }
  }

  void _handleRunTap(Run run) {
    if (run.status.toUpperCase() == 'RUNNING') {
      Navigator.pushNamed(
        context,
        AppRouter.resultsRoute,
        arguments: {'runId': run.id},
      ).then((_) => _loadRuns()); // Refresh on return
    } else if (run.status.toUpperCase() == 'COMPLETED') {
      _exportRun(run);
    } else {
      // For other statuses (FAILED, ABORTED, etc.), maybe just show details or allow export?
      // User said "only let them enter results page if run is in status RUNNING, else COMPLETED then they can export"
      // Let's assume for others we do nothing or maybe just show a snackbar explaining?
      // Or maybe allow export for FAILED too?
      // For now, adhere strictly to user request for RUNNING/COMPLETED logic.
      if ([
        'FAILED',
        'ABORTED',
        'CANCELED',
      ].contains(run.status.toUpperCase())) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Run is ${run.status}. Cannot view live dashboard.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.flowId != null ? 'Flow Runs' : 'All Runs'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadRuns),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _runs == null
          ? const Center(child: Text('Failed to load runs'))
          : _runs!.isEmpty
          ? const Center(child: Text('No runs found'))
          : RefreshIndicator(
              onRefresh: _loadRuns,
              child: ListView.builder(
                itemCount: _runs!.length,
                itemBuilder: (context, index) {
                  final run = _runs![index];
                  return _buildRunTile(run);
                },
              ),
            ),
    );
  }

  Widget _buildRunTile(Run run) {
    final status = run.status.toUpperCase();
    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'RUNNING':
        statusColor = Colors.blue;
        statusIcon = Icons.play_circle_outline;
        break;
      case 'COMPLETED':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_outline;
        break;
      case 'FAILED':
        statusColor = Colors.red;
        statusIcon = Icons.error_outline;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
    }

    final isExporting = _exportingRunIds.contains(run.id);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(statusIcon, color: statusColor),
        title: Text('Run #${run.id}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Flow ID: ${run.flowId} | Status: $status'),
            if (run.createdAt != null)
              Text(
                DateFormat(
                  'yyyy-MM-dd HH:mm:ss',
                ).format(DateTime.parse(run.createdAt!).toLocal()),
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (status == 'RUNNING')
              const Icon(Icons.arrow_forward_ios, size: 16),
            if (status == 'COMPLETED')
              isExporting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download, color: Colors.blue),
          ],
        ),
        onTap: () => _handleRunTap(run),
      ),
    );
  }
}
