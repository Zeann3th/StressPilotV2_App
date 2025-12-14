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

  // Variables
  final List<MapEntry<TextEditingController, TextEditingController>>
  _variables = [];

  // File
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

    if (mounted) {
      try {
        await context.read<FlowProvider>().runFlow(
          flowId: widget.flowId,
          runFlowRequest: request,
          file: multipartFile,
        );

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Flow execution started')),
          );
          // Resolve the last run for this flow and navigate directly to RunsPage.
          // The backend may create the run asynchronously, so retry briefly until we find a run
          // that appears to have been created after we started this execution.
          final startTime = DateTime.now().toUtc();
          try {
            final runSvc = getIt<RunService>();
            Run? found;
            const int maxAttempts = 10;
            const Duration delay = Duration(milliseconds: 500);
            for (int attempt = 0; attempt < maxAttempts; attempt++) {
              try {
                final candidate = await runSvc.getLastRun(widget.flowId);
                // getLastRun returns a non-null Run. Verify createdAt if available.
                if (candidate.createdAt != null) {
                  try {
                    final created = DateTime.parse(candidate.createdAt!).toUtc();
                    if (created.isAfter(startTime.subtract(const Duration(seconds: 1)))) {
                      found = candidate;
                      break;
                    }
                  } catch (_) {
                    // Parsing issue - accept candidate as a best-effort
                    found = candidate;
                    break;
                  }
                } else {
                  // No createdAt - accept the candidate as best-effort
                  found = candidate;
                  break;
                }
              } catch (_) {
                // ignore and retry
              }
              await Future.delayed(delay);
            }

            if (found != null && mounted) {
              Navigator.pushNamed(
                context,
                AppRouter.runsRoute,
                arguments: {'runId': found.id},
              );
            } else {
              // Fallback to previous routing if resolution fails
              Navigator.pushNamed(
                context,
                AppRouter.resultsRoute,
                arguments: {'flowId': widget.flowId},
              );
            }
          } catch (e) {
            // Unexpected error - fallback
            Navigator.pushNamed(
              context,
              AppRouter.resultsRoute,
              arguments: {'flowId': widget.flowId},
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Run Flow Configuration'),
      content: SizedBox(
        width: 600, // Make the form bigger
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Configuration Section
              const Text(
                'General Settings',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _threadsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Threads',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _durationCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Duration (s)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _rampUpCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Ramp Up (s)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Credentials File Section
              const Text(
                'Credentials',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickFile,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Select JSON File'),
                  ),
                  const SizedBox(width: 16),
                  if (_selectedFile != null)
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.description),
                          const SizedBox(width: 8),
                          Text(_selectedFile!.name),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () =>
                                setState(() => _selectedFile = null),
                          ),
                        ],
                      ),
                    )
                  else
                    const Text(
                      'No file selected (Optional)',
                      style: TextStyle(color: Colors.grey),
                    ),
                ],
              ),

              const SizedBox(height: 24),

              // Variables Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Runtime Variables',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: _addVariable,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Variable'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_variables.isEmpty)
                const Text(
                  'No variables added',
                  style: TextStyle(color: Colors.grey),
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
                          child: TextField(
                            controller: _variables[index].key,
                            decoration: const InputDecoration(
                              hintText: 'Key',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _variables[index].value,
                            decoration: const InputDecoration(
                              hintText: 'Value',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeVariable(index),
                        ),
                      ],
                    );
                  },
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _run, child: const Text('Run Flow')),
      ],
    );
  }
}
