import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stress_pilot/core/navigation/app_router.dart';
import 'package:stress_pilot/features/projects/domain/flow.dart' as flow_domain;
import 'package:stress_pilot/features/projects/presentation/provider/flow_provider.dart';
import 'package:stress_pilot/core/di/locator.dart';
import 'package:stress_pilot/features/results/data/run_service.dart';
import 'package:stress_pilot/features/results/domain/models/run.dart';

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

  // List of variables as Key-Value pairs
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
      await context.read<FlowProvider>().runFlow(
        flowId: widget.flowId,
        runFlowRequest: request,
        file: multipartFile,
      );

      if (!mounted) return;

      final navigator = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);

      navigator.pop(); // Close dialog

      await Future.delayed(const Duration(milliseconds: 300));

      try {
        messenger.showSnackBar(
          const SnackBar(content: Text('Flow execution started')),
        );
      } catch (e) {
        // Ignored
      }

      await _pollForRun(messenger, navigator);
    } catch (e) {
      if (mounted) {
        try {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        } catch (_) {}
      }
    }
  }

  Future<void> _pollForRun(
    ScaffoldMessengerState messenger,
    NavigatorState navigator,
  ) async {
    final startTime = DateTime.now().toUtc();
    try {
      final runSvc = getIt<RunService>();
      Run? found;
      const int maxAttempts = 10;
      const Duration delay = Duration(milliseconds: 500);

      for (int attempt = 0; attempt < maxAttempts; attempt++) {
        try {
          final candidate = await runSvc.getLastRun(widget.flowId);
          final created = candidate.startedAt.toUtc();

          // Check if created after we started polling (with small buffer)
          if (created.isAfter(startTime.subtract(const Duration(seconds: 1)))) {
            found = candidate;
            break;
          }
        } catch (e) {
          // Flatten connection errors during polling
        }
        await Future.delayed(delay);
      }

      if (found != null) {
        navigator.pushNamed(
          AppRouter.resultsRoute,
          arguments: {'runId': found.id},
        );
      } else {
        // Fallback to runs list
        navigator.pushNamed(
          AppRouter.runsRoute,
          arguments: {'flowId': widget.flowId},
        );
      }
    } catch (e) {
      // General error fallback
      navigator.pushNamed(
        AppRouter.runsRoute,
        arguments: {'flowId': widget.flowId},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withValues(
                          alpha: 0.4,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.rocket_launch_rounded,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Run Flow',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      tooltip: 'Close',
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Configuration Form
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Section: Performance Settings
                        _buildSectionHeader('Performance Settings'),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildIntegerField(
                                _threadsCtrl,
                                'Threads',
                                Icons.groups_rounded,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildIntegerField(
                                _durationCtrl,
                                'Duration (s)',
                                Icons.timer_rounded,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildIntegerField(
                                _rampUpCtrl,
                                'Ramp Up (s)',
                                Icons.trending_up_rounded,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Section: Data & Environment
                        _buildSectionHeader('Data & Environment'),
                        const SizedBox(height: 12),

                        // File Upload
                        InkWell(
                          onTap: _pickFile,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _selectedFile != null
                                    ? colorScheme.primary
                                    : colorScheme.outlineVariant,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _selectedFile != null
                                      ? Icons.description
                                      : Icons.upload_file_rounded,
                                  color: _selectedFile != null
                                      ? colorScheme.primary
                                      : colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _selectedFile?.name ??
                                            'Select Data File (JSON)',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: _selectedFile != null
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                          color: _selectedFile != null
                                              ? colorScheme.onSurface
                                              : colorScheme.onSurfaceVariant,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (_selectedFile == null)
                                        Text(
                                          'Optional: Upload CSV or JSON data source',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: colorScheme.onSurfaceVariant
                                                .withValues(alpha: 0.7),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                if (_selectedFile != null)
                                  IconButton(
                                    onPressed: () =>
                                        setState(() => _selectedFile = null),
                                    icon: const Icon(Icons.close, size: 18),
                                    visualDensity: VisualDensity.compact,
                                  ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Section: Variables
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildSectionHeader('Variables'),
                            TextButton.icon(
                              onPressed: _addVariable,
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Add Variable'),
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ],
                        ),
                        if (_variables.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              'No custom variables defined.',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.5,
                                ),
                                fontStyle: FontStyle.italic,
                                fontSize: 13,
                              ),
                            ),
                          ),

                        ..._variables.asMap().entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: _buildTextField(
                                    entry.value.key,
                                    'Key',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 3,
                                  child: _buildTextField(
                                    entry.value.value,
                                    'Value',
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _removeVariable(entry.key),
                                  icon: Icon(
                                    Icons.remove_circle_outline,
                                    color: colorScheme.error.withValues(
                                      alpha: 0.8,
                                    ),
                                    size: 20,
                                  ),
                                  splashRadius: 20,
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: _run,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      icon: const Icon(Icons.play_arrow_rounded, size: 20),
                      label: const Text('Start Run'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
        color: Theme.of(context).colorScheme.outline,
      ),
    );
  }

  Widget _buildIntegerField(
    TextEditingController controller,
    String label,
    IconData icon,
  ) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        prefixIcon: Icon(icon, size: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.all(12),
        isDense: true,
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        isDense: true,
      ),
    );
  }
}
