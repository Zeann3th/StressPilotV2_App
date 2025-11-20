import 'package:flutter/material.dart';
import 'package:stress_pilot/features/projects/domain/project.dart';

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
    final colors = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _ProjectTableHeader(),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: projects.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
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
      ),
    );
  }
}

class _ProjectTableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Row(
        children: [
          _HeaderCell('NAME', width: 200, text: text, colors: colors),
          _HeaderCell('DESCRIPTION', flex: 1, text: text, colors: colors),
          _HeaderCell('ID', width: 80, text: text, colors: colors),
          _HeaderCell('CREATED AT', width: 140, text: text, colors: colors),
          _HeaderCell('UPDATED AT', width: 140, text: text, colors: colors),
          _HeaderCell(
            'ACTIONS',
            width: 120,
            text: text,
            colors: colors,
            center: true,
          ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String label;
  final double? width;
  final int? flex;
  final TextTheme text;
  final ColorScheme colors;
  final bool center;

  const _HeaderCell(
    this.label, {
    this.width,
    this.flex,
    required this.text,
    required this.colors,
    this.center = false,
  });

  @override
  Widget build(BuildContext context) {
    final widget = Text(
      label,
      textAlign: center ? TextAlign.center : TextAlign.start,
      style: text.labelSmall?.copyWith(
        color: colors.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
    );

    if (width != null) return SizedBox(width: width, child: widget);
    return Expanded(child: widget);
  }
}

class _ProjectTableRow extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            SizedBox(
              width: 200,
              child: Row(
                children: [
                  _ProjectAvatar(name: project.name),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      project.name,
                      style: text.bodyMedium?.copyWith(color: colors.onSurface),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Text(
                project.description,
                style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _TableCell('#${project.id}', width: 80),
            _TableCell(_formatDate(project.createdAt), width: 140),
            _TableCell(_formatDate(project.updatedAt), width: 140),
            SizedBox(
              width: 120,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: colors.onSurface,
                    ),
                    onPressed: onEdit,
                    tooltip: 'Edit',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: colors.error,
                    ),
                    onPressed: onDelete,
                    tooltip: 'Delete',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month]} ${date.day}, ${date.year}';
  }
}

class _ProjectAvatar extends StatelessWidget {
  final String name;

  const _ProjectAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: _getColorFromString(name),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'P',
          style: text.labelMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Color _getColorFromString(String str) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.cyan,
    ];
    return colors[str.length % colors.length];
  }
}

class _TableCell extends StatelessWidget {
  final String text;
  final double width;

  const _TableCell(this.text, {required this.width});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      width: width,
      child: Text(
        text,
        style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
      ),
    );
  }
}
