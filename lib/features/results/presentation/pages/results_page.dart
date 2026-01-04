import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
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

  Timer? _pollTimer;
  Timer? _tickTimer;
  Duration _elapsed = Duration.zero;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadRun();
      if (_currentRun != null && mounted) {
        context.read<ResultsProvider>().initialize(_currentRun!.flowId);
        _startTimers();
      }
    });
  }

  void _startTimers() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _refreshRun(),
    );

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

    try {
      final created = _currentRun!.startedAt;
      setState(() {
        _elapsed = DateTime.now().toUtc().difference(created.toUtc());
      });
    } catch (_) {
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
        try {
          final created = _currentRun!.startedAt;
          _elapsed = DateTime.now().toUtc().difference(created.toUtc());
        } catch (_) {
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Live Run Dashboard',
          style: TextStyle(
            color: Theme.of(context).appBarTheme.foregroundColor,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Color(0xFF007AFF),
        ), // Back button blue
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFF38383A), height: 1),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButton<int?>(
              value: provider.selectedEndpointId,
              hint: const Text(
                'All Endpoints',
                style: TextStyle(color: Colors.white),
              ),
              dropdownColor: const Color(0xFF1C1C1E),
              underline: const SizedBox(),
              icon: const Icon(
                CupertinoIcons.chevron_down,
                size: 14,
                color: Color(0xFF98989D),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text(
                    'All Endpoints',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                ...provider.endpointNames.entries.map(
                  (e) => DropdownMenuItem(
                    value: e.key,
                    child: Text(
                      e.value,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
              onChanged: (v) => provider.setEndpointFilter(v),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: IconButton(
              icon: _exporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      CupertinoIcons.arrow_down_doc,
                      color: Color(0xFF007AFF),
                    ),
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
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(flex: 3, child: _buildRunInfoCard()),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: MetricsCard(
                    title: 'Total Requests',
                    value: provider.totalRequests.toString(),
                    icon: CupertinoIcons.number,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: MetricsCard(
                    title: 'Avg Response',
                    value: '${provider.avgResponseTime.toStringAsFixed(0)} ms',
                    icon: CupertinoIcons.timer,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: MetricsCard(
                    title: 'Req / Sec',
                    value: provider.requestsPerSecond.toStringAsFixed(1),
                    icon: CupertinoIcons.speedometer,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: MetricsCard(
                    title: 'Errors',
                    value: provider.errorCount.toString(),
                    icon: CupertinoIcons.exclamationmark_triangle,
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
        height: 100, // Fixed height to match metrics
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF38383A)),
        ),
        child: const Center(
          child: CupertinoActivityIndicator(color: Colors.white),
        ),
      );
    }

    if (_currentRun == null) {
      return Container(
        height: 100,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF38383A)),
        ),
        child: const Center(
          child: Text(
            'No run metadata available',
            style: TextStyle(color: Color(0xFF98989D)),
          ),
        ),
      );
    }

    final status = _currentRun!.status.toUpperCase();
    final statusColor = status == 'COMPLETED'
        ? Colors.green
        : (status == 'FAILED' ? Colors.red : Colors.blue);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Run #${_currentRun!.id}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
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
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            children: [
              _InfoBadge(
                label: 'Threads',
                value: _currentRun!.threads.toString(),
              ),
              _InfoBadge(label: 'Duration', value: '${_currentRun!.duration}s'),
              _InfoBadge(label: 'Elapsed', value: _formatDuration(_elapsed)),
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

class _InfoBadge extends StatelessWidget {
  final String label;
  final String value;
  const _InfoBadge({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF98989D), fontSize: 11),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontFamily: 'JetBrains Mono',
          ),
        ),
      ],
    );
  }
}
