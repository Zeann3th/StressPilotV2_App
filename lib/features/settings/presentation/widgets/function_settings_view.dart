import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/core/themes/components/components.dart';
import 'package:stress_pilot/features/settings/presentation/provider/function_settings_provider.dart';
import 'package:stress_pilot/features/settings/domain/models/user_function.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:highlight/languages/javascript.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';

class FunctionSettingsView extends StatefulWidget {
  const FunctionSettingsView({super.key});

  @override
  State<FunctionSettingsView> createState() => _FunctionSettingsViewState();
}

class _FunctionSettingsViewState extends State<FunctionSettingsView> {
  final ScrollController _listScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      if (!mounted) return;
      await context.read<FunctionSettingsProvider>().loadFunctions();
    });
  }

  @override
  void dispose() {
    _listScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FunctionSettingsProvider>();
    final functions = provider.functions;
    final selected = provider.selectedFunction;
    final border = AppColors.border;

    if (provider.isLoading && functions.isEmpty) {
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
                    Text('Functions', style: AppTypography.label.copyWith(fontSize: 16)),
                    const Spacer(),
                    PilotButton.ghost(
                      icon: Icons.add_rounded,
                      onPressed: () => provider.createNew(),
                    ),
                    PilotButton.ghost(
                      icon: Icons.refresh_rounded,
                      onPressed: () => provider.loadFunctions(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: _listScrollController,
                  itemCount: functions.length,
                  itemBuilder: (context, index) {
                    final func = functions[index];
                    final isSelected = selected?.id == func.id;
                    return _FunctionListTile(
                      function: func,
                      isSelected: isSelected,
                      onTap: () => provider.selectFunction(func),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: selected == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.functions_rounded, size: 48, color: AppColors.textSecondary.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      Text('Select a function to edit', style: AppTypography.body.copyWith(color: AppColors.textSecondary)),
                      const SizedBox(height: 24),
                      PilotButton.primary(
                        label: 'Create New Function',
                        icon: Icons.add_rounded,
                        onPressed: () => provider.createNew(),
                      ),
                    ],
                  ),
                )
              : _FunctionDetailEditor(function: selected),
        ),
      ],
    );
  }
}

class _FunctionListTile extends StatelessWidget {
  final UserFunction function;
  final bool isSelected;
  final VoidCallback onTap;

  const _FunctionListTile({
    required this.function,
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
            Text(
              function.name,
              style: AppTypography.body.copyWith(
                color: textColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              function.description ?? 'No description',
              style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _FunctionDetailEditor extends StatefulWidget {
  final UserFunction function;

  const _FunctionDetailEditor({required this.function});

  @override
  State<_FunctionDetailEditor> createState() => _FunctionDetailEditorState();
}

class _FunctionDetailEditorState extends State<_FunctionDetailEditor> {
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late CodeController _codeController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.function.name);
    _descController = TextEditingController(text: widget.function.description);
    _codeController = CodeController(
      text: widget.function.body,
      language: javascript,
    );
  }

  @override
  void didUpdateWidget(_FunctionDetailEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.function.id != widget.function.id) {
      _nameController.text = widget.function.name;
      _descController.text = widget.function.description ?? '';
      _codeController.text = widget.function.body;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                    Text(widget.function.id == null ? 'New Function' : 'Edit Function',
                      style: AppTypography.heading.copyWith(fontSize: 24)),
                    if (widget.function.updatedAt != null)
                      Text('Last updated: ${widget.function.updatedAt}',
                        style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              if (widget.function.id != null)
                PilotButton.ghost(
                  label: 'Delete',
                  icon: Icons.delete_outline_rounded,
                  foregroundOverride: Colors.redAccent,
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Function'),
                        content: Text('Are you sure you want to delete "${widget.function.name}"?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.redAccent))),
                        ],
                      ),
                    );
                    if (confirmed == true && context.mounted) {
                      final provider = context.read<FunctionSettingsProvider>();
                      await provider.deleteFunction(widget.function.id!);
                      if (context.mounted) PilotToast.show(context, 'Function deleted');
                    }
                  },
                ),
              const SizedBox(width: 12),
              PilotButton.primary(
                label: 'Save Changes',
                icon: Icons.save_rounded,
                onPressed: () async {
                  final provider = context.read<FunctionSettingsProvider>();
                  final updated = widget.function.copyWith(
                    name: _nameController.text,
                    description: _descController.text,
                    body: _codeController.text,
                  );
                  await provider.saveFunction(updated);
                  if (context.mounted) PilotToast.show(context, 'Function saved successfully');
                },
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 24),

          Text('Function Name', style: AppTypography.label),
          const SizedBox(height: 8),
          PilotInput(
            controller: _nameController,
            placeholder: 'Enter function name (e.g. processResponse)',
          ),

          const SizedBox(height: 24),

          Text('Description', style: AppTypography.label),
          const SizedBox(height: 8),
          PilotInput(
            controller: _descController,
            placeholder: 'What does this function do?',
          ),

          const SizedBox(height: 24),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Function Definition (JavaScript)', style: AppTypography.label),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.br8,
                      border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: CodeTheme(
                      data: CodeThemeData(styles: monokaiSublimeTheme),
                      child: CodeField(
                        controller: _codeController,
                        textStyle: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 13),
                        expands: true,
                      ),
                    ),
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
