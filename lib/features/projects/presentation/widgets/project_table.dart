import 'package:flutter/material.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/core/themes/components/components.dart';
import 'package:stress_pilot/features/projects/domain/models/project.dart';

class ProjectTable extends StatelessWidget {
  final List<Project> projects;
  final Function(Project) onProjectTap;
  final Function(Project) onEdit;
  final Function(Project) onDelete;

  const ProjectTable({
    super.key,
    required this.projects,
    required this.onProjectTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ProjectTableHeader(),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: projects.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final project = projects[index];
            return _ProjectTableRow(
              project: project,
              onTap: () => onProjectTap(project),
              onEdit: () => onEdit(project),
              onDelete: () => onDelete(project),
            );
          },
        ),
      ],
    );
  }
}

class _ProjectTableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _HeaderCell('NAME', width: 220),
          _HeaderCell('DESCRIPTION', flex: 1),
          _HeaderCell('ID', width: 70),
          _HeaderCell('CREATED', width: 120),
          _HeaderCell('ACTIONS', width: 90, center: true),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String label;
  final double? width;
  final int? flex;
  final bool center;

  const _HeaderCell(this.label, {this.width, this.flex, this.center = false});

  @override
  Widget build(BuildContext context) {
    final widget = Text(
      label,
      textAlign: center ? TextAlign.center : TextAlign.start,
      style: AppTypography.label.copyWith(
        color: AppColors.textMuted,
        fontSize: 10,
        letterSpacing: 0.8,
      ),
    );

    if (width != null) return SizedBox(width: width, child: widget);
    return Expanded(child: widget);
  }
}

class _ProjectTableRow extends StatefulWidget {
  final Project project;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProjectTableRow({
    required this.project,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_ProjectTableRow> createState() => _ProjectTableRowState();
}

class _ProjectTableRowState extends State<_ProjectTableRow> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final border = AppColors.border;
    final surface = AppColors.elevatedSurface;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: TweenAnimationBuilder<double>(
          duration: AppDurations.short,
          tween: Tween(begin: 1.0, end: _isPressed ? 0.99 : 1.0),
          builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
          child: AnimatedContainer(
            duration: AppDurations.micro,
            decoration: BoxDecoration(
              color: _isHovered ? AppColors.activeItem.withValues(alpha: 0.5) : surface,
              borderRadius: AppRadius.br6,
              border: Border.all(
                color: _isHovered ? AppColors.accent.withValues(alpha: 0.3) : border,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 220,
                  child: Row(
                    children: [
                      _ProjectAvatar(name: widget.project.name),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.project.name,
                          style: AppTypography.bodyMd.copyWith(
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Text(
                    widget.project.description.isEmpty ? 'No description' : widget.project.description,
                    style: AppTypography.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _MonoCell('#${widget.project.id}', width: 70),
                _MonoCell(_formatDate(widget.project.createdAt), width: 120),
                SizedBox(
                  width: 90,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      PilotButton.ghost(
                        icon: Icons.edit_outlined,
                        compact: true,
                        tooltip: 'Edit',
                        onPressed: widget.onEdit,
                      ),
                      const SizedBox(width: 4),
                      PilotButton.danger(
                        icon: Icons.delete_outline_rounded,
                        compact: true,
                        tooltip: 'Delete',
                        onPressed: widget.onDelete,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _ProjectAvatar extends StatelessWidget {
  final String name;

  const _ProjectAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final color = _colorForString(name);

    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: AppRadius.br8,
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'P',
          style: AppTypography.body.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Color _colorForString(String text) {
    if (text.isEmpty) return AppColors.textSecondary;
    final colors = [
      AppColors.accent,
      Color(0xFFEF4444),
      Color(0xFF3B82F6),
      Color(0xFFF59E0B),
      Color(0xFF8B5CF6),
      Color(0xFF06B6D4),
      Color(0xFFEC4899),
      Color(0xFF6366F1),
    ];
    return colors[text.hashCode.abs() % colors.length];
  }
}

class _MonoCell extends StatelessWidget {
  final String text;
  final double width;

  const _MonoCell(this.text, {required this.width});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}
