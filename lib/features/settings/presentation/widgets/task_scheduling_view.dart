import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/core/themes/components/components.dart';
import 'package:stress_pilot/features/settings/presentation/provider/scheduling_provider.dart';
import 'package:stress_pilot/features/settings/domain/models/schedule.dart';
import 'package:stress_pilot/features/projects/presentation/provider/flow_provider.dart';
import 'package:stress_pilot/features/projects/domain/models/flow.dart' as flow_domain;

class TaskSchedulingView extends StatefulWidget {
  const TaskSchedulingView({super.key});

  @override
  State<TaskSchedulingView> createState() => _TaskSchedulingViewState();
}

class _TaskSchedulingViewState extends State<TaskSchedulingView> {
  final ScrollController _listScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      if (!mounted) return;
      await context.read<SchedulingProvider>().loadSchedules();
      if (!mounted) return;
      await context.read<FlowProvider>().loadFlows();
    });
  }

  @override
  void dispose() {
    _listScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SchedulingProvider>();
    final schedules = provider.schedules;
    final selected = provider.selectedSchedule;
    final border = AppColors.border;

    if (provider.isLoading && schedules.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Row(
      children: [
        Container(
          width: 300,
          decoration: BoxDecoration(
            border: Border(right: BorderSide(color: border.withValues(alpha: 0.1))),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Text('Schedules', style: AppTypography.label.copyWith(fontSize: 16)),
                    const Spacer(),
                    PilotButton.ghost(
                      icon: Icons.add_rounded,
                      onPressed: () => provider.createNew(),
                    ),
                    PilotButton.ghost(
                      icon: Icons.refresh_rounded,
                      onPressed: () => provider.loadSchedules(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: _listScrollController,
                  itemCount: schedules.length,
                  itemBuilder: (context, index) {
                    final schedule = schedules[index];
                    final isSelected = selected?.id == schedule.id;
                    return _ScheduleListTile(
                      schedule: schedule,
                      isSelected: isSelected,
                      onTap: () => provider.selectSchedule(schedule),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: selected == null
              ? _NewScheduleEditor()
              : _ScheduleDetailEditor(schedule: selected),
        ),
      ],
    );
  }
}

class _ScheduleListTile extends StatelessWidget {
  final Schedule schedule;
  final bool isSelected;
  final VoidCallback onTap;

  const _ScheduleListTile({
    required this.schedule,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isSelected ? AppColors.accent.withValues(alpha: 0.1) : Colors.transparent;
    final textColor = AppColors.textPrimary;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.05))),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Flow #${schedule.flowId}',
                    style: AppTypography.body.copyWith(
                      color: textColor,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!schedule.enabled)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('Disabled', style: AppTypography.caption.copyWith(fontSize: 10)),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              schedule.quartzExpr,
              style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontFamily: 'JetBrains Mono'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleDetailEditor extends StatefulWidget {
  final Schedule schedule;

  const _ScheduleDetailEditor({required this.schedule});

  @override
  State<_ScheduleDetailEditor> createState() => _ScheduleDetailEditorState();
}

class _ScheduleDetailEditorState extends State<_ScheduleDetailEditor> {
  late TextEditingController _cronController;
  late TextEditingController _threadsController;
  late TextEditingController _durationController;
  late TextEditingController _rampUpController;
  final ScrollController _formScrollController = ScrollController();
  late bool _enabled;
  int? _flowId;

  @override
  void initState() {
    super.initState();
    _initFields();
  }

  void _initFields() {
    _cronController = TextEditingController(text: widget.schedule.quartzExpr);
    _threadsController = TextEditingController(text: widget.schedule.threads.toString());
    _durationController = TextEditingController(text: widget.schedule.duration.toString());
    _rampUpController = TextEditingController(text: widget.schedule.rampUp.toString());
    _enabled = widget.schedule.enabled;
    _flowId = widget.schedule.flowId;
  }

  @override
  void didUpdateWidget(_ScheduleDetailEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.schedule.id != widget.schedule.id) {
      _initFields();
    }
  }

  @override
  void dispose() {
    _cronController.dispose();
    _threadsController.dispose();
    _durationController.dispose();
    _rampUpController.dispose();
    _formScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flows = context.watch<FlowProvider>().flows;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Edit Schedule', style: AppTypography.heading.copyWith(fontSize: 24)),
                    Text('ID: ${widget.schedule.id}', style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              PilotButton.ghost(
                label: 'Delete',
                icon: Icons.delete_outline_rounded,
                foregroundOverride: Colors.redAccent,
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Schedule'),
                      content: const Text('Are you sure you want to delete this schedule?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.redAccent))),
                      ],
                    ),
                  );
                  if (confirmed == true && context.mounted) {
                    final provider = context.read<SchedulingProvider>();
                    await provider.deleteSchedule(widget.schedule.id);
                    if (context.mounted) PilotToast.show(context, 'Schedule deleted');
                  }
                },
              ),
              const SizedBox(width: 12),
              PilotButton.primary(
                label: 'Save Changes',
                icon: Icons.save_rounded,
                onPressed: () async {
                  final provider = context.read<SchedulingProvider>();
                  final updated = widget.schedule.copyWith(
                    flowId: _flowId,
                    quartzExpr: _cronController.text,
                    threads: int.tryParse(_threadsController.text) ?? 1,
                    duration: int.tryParse(_durationController.text) ?? 60,
                    rampUp: int.tryParse(_rampUpController.text) ?? 0,
                    enabled: _enabled,
                  );
                  await provider.saveSchedule(updated);
                  if (context.mounted) PilotToast.show(context, 'Schedule saved successfully');
                },
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 24),
          _buildForm(flows),
        ],
      ),
    );
  }

  Widget _buildForm(List<flow_domain.Flow> flows) {
    return Expanded(
      child: SingleChildScrollView(
        controller: _formScrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Flow', style: AppTypography.label),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              initialValue: _flowId,
              items: flows.map((f) => DropdownMenuItem<int>(value: f.id, child: Text(f.name))).toList(),
              onChanged: (val) => setState(() => _flowId = val),
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: AppRadius.br8),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            const SizedBox(height: 24),
            Text('Cron Expression (Quartz)', style: AppTypography.label),
            const SizedBox(height: 8),
            PilotInput(
              controller: _cronController,
              placeholder: 'e.g. 0 0/5 * * * ?',
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Threads', style: AppTypography.label),
                      const SizedBox(height: 8),
                      PilotInput(
                        controller: _threadsController,
                        placeholder: '1',
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Duration (sec)', style: AppTypography.label),
                      const SizedBox(height: 8),
                      PilotInput(
                        controller: _durationController,
                        placeholder: '60',
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ramp Up (sec)', style: AppTypography.label),
                      const SizedBox(height: 8),
                      PilotInput(
                        controller: _rampUpController,
                        placeholder: '0',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Checkbox(
                  value: _enabled,
                  onChanged: (val) => setState(() => _enabled = val ?? true),
                ),
                const Text('Enabled'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NewScheduleEditor extends StatefulWidget {
  @override
  State<_NewScheduleEditor> createState() => _NewScheduleEditorState();
}

class _NewScheduleEditorState extends State<_NewScheduleEditor> {
  final _cronController = TextEditingController(text: '0 0/5 * * * ?');
  final _threadsController = TextEditingController(text: '1');
  final _durationController = TextEditingController(text: '60');
  final _rampUpController = TextEditingController(text: '0');
  final ScrollController _scrollController = ScrollController();
  bool _enabled = true;
  int? _flowId;

  @override
  void dispose() {
    _cronController.dispose();
    _threadsController.dispose();
    _durationController.dispose();
    _rampUpController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flows = context.watch<FlowProvider>().flows;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('New Schedule', style: AppTypography.heading.copyWith(fontSize: 24)),
              ),
              PilotButton.primary(
                label: 'Create Schedule',
                icon: Icons.add_rounded,
                onPressed: () async {
                  if (_flowId == null) {
                    PilotToast.show(context, 'Please select a flow');
                    return;
                  }
                  final provider = context.read<SchedulingProvider>();
                  final request = CreateScheduleRequest(
                    flowId: _flowId!,
                    quartzExpr: _cronController.text,
                    threads: int.tryParse(_threadsController.text) ?? 1,
                    duration: int.tryParse(_durationController.text) ?? 60,
                    rampUp: int.tryParse(_rampUpController.text) ?? 0,
                    enabled: _enabled,
                  );

                  await provider.saveSchedule(
                    Schedule(
                      id: 0,
                      flowId: _flowId!,
                      quartzExpr: _cronController.text,
                      enabled: _enabled,
                      threads: 0,
                      duration: 0,
                      rampUp: 0,
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    ),
                    createRequest: request,
                  );
                  if (context.mounted) PilotToast.show(context, 'Schedule created successfully');
                },
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Flow', style: AppTypography.label),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    initialValue: _flowId,
                    items: flows.map((f) => DropdownMenuItem<int>(value: f.id, child: Text(f.name))).toList(),
                    onChanged: (val) => setState(() => _flowId = val),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: AppRadius.br8),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Cron Expression (Quartz)', style: AppTypography.label),
                  const SizedBox(height: 8),
                  PilotInput(
                    controller: _cronController,
                    placeholder: 'e.g. 0 0/5 * * * ?',
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Threads', style: AppTypography.label),
                            const SizedBox(height: 8),
                            PilotInput(
                              controller: _threadsController,
                              placeholder: '1',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Duration (sec)', style: AppTypography.label),
                            const SizedBox(height: 8),
                            PilotInput(
                              controller: _durationController,
                              placeholder: '60',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Ramp Up (sec)', style: AppTypography.label),
                            const SizedBox(height: 8),
                            PilotInput(
                              controller: _rampUpController,
                              placeholder: '0',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Checkbox(
                        value: _enabled,
                        onChanged: (val) => setState(() => _enabled = val ?? true),
                      ),
                      const Text('Enabled'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
