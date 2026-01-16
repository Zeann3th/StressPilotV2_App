import 'package:flutter/cupertino.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:stress_pilot/features/browser_spy/presentation/manager/browser_spy_provider.dart';
import 'package:stress_pilot/features/browser_spy/domain/request_entry.dart';
import 'package:stress_pilot/features/browser_spy/presentation/widgets/project_selection_dialog.dart';
import 'package:stress_pilot/features/common/data/endpoint_service.dart';
import 'package:stress_pilot/features/projects/domain/project.dart';

class BrowserSpyPage extends StatelessWidget {
  const BrowserSpyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BrowserSpyProvider>();
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                _buildHeader(context, provider),
                if (provider.isBrowserOpen) ...[
                  Divider(
                    height: 1,
                    color: Theme.of(context).dividerTheme.color,
                  ),
                  _buildFilterBar(context, provider),
                  Divider(
                    height: 1,
                    color: Theme.of(context).dividerTheme.color,
                  ),
                  Expanded(
                    child: provider.filteredRequests.isEmpty
                        ? Center(
                            child: Text(
                              'No requests captured yet',
                              style: TextStyle(color: colors.onSurfaceVariant),
                            ),
                          )
                        : ListView.builder(
                            itemCount: provider.filteredRequests.length,
                            itemBuilder: (context, index) {
                              final req = provider.filteredRequests[index];
                              return _RequestListItem(
                                key: ValueKey(
                                  req,
                                ), // Assuming RequestEntry might need ID or stable identifier? Use ref for now.
                                request: req,
                                isEven: index.isEven,
                              );
                            },
                          ),
                  ),
                ] else
                  Expanded(child: _buildEmptyState(context, provider)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, BrowserSpyProvider provider) {
    return Container(
      height: 60, // Slightly taller for better breathing room
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(CupertinoIcons.arrow_left),
            tooltip: 'Back',
            color: Theme.of(context).colorScheme.onSurface,
          ),
          const SizedBox(width: 8),
          const Icon(CupertinoIcons.globe, size: 20),
          const SizedBox(width: 12),
          Text(
            'Browser Spy',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          if (provider.isBrowserOpen) ...[
            IconButton(
              onPressed: provider.clearHistory,
              icon: const Icon(CupertinoIcons.delete),
              tooltip: 'Clear History',
              style: IconButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: () => provider.stopBrowser(),
              icon: const Icon(CupertinoIcons.stop_fill, size: 16),
              label: const Text('Stop'),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context, BrowserSpyProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: CupertinoSearchTextField(
              placeholder: 'Filter URL...',
              onChanged: provider.setSearchText,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    selected: provider.activeFilters.contains('all'),
                    onSelected: (_) => provider.toggleFilter('all'),
                  ),
                  _FilterChip(
                    label: 'XHR/Fetch',
                    selected:
                        provider.activeFilters.contains('xhr') ||
                        provider.activeFilters.contains('fetch'),
                    onSelected: (_) => provider.toggleFilter('xhr'),
                  ),
                  _FilterChip(
                    label: 'Doc',
                    selected: provider.activeFilters.contains('document'),
                    onSelected: (_) => provider.toggleFilter('document'),
                  ),
                  _FilterChip(
                    label: 'JS',
                    selected: provider.activeFilters.contains('script'),
                    onSelected: (_) => provider.toggleFilter('script'),
                  ),
                  _FilterChip(
                    label: 'CSS',
                    selected: provider.activeFilters.contains('stylesheet'),
                    onSelected: (_) => provider.toggleFilter('stylesheet'),
                  ),
                  _FilterChip(
                    label: 'Img',
                    selected: provider.activeFilters.contains('image'),
                    onSelected: (_) => provider.toggleFilter('image'),
                  ),
                  _FilterChip(
                    label: 'Other',
                    selected: provider.activeFilters.contains('other'),
                    onSelected: (_) => provider.toggleFilter('other'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, BrowserSpyProvider provider) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: colors.surfaceContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(CupertinoIcons.globe, size: 64, color: colors.primary),
          ),
          const SizedBox(height: 24),
          Text(
            'Start a Browser Spy Session',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Launch a controlled browser instance to inspect\nnetwork traffic and create tests from real requests.',
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () => provider.launchBrowser(),
            icon: const Icon(CupertinoIcons.play_arrow_solid, size: 16),
            label: const Text('Launch Browser'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => onSelected(!selected),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? colors.primaryContainer : colors.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? colors.primary : colors.outlineVariant,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              color: selected ? colors.onPrimaryContainer : colors.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _RequestListItem extends StatelessWidget {
  final RequestEntry request;
  final bool isEven;

  const _RequestListItem({
    super.key,
    required this.request,
    required this.isEven,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    Color methodColor;
    switch (request.method.toUpperCase()) {
      case 'GET':
        methodColor = Colors.blue;
        break;
      case 'POST':
        methodColor = Colors.green;
        break;
      case 'PUT':
        methodColor = Colors.orange;
        break;
      case 'DELETE':
        methodColor = Colors.red;
        break;
      default:
        methodColor = Colors.grey;
    }

    return GestureDetector(
      onSecondaryTapUp: (details) {
        _showContextMenu(context, details.globalPosition);
      },
      child: Container(
        decoration: BoxDecoration(
          color: isEven
              ? colors.surface.withValues(alpha: 0.5)
              : colors.surface,
          border: Border(
            bottom: BorderSide(
              color: colors.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
        ),
        child: InkWell(
          onTap: () {
            // Future: Show details pane
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: methodColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: methodColor.withValues(alpha: 0.3),
                    ),
                  ),
                  width: 60,
                  alignment: Alignment.center,
                  child: Text(
                    request.method,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: methodColor,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.url,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontFamily: 'JetBrains Mono',
                        ),
                      ),
                      if (request.resourceType != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            request.resourceType!,
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                if (request.statusCode != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(
                        request.statusCode!,
                      ).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      request.statusCode.toString(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(request.statusCode!),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(int code) {
    if (code >= 200 && code < 300) return Colors.green;
    if (code >= 300 && code < 400) return Colors.blue;
    if (code >= 400 && code < 500) return Colors.orange;
    if (code >= 500) return Colors.red;
    return Colors.grey;
  }

  void _showContextMenu(BuildContext context, Offset position) async {
    final value = await showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      items: [
        const PopupMenuItem(
          value: 'send_to_test',
          child: Row(
            children: [
              Icon(Icons.add_task, size: 18),
              SizedBox(width: 8),
              Text('Send to Test'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'copy_url',
          child: Row(
            children: [
              Icon(Icons.copy, size: 18),
              SizedBox(width: 8),
              Text('Copy URL'),
            ],
          ),
        ),
      ],
    );

    if (!context.mounted) return;

    if (value == 'send_to_test') {
      _handleSendToTest(context, request);
    } else if (value == 'copy_url') {
      Clipboard.setData(ClipboardData(text: request.url));
    }
  }

  Future<void> _handleSendToTest(
    BuildContext context,
    RequestEntry request,
  ) async {
    // 1. Select Project
    final Project? project = await showDialog<Project>(
      context: context,
      builder: (context) => const ProjectSelectionDialog(),
    );

    if (project == null || !context.mounted) return;

    // 2. Create Endpoint
    try {
      dynamic body = request.requestBody;
      try {
        if (body is String &&
            (body.trim().startsWith('{') || body.trim().startsWith('['))) {
          body = jsonDecode(body);
        }
      } catch (_) {}

      final endpointData = {
        'projectId': project.id,
        'name': '${request.method} ${Uri.parse(request.url).path}',
        'url': request.url,
        'type': 'HTTP',
        'description': 'Imported from Browser Spy',
        'httpMethod': request.method,
        'body': body,
        'httpHeaders': request.requestHeaders,
        'httpParameters': <String, String>{},
      };

      final endpointService = EndpointService();
      await endpointService.createEndpoint(endpointData);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Endpoint created in ${project.name}'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Open',
              onPressed: () {
                // Future: Navigate to project
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create endpoint: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
