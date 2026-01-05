import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../common/domain/endpoint.dart';
import '../../common/presentation/provider/endpoint_provider.dart';
import 'package:stress_pilot/features/common/presentation/widgets/environment_dialog.dart';
import 'package:stress_pilot/features/common/presentation/widgets/endpoint_type_badge.dart';
import 'package:stress_pilot/features/common/presentation/widgets/json_viewer.dart';
import 'package:stress_pilot/features/projects/domain/project.dart';

import '../widgets/key_value_editor.dart';
import 'create_endpoint_dialog.dart';

class ProjectEndpointsPage extends StatefulWidget {
  final Project project;

  const ProjectEndpointsPage({super.key, required this.project});

  @override
  State<ProjectEndpointsPage> createState() => _ProjectEndpointsPageState();
}

class _ProjectEndpointsPageState extends State<ProjectEndpointsPage> {
  Endpoint? _selectedEndpoint;
  late ScrollController _scrollCtrl;

  @override
  void initState() {
    super.initState();
    _scrollCtrl = ScrollController();
    _scrollCtrl.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EndpointProvider>().loadEndpoints(
        projectId: widget.project.id,
      );
    });
  }

  void _onScroll() {
    final provider = context.read<EndpointProvider>();
    if (!provider.hasMore || provider.isLoadingMore) return;

    if (_scrollCtrl.position.maxScrollExtent - _scrollCtrl.position.pixels <
        200) {
      provider.loadMoreEndpoints(projectId: widget.project.id);
    }
  }

  void _createNewEndpoint() {
    setState(() {
      _selectedEndpoint = null;
    });
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EndpointProvider>();

    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 280,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: Theme.of(context).dividerTheme.color!),
              ),
              color: Theme.of(context).colorScheme.surface,
            ),
            child: Column(
              children: [
                Container(
                  height: 56, // Standard app bar height
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context).dividerTheme.color!,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(CupertinoIcons.arrow_left, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Back to Projects',
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.project.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          EnvironmentManagerDialog.show(
                            context,
                            widget.project.environmentId,
                            widget.project.name,
                          );
                        },
                        icon: const Icon(CupertinoIcons.layers_alt, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Environment',
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(12),
                  child: CupertinoSearchTextField(
                    placeholder: 'Search Endpoints',
                    onChanged: (value) {},
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      const Text(
                        'Endpoints',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF98989D), // Secondary Label
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _createNewEndpoint,
                        icon: const Icon(Icons.add, size: 18),
                        color: const Color(0xFF98989D),
                        tooltip: 'New Endpoint',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        style: const ButtonStyle(
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: provider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                          onRefresh: () => provider.refreshEndpoints(
                            projectId: widget.project.id,
                          ),
                          child: ListView.builder(
                            controller: _scrollCtrl,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount:
                                provider.endpoints.length +
                                (provider.hasMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index >= provider.endpoints.length) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  child: Center(
                                    child: provider.isLoadingMore
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                                );
                              }

                              final ep = provider.endpoints[index];
                              final isSelected = _selectedEndpoint?.id == ep.id;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: InkWell(
                                  onTap: () =>
                                      setState(() => _selectedEndpoint = ep),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(
                                              0xFF007AFF,
                                            ) // System Blue
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            EndpointTypeBadge(
                                              type: ep.type,
                                              compact: true,
                                              inverse: isSelected,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Tooltip(
                                                message: ep.url,
                                                child: Text(
                                                  ep.name,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: isSelected
                                                        ? FontWeight.w600
                                                        : FontWeight.normal,
                                                    color: isSelected
                                                        ? Colors.white
                                                        : Theme.of(context)
                                                              .colorScheme
                                                              .onSurface,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _selectedEndpoint == null
                ? _EmptyState(
                    projectId: widget.project.id,
                    onCreated: (ep) => setState(() => _selectedEndpoint = ep),
                  )
                : _EndpointWorkspace(
                    key: ValueKey(_selectedEndpoint!.id),
                    endpoint: _selectedEndpoint!,
                    projectId: widget.project.id,
                    onDeleted: () => setState(() => _selectedEndpoint = null),
                    onUpdated: (updated) =>
                        setState(() => _selectedEndpoint = updated),
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final int projectId;
  final Function(Endpoint) onCreated;

  const _EmptyState({required this.projectId, required this.onCreated});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              shape: BoxShape.circle,
              border: Border.all(color: Theme.of(context).colorScheme.outline),
            ),
            child: Icon(
              CupertinoIcons.cube_box,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Endpoint Selected',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select an endpoint from the sidebar\nor create a new one to get started.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => _showCreateDialog(context),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Create Endpoint'),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context) async {
    final endpointProvider = context.read<EndpointProvider>();
    final result = await showDialog(
      context: context,
      builder: (ctx) => ChangeNotifierProvider.value(
        value: endpointProvider,
        child: CreateEndpointDialog(projectId: projectId),
      ),
    );

    if (result != null && result is Endpoint) {
      onCreated(result);
    }
  }
}

class _EndpointWorkspace extends StatefulWidget {
  final Endpoint endpoint;
  final int projectId;
  final VoidCallback onDeleted;
  final Function(Endpoint) onUpdated;

  const _EndpointWorkspace({
    super.key,
    required this.endpoint,
    required this.projectId,
    required this.onDeleted,
    required this.onUpdated,
  });

  @override
  State<_EndpointWorkspace> createState() => _EndpointWorkspaceState();
}

class _EndpointWorkspaceState extends State<_EndpointWorkspace>
    with TickerProviderStateMixin {
  late TextEditingController _urlCtrl;
  late TextEditingController _nameCtrl;
  late String _method;

  late TextEditingController _bodyCtrl;
  late TextEditingController _successConditionCtrl;
  Map<String, String> _headers = {};
  Map<String, String> _params = {};
  Map<String, String> _variables = {};

  Map<String, dynamic>? _response;
  bool _isLoading = false;
  int? _statusCode;
  int? _responseTime;

  bool? _isSuccess;

  late TabController _reqTabCtrl;
  late TabController _resTabCtrl;

  @override
  void initState() {
    super.initState();
    _urlCtrl = TextEditingController(text: widget.endpoint.url);
    _nameCtrl = TextEditingController(text: widget.endpoint.name);
    _method = widget.endpoint.httpMethod ?? 'GET';

    String bodyText = '';
    if (widget.endpoint.body != null) {
      if (widget.endpoint.body is String) {
        bodyText = widget.endpoint.body;
      } else {
        bodyText = const JsonEncoder.withIndent(
          '  ',
        ).convert(widget.endpoint.body);
      }
    }
    _bodyCtrl = TextEditingController(text: bodyText);
    _successConditionCtrl = TextEditingController(
      text: widget.endpoint.successCondition ?? '',
    );

    if (widget.endpoint.httpHeaders != null) {
      widget.endpoint.httpHeaders!.forEach(
        (k, v) => _headers[k] = v.toString(),
      );
    }
    if (widget.endpoint.httpParameters != null) {
      widget.endpoint.httpParameters!.forEach(
        (k, v) => _params[k] = v.toString(),
      );
    }

    _reqTabCtrl = TabController(length: 4, vsync: this);
    _resTabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _nameCtrl.dispose();
    _bodyCtrl.dispose();
    _successConditionCtrl.dispose();
    _reqTabCtrl.dispose();
    _resTabCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    try {
      dynamic bodyPayload = _bodyCtrl.text;
      try {
        if (bodyPayload.trim().startsWith('{') ||
            bodyPayload.trim().startsWith('[')) {
          bodyPayload = jsonDecode(bodyPayload);
        }
      } catch (_) {}

      final data = {
        'name': _nameCtrl.text,
        'url': _urlCtrl.text,
        'httpMethod': _method,
        'body': bodyPayload,
        'httpHeaders': _headers,
        'httpParameters': _params,
        'successCondition': _successConditionCtrl.text,
        'projectId': widget.projectId,
      };

      final updated = await context.read<EndpointProvider>().updateEndpoint(
        widget.endpoint.id,
        data,
      );
      widget.onUpdated(updated);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Saved')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _send() async {
    setState(() {
      _isLoading = true;
      _response = null;
      _statusCode = null;
      _isSuccess = null;
    });

    try {
      dynamic bodyPayload = _bodyCtrl.text;
      try {
        if (bodyPayload.trim().isNotEmpty) {
          bodyPayload = jsonDecode(bodyPayload);
        }
      } catch (_) {}

      final result = await context
          .read<EndpointProvider>()
          .executeEndpoint(widget.endpoint.id, {
            'url': _urlCtrl.text,
            'httpMethod': _method,
            'body': bodyPayload,
            'httpHeaders': _headers,
            'httpParameters': _params,
            'variables': _variables,
            'successCondition': _successConditionCtrl.text,
          });

      setState(() {
        _response = result;
        _statusCode = result['statusCode'];
        _responseTime = result['responseTimeMs'];
        if (result.containsKey('success')) {
          _isSuccess = result['success'] as bool?;
        }
      });
    } catch (e) {
      setState(() {
        _response = {'error': e.toString()};
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameCtrl,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Endpoint Name',
                      hintStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                    style: TextStyle(
                      fontSize: 20, // Slightly smaller for dense feel
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _save,
                  icon: const Icon(CupertinoIcons.floppy_disk),
                  color: Theme.of(context).colorScheme.primary,
                  tooltip: 'Save',
                ),
                IconButton(
                  onPressed: widget.onDeleted,
                  icon: const Icon(CupertinoIcons.trash),
                  color: Theme.of(context).colorScheme.error,
                  iconSize: 20,
                  tooltip: 'Delete',
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Theme.of(context).dividerTheme.color),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              height: 36,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainer,
                                borderRadius: const BorderRadius.horizontal(
                                  left: Radius.circular(8),
                                ),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                              ),
                              child: Center(
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _method,
                                    dropdownColor: Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainer,
                                    icon: Icon(
                                      CupertinoIcons.chevron_down,
                                      size: 12,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                    items:
                                        [
                                          'GET',
                                          'POST',
                                          'PUT',
                                          'DELETE',
                                          'PATCH',
                                        ].map((m) {
                                          return DropdownMenuItem(
                                            value: m,
                                            child: Text(
                                              m,
                                              style: TextStyle(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurface,
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                    onChanged: (v) =>
                                        setState(() => _method = v!),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainer,
                                  border: Border(
                                    top: BorderSide(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.outline,
                                    ),
                                    bottom: BorderSide(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.outline,
                                    ),
                                    right: BorderSide(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.outline,
                                    ),
                                  ),
                                  borderRadius: const BorderRadius.horizontal(
                                    right: Radius.circular(8),
                                  ),
                                ),
                                alignment: Alignment.centerLeft,
                                child: TextField(
                                  controller: _urlCtrl,
                                  decoration: InputDecoration(
                                    hintText:
                                        'https://api.example.com/v1/resource',
                                    hintStyle: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                      fontSize: 13,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 0,
                                    ),
                                    isDense: true,
                                  ),
                                  style: TextStyle(
                                    fontFamily: 'JetBrains Mono',
                                    fontSize: 13,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                                  textAlignVertical: TextAlignVertical.center,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              height: 36,
                              child: FilledButton.icon(
                                onPressed: _isLoading ? null : _send,
                                icon: _isLoading
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(
                                        CupertinoIcons.play_fill,
                                        size: 14,
                                      ),
                                label: const Text('Send'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  textStyle: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SizedBox(
                          height: 32,
                          child: _SegmentedTabControl(
                            controller: _reqTabCtrl,
                            tabs: const [
                              'Params',
                              'Headers',
                              'Body',
                              'Configuration',
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: Theme.of(context).dividerTheme.color!,
                              ),
                            ),
                          ),
                          child: TabBarView(
                            controller: _reqTabCtrl,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: KeyValueEditor(
                                  data: _params,
                                  onChanged: (d) => _params = d,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: KeyValueEditor(
                                  data: _headers,
                                  onChanged: (d) => _headers = d,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(1),
                                child: TextField(
                                  controller: _bodyCtrl,
                                  maxLines: null,
                                  expands: true,
                                  style: TextStyle(
                                    fontFamily: 'JetBrains Mono',
                                    fontSize: 13,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Request Body (JSON)',
                                    hintStyle: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.all(16),
                                  ),
                                ),
                              ),
                              ListView(
                                padding: const EdgeInsets.all(16),
                                children: [
                                  Text(
                                    'Success Condition (SpEL)',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _successConditionCtrl,
                                    decoration: const InputDecoration(
                                      hintText:
                                          'e.g., #statusCode == 200 && #body.status == "OK"',
                                      border: OutlineInputBorder(),
                                      helperText:
                                          'Available variables: #statusCode, #body, #headers, #responseTime',
                                    ),
                                    minLines: 1,
                                    maxLines: 3,
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    'Variables',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    constraints: const BoxConstraints(
                                      minHeight: 100,
                                      maxHeight: 300,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Theme.of(
                                          context,
                                        ).dividerTheme.color!,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: KeyValueEditor(
                                      data: _variables,
                                      onChanged: (d) => _variables = d,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: Theme.of(context).dividerTheme.color),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainer,
                          border: Border(
                            bottom: BorderSide(
                              color: Theme.of(context).dividerTheme.color!,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Response',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                            const Spacer(),
                            if (_statusCode != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: (_isSuccess == true)
                                      ? const Color(
                                          0xFF30D158,
                                        ).withValues(alpha: 0.2)
                                      : const Color(
                                          0xFFFF453A,
                                        ).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _isSuccess == true
                                      ? 'SUCCESS (${_statusCode ?? '-'})'
                                      : 'FAILED (${_statusCode ?? '-'})',
                                  style: TextStyle(
                                    color: (_isSuccess == true)
                                        ? const Color(0xFF30D158)
                                        : const Color(0xFFFF453A),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '${_responseTime}ms',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                  fontSize: 12,
                                  fontFamily: 'JetBrains Mono',
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Expanded(
                        child: _response == null
                            ? Center(
                                child: Text(
                                  'Ready to send',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              )
                            : SingleChildScrollView(
                                padding: const EdgeInsets.all(16),
                                child: JsonViewer(
                                  json: () {
                                    final r = Map<String, dynamic>.from(
                                      _response!,
                                    );
                                    // Keep only message and data/body if they exist, or show filtered view
                                    final filtered = <String, dynamic>{};
                                    if (r.containsKey('message'))
                                      filtered['message'] = r['message'];
                                    if (r.containsKey('data')) {
                                      filtered['data'] = r['data'];
                                    } else if (r.containsKey('body')) {
                                      filtered['data'] = r['body'];
                                    } else {
                                      // If neither, maybe just show everything except technical fields?
                                      // For now, let's respect the user's request strictly but fallback safely
                                      // If strictly message and data are requested, what if they don't exist?
                                      // The user said "by then response only need message and data pls"
                                      // I'll try to find them. If map is empty after filter, maybe show original?
                                      // Or maybe the user implies the backend response structure has these.
                                      // Let's filter for them.
                                      if (r.containsKey('error'))
                                        filtered['error'] = r['error'];
                                    }

                                    // If we found nothing relevant, just show everything minus metadata
                                    if (filtered.isEmpty) {
                                      final metadataKeys = [
                                        'statusCode',
                                        'success',
                                        'responseTimeMs',
                                        'timestamp',
                                        'headers',
                                      ];
                                      r.removeWhere(
                                        (k, v) => metadataKeys.contains(k),
                                      );
                                      return r;
                                    }
                                    return filtered;
                                  }(),
                                ),
                              ),
                      ),
                    ],
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

class _SegmentedTabControl extends StatefulWidget {
  final TabController controller;
  final List<String> tabs;

  const _SegmentedTabControl({required this.controller, required this.tabs});

  @override
  State<_SegmentedTabControl> createState() => _SegmentedTabControlState();
}

class _SegmentedTabControlState extends State<_SegmentedTabControl> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: List.generate(widget.tabs.length, (index) {
          final isSelected = widget.controller.index == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => widget.controller.animateTo(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).cardTheme.color
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                alignment: Alignment.center,
                child: Text(
                  widget.tabs[index],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: isSelected
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
