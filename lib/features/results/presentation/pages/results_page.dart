import 'dart:async';
import 'dart:io';

import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stress_pilot/features/common/presentation/provider/run_provider.dart';
import 'package:stress_pilot/features/results/presentation/provider/results_provider.dart';
import 'package:stress_pilot/features/common/data/run_service.dart';
import 'package:stress_pilot/core/domain/entities/run.dart';
import 'package:stress_pilot/features/results/presentation/widgets/metrics_card.dart';
import 'package:stress_pilot/features/results/presentation/widgets/realtime_chart.dart';
import 'package:stress_pilot/core/di/locator.dart';
import 'package:stress_pilot/core/navigation/app_router.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';

import 'package:stress_pilot/features/common/presentation/app_topbar.dart';

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

        _startTimers();
      }
    });
  }

  bool _aggressivePolling = false;

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

  void _startAggressivePolling() {
    if (_aggressivePolling) return;
    _aggressivePolling = true;
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _refreshRun(),
    );
  }

  void _stopTimers() {
    _pollTimer?.cancel();
    _tickTimer?.cancel();
    _aggressivePolling = false;
  }

  Future<void> _updateElapsed() async {
    if (_currentRun == null) return;

    try {
      final created = _currentRun!.startedAt;
      final newElapsed = DateTime.now().toUtc().difference(created.toUtc());
      setState(() {
        _elapsed = newElapsed;
      });

      if (!_aggressivePolling &&
          !_isTerminalStatus(_currentRun!.status) &&
          newElapsed.inSeconds >= (_currentRun!.duration + 1)) {
        _startAggressivePolling();
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
      final svc = getIt<RunService>();
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
      final svc = getIt<RunService>();
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
      final svc = getIt<RunService>();
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textCol = isDark ? AppColors.textPrimary : AppColors.textLight;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          const AppTopBar(),
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [

                  Container(
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back, color: textCol, size: 20),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Live Run Dashboard',
                          style: AppTypography.heading.copyWith(color: textCol),
                        ),
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: DropdownButton<int?>(
                            value: provider.selectedEndpointId,
                            hint: Text(
                              'All Endpoints',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            dropdownColor: Theme.of(context).colorScheme.surfaceContainer,
                            underline: const SizedBox(),
                            icon: const Icon(
                              LucideIcons.chevronDown,
                              size: 14,
                              color: Color(0xFF98989D),
                            ),
                            items: [
                              DropdownMenuItem(
                                value: null,
                                child: Text(
                                  'All Endpoints',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              ...provider.endpointNames.entries.map(
                                (e) => DropdownMenuItem(
                                  value: e.key,
                                  child: Text(
                                    e.value,
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (v) => provider.setEndpointFilter(v),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Consumer<RunProvider>(
                            builder: (context, runProvider, child) {
                              final isTerminal = _currentRun == null ||
                                  _isTerminalStatus(_currentRun!.status);
                              if (isTerminal) return const SizedBox.shrink();

                              return Tooltip(
                                message: 'Abort Run',
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.stop_circle_outlined,
                                    color: Colors.red,
                                  ),
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
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Tooltip(
                            message: 'Export',
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
                                      LucideIcons.fileDown,
                                      color: Color(0xFF007AFF),
                                    ),
                              onPressed:
                                  (_currentRun != null &&
                                      _isTerminalStatus(_currentRun!.status) &&
                                      !_exporting)
                                  ? () => _exportRun()
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textCol = isDark ? AppColors.textPrimary : AppColors.textLight;

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
              Text(
                'Run #${_currentRun!.id}',
                style: AppTypography.heading.copyWith(
                  color: textCol,
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
