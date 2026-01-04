import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
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

      navigator.pop();

      await Future.delayed(const Duration(milliseconds: 300));

      try {
        messenger.showSnackBar(
          const SnackBar(content: Text('Flow execution started')),
        );
      } catch (e) {
        debugPrint("⚠️ SnackBar error (harmless): $e");
      }

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

            if (created.isAfter(
              startTime.subtract(const Duration(seconds: 1)),
            )) {
              found = candidate;
              break;
            }
          } catch (e) {
            debugPrint("   Polling fetch error: $e");
          }
          await Future.delayed(delay);
        }

        if (found != null) {
          navigator.pushNamed(
            AppRouter.resultsRoute,
            arguments: {'runId': found.id},
          );
        } else {
          navigator.pushNamed(
            AppRouter.runsRoute,
            arguments: {'flowId': widget.flowId},
          );
        }
      } catch (e) {
        navigator.pushNamed(
          AppRouter.runsRoute,
          arguments: {'flowId': widget.flowId},
        );
      }
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Run Flow Configuration',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'General Settings',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF98989D),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildInput(_threadsCtrl, 'Threads', isNumber: true),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildInput(
                      _durationCtrl,
                      'Duration (s)',
                      isNumber: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildInput(
                      _rampUpCtrl,
                      'Ramp Up (s)',
                      isNumber: true,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              const Text(
                'Credentials',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF98989D),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                child: Row(
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _pickFile,
                      child: Row(
                        children: const [
                          Icon(
                            CupertinoIcons.doc_fill,
                            color: Color(0xFF007AFF),
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Select JSON File',
                            style: TextStyle(
                              color: Color(0xFF007AFF),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _selectedFile != null
                          ? Row(
                              children: [
                                Icon(
                                  CupertinoIcons.doc_text,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _selectedFile!.name,
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  minSize: 0,
                                  onPressed: () =>
                                      setState(() => _selectedFile = null),
                                  child: const Icon(
                                    CupertinoIcons.clear_circled_solid,
                                    color: Color(0xFF636366),
                                    size: 18,
                                  ),
                                ),
                              ],
                            )
                          : const Text(
                              'No file selected (Optional)',
                              style: TextStyle(
                                color: Color(0xFF636366),
                                fontSize: 13,
                              ),
                            ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Runtime Variables',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF98989D),
                      fontSize: 13,
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minSize: 0,
                    onPressed: _addVariable,
                    child: Row(
                      children: const [
                        Icon(
                          CupertinoIcons.add,
                          size: 14,
                          color: Color(0xFF007AFF),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Add Variable',
                          style: TextStyle(
                            color: Color(0xFF007AFF),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_variables.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No variables added',
                    style: TextStyle(color: Color(0xFF636366), fontSize: 13),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _variables.length,
                  separatorBuilder: (c, i) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    return Row(
                      children: [
                        Expanded(
                          child: _buildInput(_variables[index].key, 'Key'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: _buildInput(_variables[index].value, 'Value'),
                        ),
                        const SizedBox(width: 8),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          minSize: 0,
                          onPressed: () => _removeVariable(index),
                          child: const Icon(
                            CupertinoIcons.trash,
                            color: Color(0xFFFF453A),
                            size: 20,
                          ),
                        ),
                      ],
                    );
                  },
                ),

              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CupertinoButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Color(0xFF98989D)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  CupertinoButton.filled(
                    onPressed: _run,
                    child: const Text(
                      'Run Flow',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(
    TextEditingController controller,
    String placeholder, {
    bool isNumber = false,
  }) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: CupertinoTextField(
        controller: controller,
        placeholder: placeholder,
        placeholderStyle: const TextStyle(
          color: Color(0xFF636366),
          fontSize: 13,
        ),
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 13,
        ),
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: null,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      ),
    );
  }
}
