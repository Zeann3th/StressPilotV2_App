import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stress_pilot/core/design/tokens.dart';
import 'package:stress_pilot/core/design/components.dart';
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
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.textPrimary : AppColors.textLight;

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          // Topbar
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: surface,
              border: Border(bottom: BorderSide(color: border, width: 1)),
            ),
            child: Row(
              children: [
                PilotButton.ghost(
                  icon: Icons.arrow_back_rounded,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 12),
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
                ? Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.accent,
                      ),
                    ),
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
                      itemBuilder: (context, index) =>
                          _RunTile(
                            run: _runs![index],
                            isExporting: _exportingRunIds.contains(_runs![index].id),
                            onTap: () => _handleRunTap(_runs![index]),
                          ),
                    ),
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

  const _RunTile({
    required this.run,
    required this.isExporting,
    required this.onTap,
  });

  @override
  State<_RunTile> createState() => _RunTileState();
}

class _RunTileState extends State<_RunTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.textPrimary : AppColors.textLight;

    final status = widget.run.status.toUpperCase();
    final (statusColor, statusIcon) = _statusAppearance(status);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppDurations.micro,
          decoration: BoxDecoration(
            color: _hovered
                ? AppColors.accent.withValues(alpha: 0.04)
                : surface,
            borderRadius: AppRadius.br12,
            border: Border.all(
              color: _hovered
                  ? AppColors.accent.withValues(alpha: 0.25)
                  : border,
            ),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 24),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Run #${widget.run.id}',
                          style: AppTypography.bodyLg.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        PilotBadge(label: status, color: statusColor),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Flow ID: ${widget.run.flowId}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('yyyy-MM-dd HH:mm:ss')
                          .format(widget.run.startedAt.toLocal()),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (status == 'RUNNING')
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: AppColors.textMuted,
                ),
              if (status == 'COMPLETED')
                widget.isExporting
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
            ],
          ),
        ),
      ),
    );
  }

  (Color, IconData) _statusAppearance(String status) {
    switch (status) {
      case 'RUNNING':
        return (const Color(0xFF3B82F6), Icons.play_circle_outline_rounded);
      case 'COMPLETED':
        return (AppColors.accent, Icons.check_circle_outline_rounded);
      case 'FAILED':
        return (AppColors.error, Icons.error_outline_rounded);
      default:
        return (AppColors.textMuted, Icons.help_outline_rounded);
    }
  }
}
