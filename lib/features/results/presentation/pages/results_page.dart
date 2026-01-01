import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stress_pilot/features/results/presentation/provider/results_provider.dart';
import 'package:stress_pilot/features/results/data/run_service.dart';
import 'package:stress_pilot/features/results/domain/models/run.dart';
import 'package:stress_pilot/features/results/presentation/widgets/metrics_card.dart';
import 'package:stress_pilot/features/results/presentation/widgets/realtime_chart.dart';
import 'package:stress_pilot/core/di/locator.dart';

class ResultsPage extends StatefulWidget {
  final int runId;

  const ResultsPage({super.key, required this.runId});

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  Run? _currentRun;
  bool _loadingRun = false;

  Timer? _pollTimer; // 30s polling
  Timer? _tickTimer; // 1s UI tick for elapsed
  Duration _elapsed = Duration.zero;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Load run metadata first, then initialize results provider for the run's flow
      await _loadRun();
      if (_currentRun != null && mounted) {
        context.read<ResultsProvider>().initialize(_currentRun!.flowId);
        _startTimers();
      }
    });
  }

  void _startTimers() {
    // Start 30s polling
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _refreshRun(),
    );

    // Start 1s tick to update elapsed display
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateElapsed(),
    );
  }

  void _stopTimers() {
    _pollTimer?.cancel();
    _tickTimer?.cancel();
  }

  Future<void> _updateElapsed() async {
    if (_currentRun == null) return;
    // If run has a createdAt or startedAt, try to compute elapsed. Fall back to internal timer.
    if (_currentRun!.createdAt != null) {
      try {
        final created = DateTime.parse(_currentRun!.createdAt!);
        setState(() {
          _elapsed = DateTime.now().toUtc().difference(created.toUtc());
        });
      } catch (_) {
        setState(() {
          _elapsed = _elapsed + const Duration(seconds: 1);
        });
      }
    } else {
      setState(() {
        _elapsed = _elapsed + const Duration(seconds: 1);
      });
    }
  }

  Future<void> _loadRun() async {
    setState(() => _loadingRun = true);
    try {
      final svc = getIt<RunService>();
      final run = await svc.getRun(widget.runId);
      setState(() {
        _currentRun = run;
        // initialize elapsed based on createdAt if available
        if (_currentRun?.createdAt != null) {
          try {
            final created = DateTime.parse(_currentRun!.createdAt!);
            _elapsed = DateTime.now().toUtc().difference(created.toUtc());
          } catch (_) {
            _elapsed = Duration.zero;
          }
        } else {
          _elapsed = Duration.zero;
        }
      });
    } catch (e) {
      debugPrint('Failed to load run: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load run: $e')));
      }
    } finally {
      if (mounted) setState(() => _loadingRun = false);
    }
  }

  Future<void> _refreshRun() async {
    try {
      final svc = getIt<RunService>();
      final run = await svc.getRun(widget.runId);
      setState(() {
        _currentRun = run;
      });
      // If run completed, stop timers
      if (_currentRun != null && _isTerminalStatus(_currentRun!.status)) {
        _stopTimers();
      }
    } catch (e) {
      debugPrint('Run refresh failed: $e');
    }
  }

  bool _isTerminalStatus(String status) {
    final s = status.toUpperCase();
    return s == 'COMPLETED' ||
        s == 'FAILED' ||
        s == 'ABORTED' ||
        s == 'CANCELED';
  }

  Future<void> _exportRun() async {
    if (_currentRun == null) return;
    setState(() => _exporting = true);
    try {
      final svc = getIt<RunService>();
      final File? file = await svc.exportRun(_currentRun!);
      if (file == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Export returned empty')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Export saved to ${file.path}')),
          );
        }
      }
    } catch (e) {
      debugPrint('Export failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    } finally {
      setState(() => _exporting = false);
    }
  }

  @override
  void dispose() {
    _stopTimers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ResultsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Run Dashboard'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButton<int?>(
              value: provider.selectedEndpointId,
              hint: const Text('All Endpoints'),
              underline: const SizedBox(),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('All Endpoints'),
                ),
                ...provider.endpointNames.entries.map(
                  (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                ),
              ],
              onChanged: (v) => provider.setEndpointFilter(v),
            ),
          ),
          // Export Button: disabled until run is COMPLETED
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: IconButton(
              icon: _exporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download),
              tooltip: 'Export Run',
              onPressed:
                  (_currentRun != null &&
                      _currentRun!.status.toUpperCase() == 'COMPLETED' &&
                      !_exporting)
                  ? () => _exportRun()
                  : null,
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Run info & metrics
            Row(
              children: [
                Expanded(child: _buildRunInfoCard()),
                const SizedBox(width: 16),
                Expanded(
                  child: MetricsCard(
                    title: 'Total Requests',
                    value: provider.totalRequests.toString(),
                    icon: Icons.numbers,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: MetricsCard(
                    title: 'Avg Response Time',
                    value: '${provider.avgResponseTime.toStringAsFixed(2)} ms',
                    icon: Icons.timer,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: MetricsCard(
                    title: 'Requests / Sec',
                    value: provider.requestsPerSecond.toStringAsFixed(1),
                    icon: Icons.speed,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: MetricsCard(
                    title: 'Errors',
                    value: provider.errorCount.toString(),
                    icon: Icons.error_outline,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: RealtimeChart(
                      title: 'Response Time (ms)',
                      data: provider.responseTimePoints,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: RealtimeChart(
                      title: 'Requests Per Second',
                      data: provider.rpsPoints,
                      color: Colors.green,
                      isYAxisInteger: true,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRunInfoCard() {
    if (_loadingRun) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentRun == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: const Center(child: Text('No run metadata available')),
      );
    }

    final status = _currentRun!.status.toUpperCase();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Run #${_currentRun!.id}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(status, style: Theme.of(context).textTheme.labelLarge),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'CCU (threads): ',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    _currentRun!.threads.toString(),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Duration: ',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '${_currentRun!.duration}s',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Ramp Up: ',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '${_currentRun!.rampUpDuration}s',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Elapsed: ',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    _formatDuration(_elapsed),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '${h}h ${m}m ${s}s';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }
}
