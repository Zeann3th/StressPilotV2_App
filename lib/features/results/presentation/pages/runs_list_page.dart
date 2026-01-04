import 'dart:io';

import 'package:flutter/cupertino.dart';
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
      ).then((_) => _loadRuns());
    } else if (run.status.toUpperCase() == 'COMPLETED') {
      _exportRun(run);
    } else {
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          widget.flowId != null ? 'Flow Runs' : 'All Runs',
          style: TextStyle(
            color: Theme.of(context).appBarTheme.foregroundColor,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF007AFF)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Theme.of(context).dividerTheme.color,
            height: 1,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.refresh),
            onPressed: _loadRuns,
            color: const Color(0xFF007AFF),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : _runs == null
          ? const Center(
              child: Text(
                'Failed to load runs',
                style: TextStyle(color: Color(0xFF98989D)),
              ),
            )
          : _runs!.isEmpty
          ? const Center(
              child: Text(
                'No runs found',
                style: TextStyle(color: Color(0xFF98989D)),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadRuns,
              color: const Color(0xFF007AFF),
              backgroundColor: Theme.of(context).colorScheme.surface,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _runs!.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
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
        statusColor = const Color(0xFF007AFF); // Blue
        statusIcon = CupertinoIcons.play_circle;
        break;
      case 'COMPLETED':
        statusColor = const Color(0xFF30D158); // Green
        statusIcon = CupertinoIcons.check_mark_circled;
        break;
      case 'FAILED':
        statusColor = const Color(0xFFFF453A); // Red
        statusIcon = CupertinoIcons.exclamationmark_circle;
        break;
      default:
        statusColor = const Color(0xFF8E8E93); // Gray
        statusIcon = CupertinoIcons.question_circle;
    }

    final isExporting = _exportingRunIds.contains(run.id);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleRunTap(run),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Run #${run.id}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Flow ID: ${run.flowId}',
                        style: const TextStyle(
                          color: Color(0xFF98989D),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat(
                          'yyyy-MM-dd HH:mm:ss',
                        ).format(run.startedAt.toLocal()),
                        style: const TextStyle(
                          color: Color(0xFF98989D),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (status == 'RUNNING')
                  const Icon(
                    CupertinoIcons.chevron_right,
                    size: 16,
                    color: Color(0xFF636366),
                  ),
                if (status == 'COMPLETED')
                  isExporting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CupertinoActivityIndicator(radius: 10),
                        )
                      : const Icon(
                          CupertinoIcons.arrow_down_doc,
                          color: Color(0xFF007AFF),
                        ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
