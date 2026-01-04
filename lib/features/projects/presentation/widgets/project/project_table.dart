import 'package:flutter/cupertino.dart';
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
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _ProjectTableHeader(),
          Divider(height: 1, color: Theme.of(context).dividerTheme.color),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: projects.length,
            separatorBuilder: (_, _) =>
                Divider(height: 1, color: Theme.of(context).dividerTheme.color),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Row(
        children: [
          _HeaderCell('NAME', width: 250),
          _HeaderCell('DESCRIPTION', flex: 1),
          _HeaderCell('ID', width: 80),
          _HeaderCell('CREATED', width: 140),
          _HeaderCell('ACTIONS', width: 100, center: true),
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
      style: const TextStyle(
        color: Color(0xFF98989D),
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
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

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          color: _isHovered
              ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05)
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: Row(
            children: [
              SizedBox(
                width: 250,
                child: Row(
                  children: [
                    _ProjectAvatar(name: widget.project.name),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.project.name,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
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
                  widget.project.description,
                  style: const TextStyle(
                    color: Color(0xFF98989D),
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _TableCell('#${widget.project.id}', width: 80),
              _TableCell(_formatDate(widget.project.createdAt), width: 140),
              SizedBox(
                width: 100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ActionButton(
                      icon: CupertinoIcons.pencil,
                      tooltip: 'Edit',
                      onPressed: widget.onEdit,
                      color: const Color(0xFF007AFF),
                    ),
                    const SizedBox(width: 8),
                    _ActionButton(
                      icon: CupertinoIcons.trash,
                      tooltip: 'Delete',
                      onPressed: widget.onDelete,
                      color: const Color(0xFFFF453A),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 18, color: color),
      onPressed: onPressed,
      tooltip: tooltip,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      style: IconButton.styleFrom(hoverColor: color.withAlpha(30)),
    );
  }
}

class _ProjectAvatar extends StatelessWidget {
  final String name;

  const _ProjectAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final color = _getColorForString(name);

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'P',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Color _getColorForString(String text) {
    if (text.isEmpty) return Colors.grey;

    const colors = [
      Color(0xFF0A84FF), // Blue
      Color(0xFFFF453A), // Red
      Color(0xFF30D158), // Green
      Color(0xFFFF9F0A), // Orange
      Color(0xFFBF5AF2), // Purple
      Color(0xFF64D2FF), // Cyan/Teal
      Color(0xFFFF375F), // Pink
      Color(0xFF5E5CE6), // Indigo
    ];

    return colors[text.hashCode.abs() % colors.length];
  }
}

class _TableCell extends StatelessWidget {
  final String text;
  final double width;

  const _TableCell(this.text, {required this.width});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF98989D),
          fontSize: 13,
          fontFamily: 'JetBrains Mono',
        ),
      ),
    );
  }
}
