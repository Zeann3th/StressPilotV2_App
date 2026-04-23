import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stress_pilot/features/projects/domain/models/flow.dart' as flow_domain;
import 'package:stress_pilot/core/themes/components/components.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/core/navigation/app_router.dart';
import 'package:stress_pilot/features/shared/presentation/provider/flow_provider.dart';
import 'package:stress_pilot/features/shared/presentation/provider/run_provider.dart';
import 'package:stress_pilot/features/shared/presentation/widgets/field_label.dart';

class RunFlowDialog extends StatefulWidget {
  final int flowId;

  const RunFlowDialog({super.key, required this.flowId});

  @override
  State<RunFlowDialog> createState() => _RunFlowDialogState();
}

class _RunFlowDialogState extends State<RunFlowDialog> {
  final _threadsCtrl = TextEditingController(text: '1');
  final _durationCtrl = TextEditingController(text: '60');
  final _rampUpCtrl = TextEditingController(text: '0');

  final List<MapEntry<TextEditingController, TextEditingController>>
  _variables = [];

  PlatformFile? _selectedFile;

  @override
  void dispose() {
    _threadsCtrl.dispose();
    _durationCtrl.dispose();
    _rampUpCtrl.dispose();
    for (var entry in _variables) {
      entry.key.dispose();
      entry.value.dispose();
    }
    super.dispose();
  }

  void _addVariable() {
    setState(() {
      _variables.add(
        MapEntry(TextEditingController(), TextEditingController()),
      );
    });
  }

  void _removeVariable(int index) {
    setState(() {
      final entry = _variables.removeAt(index);
      entry.key.dispose();
      entry.value.dispose();
    });
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null) {
      setState(() {
        _selectedFile = result.files.single;
      });
    }
  }

  void _run() async {
    final threads = int.tryParse(_threadsCtrl.text) ?? 1;
    final duration = int.tryParse(_durationCtrl.text) ?? 60;
    final rampUp = int.tryParse(_rampUpCtrl.text) ?? 0;

    final variablesMap = <String, dynamic>{};
    for (var entry in _variables) {
      if (entry.key.text.isNotEmpty) {
        variablesMap[entry.key.text] = entry.value.text;
      }
    }

    MultipartFile? multipartFile;
    if (_selectedFile != null && _selectedFile!.path != null) {
      multipartFile = await MultipartFile.fromFile(
        _selectedFile!.path!,
        filename: _selectedFile!.name,
      );
    }

    final request = flow_domain.RunFlowRequest(
      threads: threads,
      totalDuration: duration,
      rampUpDuration: rampUp,
      variables: variablesMap,
    );

    if (!mounted) return;

    try {
      final runId = await context.read<FlowProvider>().runFlow(
        flowId: widget.flowId,
        runFlowRequest: request,
        file: multipartFile,
      );

      if (!mounted) return;
      await context.read<RunProvider>().trackRun(runId);

      if (!mounted) return;
      Navigator.of(context).pop();
      AppNavigator.pushNamed(AppRouter.resultsRoute, arguments: {'runId': runId});
    } catch (e) {
      if (mounted) {
        PilotToast.show(context, 'Error: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PilotDialog(
      title: 'Run Flow',
      maxWidth: 600,
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FieldLabel('PERFORMANCE SETTINGS'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _FieldSubLabel('Threads'),
                      const SizedBox(height: 6),
                      PilotInput(
                        controller: _threadsCtrl,
                        placeholder: '1',
                        prefixIcon: LucideIcons.users,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _FieldSubLabel('Duration (s)'),
                      const SizedBox(height: 6),
                      PilotInput(
                        controller: _durationCtrl,
                        placeholder: '60',
                        prefixIcon: LucideIcons.timer,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _FieldSubLabel('Ramp Up (s)'),
                      const SizedBox(height: 6),
                      PilotInput(
                        controller: _rampUpCtrl,
                        placeholder: '0',
                        prefixIcon: LucideIcons.trendingUp,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            FieldLabel('DATA & ENVIRONMENT'),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickFile,
              borderRadius: AppRadius.br12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.elevated,
                  borderRadius: AppRadius.br12,
                  border: Border.all(
                    color: _selectedFile != null ? AppColors.accent : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _selectedFile != null ? LucideIcons.fileText : LucideIcons.upload,
                      color: _selectedFile != null ? AppColors.accent : AppColors.textMuted,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedFile?.name ?? 'Select Data File (JSON)',
                            style: AppTypography.body.copyWith(
                              fontWeight: _selectedFile != null ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                          if (_selectedFile == null)
                            Text(
                              'Optional: Upload CSV or JSON data source',
                              style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                            ),
                        ],
                      ),
                    ),
                    if (_selectedFile != null)
                      IconButton(
                        onPressed: () => setState(() => _selectedFile = null),
                        icon: const Icon(LucideIcons.x, size: 18),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FieldLabel('VARIABLES'),
                PilotButton.ghost(
                  label: 'Add Variable',
                  icon: LucideIcons.plus,
                  onPressed: _addVariable,
                  compact: true,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_variables.isEmpty)
              Text(
                'No custom variables defined.',
                style: AppTypography.caption.copyWith(fontStyle: FontStyle.italic),
              ),
            ..._variables.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: PilotInput(
                        controller: entry.value.key,
                        placeholder: 'Key',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: PilotInput(
                        controller: entry.value.value,
                        placeholder: 'Value',
                      ),
                    ),
                    IconButton(
                      onPressed: () => _removeVariable(entry.key),
                      icon: Icon(LucideIcons.circleMinus, color: AppColors.error, size: 20),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
      actions: [
        PilotButton.ghost(
          label: 'Cancel',
          onPressed: () => Navigator.of(context).pop(),
        ),
        PilotButton.primary(
          label: 'Start Run',
          icon: LucideIcons.play,
          onPressed: _run,
        ),
      ],
    );
  }
}

class _FieldSubLabel extends StatelessWidget {
  final String text;
  const _FieldSubLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.caption.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
