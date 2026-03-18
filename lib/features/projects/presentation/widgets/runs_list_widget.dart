import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/core/themes/components/components.dart';
import 'package:stress_pilot/core/di/locator.dart';
import 'package:stress_pilot/core/navigation/app_router.dart';
import 'package:stress_pilot/features/common/data/run_service.dart';
import 'package:stress_pilot/features/common/presentation/provider/run_provider.dart';
import 'package:stress_pilot/core/domain/entities/run.dart';

class RunsListWidget extends StatefulWidget {
  final int? flowId;

  const RunsListWidget({super.key, this.flowId});

  @override
  State<RunsListWidget> createState() => _RunsListWidgetState();
}

class _RunsListWidgetState extends State<RunsListWidget> {
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
        PilotToast.show(context, 'Failed to load runs: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _exportRun(Run run) async {
    if (_exportingRunIds.contains(run.id)) return;
    setState(() => _exportingRunIds.add(run.id));
    try {
      final File? file = await _runService.exportRun(run);
      if (mounted) {
        if (file == null) {
          PilotToast.show(context, 'Export returned empty', isError: true);
        } else {
          PilotToast.show(context, 'Exported to ${file.path}');
        }
      }
    } catch (e) {
      if (mounted) PilotToast.show(context, 'Export failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _exportingRunIds.remove(run.id));
    }
  }

  void _handleRunTap(Run run) {
    final status = run.status.toUpperCase();
    if (status == 'RUNNING') {
      Navigator.pushNamed(
        context,
        AppRouter.resultsRoute,
        arguments: {'runId': run.id},
      ).then((_) => _loadRuns());
    } else if (status == 'COMPLETED') {
      _exportRun(run);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.textPrimary : AppColors.textLight;

    return Column(
      children: [
        Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: surface,
            border: Border(bottom: BorderSide(color: border.withValues(alpha: 0.3), width: 1)),
          ),
          child: Row(
            children: [
              Text(
                widget.flowId != null ? 'Flow Runs' : 'All Runs',
                style: AppTypography.heading.copyWith(color: textColor),
              ),
              const Spacer(),
              PilotButton.ghost(
                icon: Icons.refresh_rounded,
                onPressed: _loadRuns,
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: 5,
                  separatorBuilder: (context, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) => _RunSkeleton(isDark: isDark),
                )
              : _runs == null
                  ? Center(
                      child: Text(
                        'Failed to load runs',
                        style: AppTypography.body.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    )
                  : _runs!.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  borderRadius: AppRadius.br12,
                                  border: Border.all(color: border),
                                ),
                                child: const Icon(
                                  Icons.play_disabled_rounded,
                                  size: 32,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No runs found',
                                style: AppTypography.heading.copyWith(
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadRuns,
                          color: AppColors.accent,
                          backgroundColor: surface,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _runs!.length,
                            separatorBuilder: (context, _) => const SizedBox(height: 8),
                            itemBuilder: (context, index) => _RunTile(
                              run: _runs![index],
                              isExporting: _exportingRunIds.contains(_runs![index].id),
                              onTap: () => _handleRunTap(_runs![index]),
                              onRefresh: _loadRuns,
                            ),
                          ),
                        ),
        ),
      ],
    );
  }
}

class _RunSkeleton extends StatelessWidget {
  final bool isDark;

  const _RunSkeleton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final skeletonColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.05);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: AppRadius.br12,
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: skeletonColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 80,
                      height: 16,
                      decoration: BoxDecoration(
                        color: skeletonColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 60,
                      height: 16,
                      decoration: BoxDecoration(
                        color: skeletonColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  width: 100,
                  height: 12,
                  decoration: BoxDecoration(
                    color: skeletonColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 140,
                  height: 12,
                  decoration: BoxDecoration(
                    color: skeletonColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RunTile extends StatefulWidget {
  final Run run;
  final bool isExporting;
  final VoidCallback onTap;
  final VoidCallback onRefresh;

  const _RunTile({
    required this.run,
    required this.isExporting,
    required this.onTap,
    required this.onRefresh,
  });

  @override
  State<_RunTile> createState() => _RunTileState();
}

class _RunTileState extends State<_RunTile> {
  bool _hovered = false;
  bool _isInterrupting = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.textPrimary : AppColors.textLight;

    final status = widget.run.status.toUpperCase();
    final (statusColor, statusIcon) = _statusAppearance(status);
    final isRunning = status == 'RUNNING' || status == 'STARTING';

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppDurations.micro,
          decoration: BoxDecoration(
            color: _hovered ? AppColors.accent.withValues(alpha: 0.04) : surface,
            borderRadius: AppRadius.br12,
            border: Border.all(
              color: _hovered ? AppColors.accent.withValues(alpha: 0.25) : border,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                offset: const Offset(0, 2),
                blurRadius: 6,
              )
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Run #${widget.run.id}',
                          style: AppTypography.body.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        PilotBadge(label: status, color: statusColor, compact: true),
                      ],
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Flow ID: ${widget.run.flowId}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      DateFormat('yyyy-MM-dd HH:mm:ss').format(widget.run.startedAt.toLocal()),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              if (isRunning)
                _isInterrupting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        icon: const Icon(Icons.stop_circle_outlined, color: Colors.red),
                        tooltip: 'Abort Run',
                        onPressed: () async {
                          setState(() => _isInterrupting = true);
                          try {
                            await context.read<RunProvider>().interruptRun(widget.run.id);
                            widget.onRefresh();
                          } catch (e) {
                            if (mounted && context.mounted) {
                              PilotToast.show(context, 'Failed to abort: $e', isError: true);
                            }
                          } finally {
                            if (mounted) setState(() => _isInterrupting = false);
                          }
                        },
                      ),
              if (status == 'RUNNING')
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: AppColors.textMuted,
                ),
              if (status == 'COMPLETED')
                Tooltip(
                  message: 'Export',
                  child: widget.isExporting
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.accent,
                          ),
                        )
                      : Icon(
                          Icons.download_rounded,
                          color: AppColors.accent,
                          size: 18,
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  (Color, IconData) _statusAppearance(String status) {
    switch (status) {
      case 'RUNNING':
      case 'STARTING':
        return (const Color(0xFF3B82F6), Icons.play_circle_outline_rounded);
      case 'COMPLETED':
        return (AppColors.accent, Icons.check_circle_outline_rounded);
      case 'FAILED':
      case 'ABORTED':
        return (AppColors.error, Icons.error_outline_rounded);
      default:
        return (AppColors.textMuted, Icons.help_outline_rounded);
    }
  }
}
