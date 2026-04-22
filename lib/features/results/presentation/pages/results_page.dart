import 'dart:async';
import 'dart:io';

import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stress_pilot/features/shared/presentation/provider/run_provider.dart';
import 'package:stress_pilot/features/results/presentation/provider/results_provider.dart';
import 'package:stress_pilot/features/shared/domain/repositories/run_repository.dart';
import 'package:stress_pilot/features/shared/domain/models/run.dart';
import 'package:stress_pilot/features/results/presentation/widgets/metrics_card.dart';
import 'package:stress_pilot/features/results/presentation/widgets/realtime_chart.dart';
import 'package:stress_pilot/core/di/locator.dart';
import 'package:stress_pilot/core/navigation/app_router.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';

import 'package:stress_pilot/features/shared/presentation/widgets/fleet_page_bar.dart';

class ResultsPage extends StatefulWidget {
  final String runId;

  const ResultsPage({super.key, required this.runId});

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  Run? _currentRun;
  bool _loadingRun = false;

  Timer? _tickTimer;
  Duration _elapsed = Duration.zero;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadRun();
      if (_currentRun != null && mounted) {

        _startTimers();
      }
    });
  }

  Duration _currentPollInterval = const Duration(seconds: 15);
  bool _isPolling = false;

  void _startTimers() {
    _startPolling();

    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateElapsed(),
    );
  }

  void _startPolling() {
    if (_isPolling) return;
    _isPolling = true;
    _pollLoop();
  }

  Future<void> _pollLoop() async {
    while (_isPolling && mounted) {
      await _refreshRun();

      if (_currentRun == null || _isTerminalStatus(_currentRun!.status)) {
        _isPolling = false;
        break;
      }

      Duration nextDelay = _currentPollInterval;

      final created = _currentRun!.startedAt;
      final elapsed = DateTime.now().toUtc().difference(created.toUtc());
      final remaining = Duration(seconds: _currentRun!.duration) - elapsed;

      if (remaining.inSeconds <= 5 || elapsed.inSeconds <= 10) {

        nextDelay = const Duration(seconds: 2);
      } else if (remaining.inSeconds > 0) {

        nextDelay = const Duration(seconds: 5);
      } else {

        nextDelay = _currentPollInterval + const Duration(seconds: 2);
        if (nextDelay > const Duration(seconds: 10)) {
          nextDelay = const Duration(seconds: 10);
        }
      }

      _currentPollInterval = nextDelay;
      await Future.delayed(_currentPollInterval);
    }
  }

  void _stopTimers() {
    _isPolling = false;
    _tickTimer?.cancel();
  }

  Future<void> _updateElapsed() async {
    if (_currentRun == null) return;

    try {
      final created = _currentRun!.startedAt;
      final newElapsed = DateTime.now().toUtc().difference(created.toUtc());
      setState(() {
        _elapsed = newElapsed;
      });

      if (!_isPolling && !_isTerminalStatus(_currentRun!.status)) {
        _startPolling();
      }
    } catch (_) {
      setState(() {
        _elapsed = _elapsed + const Duration(seconds: 1);
      });
    }
  }

  Future<void> _loadRun() async {
    setState(() => _loadingRun = true);
    try {
      final svc = getIt<RunRepository>();
      final run = await svc.getRun(widget.runId);
      final isTerminal = _isTerminalStatus(run.status);

      if (mounted) {

        context.read<ResultsProvider>().setRun(
          run.id,
          run.flowId,
          isCompleted: isTerminal,
        );
      }

      setState(() {
        _currentRun = run;
        try {
          final created = _currentRun!.startedAt;
          _elapsed = DateTime.now().toUtc().difference(created.toUtc());
        } catch (_) {
          _elapsed = Duration.zero;
        }
      });

      if (isTerminal) {
        _stopTimers();
      }
    } catch (e) {
      debugPrint('Failed to load run: $e');
      if (mounted) {
        AppNavigator.scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text('Failed to load run: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingRun = false);
    }
  }

  Future<void> _refreshRun() async {
    try {
      final svc = getIt<RunRepository>();
      final run = await svc.getRun(widget.runId);
      setState(() {
        _currentRun = run;
      });

      if (_currentRun != null && _isTerminalStatus(_currentRun!.status)) {
        _stopTimers();
        if (mounted) {
          context.read<ResultsProvider>().stopChart();
        }
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
      final svc = getIt<RunRepository>();
      final File? file = await svc.exportRun(_currentRun!);
      if (file == null) {
        AppNavigator.scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(content: Text('Export returned empty')),
        );
      } else {
        AppNavigator.scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text('Export saved to ${file.path}')),
        );
      }
    } catch (e) {
      debugPrint('Export failed: $e');
      AppNavigator.scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
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
    final bg = AppColors.background;
    final surface = AppColors.surface;
    final border = AppColors.border;

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          FleetPageBar(
            title: 'Results',
            actions: [
              DropdownButton<int?>(
                value: provider.selectedEndpointId,
                hint: Text(
                  'All Endpoints',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                dropdownColor: AppColors.elevatedSurface,
                underline: const SizedBox(),
                icon: Icon(LucideIcons.chevronDown, size: 14, color: AppColors.textSecondary),
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text('All Endpoints', style: TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                  ),
                  ...provider.endpointNames.entries.map(
                    (e) => DropdownMenuItem(
                      value: e.key,
                      child: Text(e.value, style: TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                    ),
                  ),
                ],
                onChanged: (v) => provider.setEndpointFilter(v),
              ),
              Consumer<RunProvider>(
                builder: (context, runProvider, child) {
                  final isTerminal = _currentRun == null || _isTerminalStatus(_currentRun!.status);
                  if (isTerminal) return const SizedBox.shrink();
                  return Tooltip(
                    message: 'Abort Run',
                    child: IconButton(
                      icon: const Icon(Icons.stop_circle_outlined, color: Colors.red),
                      onPressed: () async {
                        try {
                          await runProvider.interruptRun(_currentRun!.id);
                          _refreshRun();
                        } catch (e) {
                          if (mounted && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to abort: $e')),
                            );
                          }
                        }
                      },
                    ),
                  );
                },
              ),
              Tooltip(
                message: 'Export',
                child: IconButton(
                  icon: _exporting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Icon(LucideIcons.fileDown, color: AppColors.accent),
                  onPressed: (_currentRun != null &&
                          _isTerminalStatus(_currentRun!.status) &&
                          !_exporting)
                      ? () => _exportRun()
                      : null,
                ),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [

                  const SizedBox(height: 12),

                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: AppRadius.br16,
                        border: Border.all(color: border.withValues(alpha: 0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            offset: const Offset(0, 4),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: AppRadius.br16,
                        child: Padding(
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
                                      icon: LucideIcons.hash,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    flex: 2,
                                    child: MetricsCard(
                                      title: 'Avg Response',
                                      value: '${provider.avgResponseTime.toStringAsFixed(0)} ms',
                                      icon: LucideIcons.timer,
                                      color: Colors.orange,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    flex: 2,
                                    child: MetricsCard(
                                      title: 'Req / Sec',
                                      value: provider.requestsPerSecond.toStringAsFixed(1),
                                      icon: LucideIcons.gauge,
                                      color: Colors.green,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    flex: 2,
                                    child: MetricsCard(
                                      title: 'Errors',
                                      value: provider.errorCount.toString(),
                                      icon: LucideIcons.triangleAlert,
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
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRunInfoCard() {
    if (_loadingRun) {
      final colors = Theme.of(context).colorScheme;
      return Container(
        height: 100,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.outlineVariant),
        ),
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colors.onSurface,
              ),
            ),
        ),
      );
    }

    if (_currentRun == null) {
      final colors = Theme.of(context).colorScheme;
      return Container(
        height: 100,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Center(
          child: Text(
            'No run metadata available',
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
        ),
      );
    }

    final status = _currentRun!.status.toUpperCase();
    final statusColor = status == 'COMPLETED'
        ? AppColors.success
        : (status == 'FAILED' || status == 'ABORTED' || status == 'CANCELED'
            ? AppColors.error
            : AppColors.info);

    final surface = AppColors.surface;
    final border = AppColors.border;
    final textCol = AppColors.textPrimary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 2),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Run #${_currentRun!.id}',
                  style: AppTypography.heading.copyWith(
                    color: textCol,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 11,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 13,
            fontFamily: 'JetBrains Mono',
          ),
        ),
      ],
    );
  }
}
