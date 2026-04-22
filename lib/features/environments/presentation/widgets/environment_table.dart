import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stress_pilot/core/themes/components/components.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/features/environments/presentation/provider/environment_provider.dart';
import 'package:stress_pilot/features/environments/domain/environment_variable.dart';

class EnvironmentTable extends StatefulWidget {
  const EnvironmentTable({super.key});

  @override
  State<EnvironmentTable> createState() => _EnvironmentTableState();
}

class _EnvironmentTableState extends State<EnvironmentTable> {
  String _search = "";

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EnvironmentProvider>();
    final variables = provider.variables;
    final border = AppColors.border;

    final filtered = variables.where((v) {
      final q = _search.toLowerCase();
      return v.key.toLowerCase().contains(q) ||
          v.value.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              SizedBox(
                width: 320,
                child: PilotInput(
                  placeholder: 'Search variables...',
                  onChanged: (v) => setState(() => _search = v),
                  prefixIcon: Icons.search_rounded,
                ),
              ),
              const Spacer(),
              PilotButton.primary(
                onPressed: () => provider.addVariable(),
                icon: Icons.add_rounded,
                label: 'Add Variable',
              ),
            ],
          ),
        ),

        Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: AppColors.elevatedSurface,
            border: Border(
              top: BorderSide(color: border),
              bottom: BorderSide(color: border),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 60,
                child: Text(
                  'STATUS',
                  style: AppTypography.label.copyWith(color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: Text(
                  'VARIABLE KEY',
                  style: AppTypography.label.copyWith(color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: Text(
                  'VALUE',
                  style: AppTypography.label.copyWith(color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),

        Expanded(
          child: provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : filtered.isEmpty
                ? _EmptyState(isSearch: _search.isNotEmpty)
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final v = filtered[index];
                      final realIndex = variables.indexOf(v);

                      return _EnvironmentRow(
                        key: ValueKey(v.id),
                        variable: v,
                        isLast: index == filtered.length - 1,
                        onChanged: (key, value, isActive) {
                          provider.updateVariable(
                            realIndex,
                            key: key,
                            value: value,
                            isActive: isActive,
                          );
                        },
                        onDelete: () {
                          provider.removeVariable(realIndex);
                        },
                      );
                    },
                  ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isSearch;
  const _EmptyState({required this.isSearch});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSearch ? Icons.search_off_rounded : Icons.code_rounded,
            size: 48,
            color: AppColors.textSecondary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            isSearch ? 'No variables match your search' : 'No environment variables found',
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _EnvironmentRow extends StatefulWidget {
  final EnvironmentVariable variable;
  final bool isLast;
  final Function(String key, String value, bool isActive) onChanged;
  final VoidCallback onDelete;

  const _EnvironmentRow({
    super.key,
    required this.variable,
    required this.isLast,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  State<_EnvironmentRow> createState() => _EnvironmentRowState();
}

class _EnvironmentRowState extends State<_EnvironmentRow> {
  late TextEditingController _keyCtrl;
  late TextEditingController _valCtrl;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _keyCtrl = TextEditingController(text: widget.variable.key);
    _valCtrl = TextEditingController(text: widget.variable.value);
  }

  @override
  void didUpdateWidget(covariant _EnvironmentRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.variable.key != _keyCtrl.text && !_keyCtrl.selection.isValid) {
      _keyCtrl.text = widget.variable.key;
    }
    if (widget.variable.value != _valCtrl.text && !_valCtrl.selection.isValid) {
      _valCtrl.text = widget.variable.value;
    }
  }

  @override
  void dispose() {
    _keyCtrl.dispose();
    _valCtrl.dispose();
    super.dispose();
  }

  void _notify() {
    widget.onChanged(_keyCtrl.text, _valCtrl.text, widget.variable.isActive);
  }

  @override
  Widget build(BuildContext context) {
    final border = AppColors.border;
    final textColor = AppColors.textPrimary;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: AppDurations.micro,
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: _isHovered ? AppColors.hoverItem : Colors.transparent,
          border: widget.isLast
              ? null
              : Border(bottom: BorderSide(color: border)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 60,
              child: Switch(
                value: widget.variable.isActive,
                onChanged: (v) => widget.onChanged(
                  widget.variable.key,
                  widget.variable.value,
                  v,
                ),
                activeThumbColor: AppColors.accent,
                activeTrackColor: AppColors.accent.withValues(alpha: 0.2),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: TextField(
                controller: _keyCtrl,
                decoration: InputDecoration(
                  hintText: 'KEY_NAME',
                  hintStyle: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.4),
                    fontSize: 13,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                ),
                style: AppTypography.codeSm.copyWith(
                  fontWeight: FontWeight.bold,
                  color: widget.variable.isActive ? textColor : AppColors.textSecondary,
                ),
                onChanged: (_) => _notify(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: TextField(
                controller: _valCtrl,
                decoration: InputDecoration(
                  hintText: 'Variable value...',
                  hintStyle: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.4),
                    fontSize: 13,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                ),
                style: AppTypography.codeSm.copyWith(
                  color: widget.variable.isActive ? textColor : AppColors.textSecondary,
                ),
                onChanged: (_) => _notify(),
              ),
            ),
            AnimatedOpacity(
              duration: AppDurations.micro,
              opacity: _isHovered ? 1.0 : 0.0,
              child: PilotButton.ghost(
                icon: Icons.delete_outline_rounded,
                onPressed: widget.onDelete,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
