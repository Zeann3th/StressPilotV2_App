import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../common/domain/endpoint.dart';
import '../../common/presentation/provider/endpoint_provider.dart';

class ProjectEndpointsPage extends StatefulWidget {
  final int projectId;

  const ProjectEndpointsPage({super.key, required this.projectId});

  @override
  State<ProjectEndpointsPage> createState() => _ProjectEndpointsPageState();
}

class _ProjectEndpointsPageState extends State<ProjectEndpointsPage> {
  Endpoint? _selectedEndpoint;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EndpointProvider>().loadEndpoints(
        projectId: widget.projectId,
      );
    });
  }

  void _createNewEndpoint() {
    setState(() {
      _selectedEndpoint = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final provider = context.watch<EndpointProvider>();

    return Scaffold(
      body: Row(
        children: [
          // --- LEFT PANE: LIST ---
          Container(
            width: 280,
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: colors.outlineVariant)),
              color: colors.surface,
            ),
            child: Column(
              children: [
                // Header / Search
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: colors.outlineVariant),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.arrow_back, color: colors.onSurface),
                        tooltip: 'Back',
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Endpoints',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colors.onSurface,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _createNewEndpoint,
                        icon: const Icon(Icons.add),
                        tooltip: 'New Endpoint',
                        style: IconButton.styleFrom(
                          foregroundColor: colors.primary,
                          backgroundColor: colors.primaryContainer.withValues(
                            alpha: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // List
                Expanded(
                  child: provider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          itemCount: provider.endpoints.length,
                          itemBuilder: (context, index) {
                            final ep = provider.endpoints[index];
                            final isSelected = _selectedEndpoint?.id == ep.id;

                            return InkWell(
                              onTap: () =>
                                  setState(() => _selectedEndpoint = ep),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? colors.primaryContainer.withValues(
                                          alpha: 0.1,
                                        )
                                      : null,
                                  border: isSelected
                                      ? Border(
                                          left: BorderSide(
                                            color: colors.primary,
                                            width: 3,
                                          ),
                                        )
                                      : const Border(
                                          left: BorderSide(
                                            color: Colors.transparent,
                                            width: 3,
                                          ),
                                        ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        _MethodBadge(
                                          method: ep.httpMethod ?? 'GET',
                                          compact: true,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            ep.name,
                                            style: TextStyle(
                                              fontWeight: isSelected
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                              color: colors.onSurface,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      ep.url,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: colors.onSurfaceVariant,
                                        fontFamily: 'JetBrains Mono',
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),

          // --- RIGHT PANE: WORKSPACE ---
          Expanded(
            child: _selectedEndpoint == null
                ? _EmptyState(
                    projectId: widget.projectId,
                    onCreated: (ep) => setState(() => _selectedEndpoint = ep),
                  )
                : _EndpointWorkspace(
                    key: ValueKey(_selectedEndpoint!.id),
                    endpoint: _selectedEndpoint!,
                    projectId: widget.projectId,
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

class _MethodBadge extends StatelessWidget {
  final String method;
  final bool compact;
  const _MethodBadge({required this.method, this.compact = false});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (method.toUpperCase()) {
      case 'POST':
        color = Colors.green;
        break;
      case 'DELETE':
        color = Colors.red;
        break;
      case 'PUT':
        color = Colors.orange;
        break;
      case 'PATCH':
        color = Colors.purple;
        break;
      default:
        color = Colors.blue;
    }
    return Text(
      method.toUpperCase().substring(
        0,
        compact && method.length > 3 ? 3 : null,
      ),
      style: TextStyle(
        fontSize: compact ? 10 : 11,
        fontWeight: FontWeight.bold,
        color: color,
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
          Icon(
            Icons.api,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'Select an endpoint or create a new one',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              // Quick create action
              _showCreateDialog(context);
            },
            child: const Text('Create Endpoint'),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    String method = 'GET';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Endpoint'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: urlCtrl,
              decoration: const InputDecoration(labelText: 'URL'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: method,
              items: [
                'GET',
                'POST',
                'PUT',
                'DELETE',
                'PATCH',
              ].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (v) => method = v!,
              decoration: const InputDecoration(labelText: 'Method'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty || urlCtrl.text.isEmpty) return;
              try {
                final ep = await context
                    .read<EndpointProvider>()
                    .createEndpoint({
                      'name': nameCtrl.text,
                      'url': urlCtrl.text,
                      'httpMethod': method,
                      'type': 'HTTP',
                      'projectId': projectId,
                    });
                if (context.mounted) {
                  Navigator.pop(ctx);
                  onCreated(ep);
                }
              } catch (e) {
                // Handle error
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
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

  // Request Data
  late TextEditingController _bodyCtrl;
  Map<String, String> _headers = {};
  Map<String, String> _params = {};

  // Response Data
  Map<String, dynamic>? _response;
  bool _isLoading = false;
  int? _statusCode;
  int? _responseTime;

  late TabController _reqTabCtrl;
  late TabController _resTabCtrl;

  @override
  void initState() {
    super.initState();
    _urlCtrl = TextEditingController(text: widget.endpoint.url);
    _nameCtrl = TextEditingController(text: widget.endpoint.name);
    _method = widget.endpoint.httpMethod ?? 'GET';

    // Initialize Body
    String bodyText = '';
    if (widget.endpoint.httpBody != null) {
      if (widget.endpoint.httpBody is String) {
        bodyText = widget.endpoint.httpBody;
      } else {
        bodyText = const JsonEncoder.withIndent(
          '  ',
        ).convert(widget.endpoint.httpBody);
      }
    }
    _bodyCtrl = TextEditingController(text: bodyText);

    // Initialize Headers/Params
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

    _reqTabCtrl = TabController(length: 3, vsync: this);
    _resTabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _nameCtrl.dispose();
    _bodyCtrl.dispose();
    _reqTabCtrl.dispose();
    _resTabCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    try {
      // Parse body if JSON
      dynamic bodyPayload = _bodyCtrl.text;
      try {
        if (bodyPayload.trim().startsWith('{') ||
            bodyPayload.trim().startsWith('[')) {
          bodyPayload = jsonDecode(bodyPayload);
        }
      } catch (_) {} // Keep as string if invalid JSON

      final data = {
        'name': _nameCtrl.text,
        'url': _urlCtrl.text,
        'httpMethod': _method,
        'httpBody': bodyPayload,
        'httpHeaders': _headers,
        'httpParameters': _params,
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
            'httpBody': bodyPayload,
            'httpHeaders': _headers,
            'httpParameters': _params,
          });

      setState(() {
        _response = result;
        _statusCode = result['statusCode'];
        _responseTime = result['responseTimeMs'];
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
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // --- TOP BAR ---
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(bottom: BorderSide(color: colors.outlineVariant)),
          ),
          child: Column(
            children: [
              // Name Row
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: 'Endpoint Name',
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _save,
                    icon: const Icon(Icons.save_outlined),
                    tooltip: 'Save',
                  ),
                  IconButton(
                    onPressed: widget.onDeleted,
                    icon: const Icon(Icons.delete_outline),
                    color: colors.error,
                    tooltip: 'Delete',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Request Row
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: colors.outlineVariant),
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(4),
                      ),
                      color: colors.surfaceContainerLow,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _method,
                        items: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH']
                            .map(
                              (m) => DropdownMenuItem(
                                value: m,
                                child: Text(
                                  m,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _getMethodColor(m),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _method = v!),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _urlCtrl,
                      decoration: InputDecoration(
                        hintText: 'Enter request URL',
                        border: OutlineInputBorder(
                          borderRadius: const BorderRadius.horizontal(
                            right: Radius.circular(4),
                          ),
                          borderSide: BorderSide(color: colors.outlineVariant),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        isDense: true,
                      ),
                      style: const TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _isLoading ? null : _send,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send, size: 16),
                    label: const Text('Send'),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // --- REQUEST TABS ---
        Container(
          color: colors.surface,
          child: TabBar(
            controller: _reqTabCtrl,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: colors.primary,
            unselectedLabelColor: colors.onSurfaceVariant,
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: colors.outlineVariant,
            tabs: const [
              Tab(text: 'Params'),
              Tab(text: 'Headers'),
              Tab(text: 'Body'),
            ],
          ),
        ),

        // --- REQUEST EDITOR ---
        Expanded(
          flex: 3,
          child: TabBarView(
            controller: _reqTabCtrl,
            children: [
              _KeyValueEditor(data: _params, onChanged: (d) => _params = d),
              _KeyValueEditor(data: _headers, onChanged: (d) => _headers = d),
              Padding(
                padding: const EdgeInsets.all(1.0),
                child: TextField(
                  controller: _bodyCtrl,
                  maxLines: null,
                  expands: true,
                  style: const TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 13,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Request Body (JSON)',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                ),
              ),
            ],
          ),
        ),

        // --- RESPONSE SECTION ---
        const Divider(height: 1),
        Container(
          height: 40,
          color: colors.surfaceContainerLow,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text(
                'Response',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const Spacer(),
              if (_statusCode != null) ...[
                Text(
                  'Status: $_statusCode',
                  style: TextStyle(
                    color: _statusCode! >= 200 && _statusCode! < 300
                        ? Colors.green
                        : Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Time: ${_responseTime}ms',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Container(
            color: colors.surface,
            child: _response == null
                ? Center(
                    child: Text(
                      'Enter URL and click Send to get a response',
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: SelectableText(
                      _getResponseBody(_response),
                      style: const TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 12,
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  String _getResponseBody(Map<String, dynamic>? response) {
    if (response == null) return '';
    if (response.containsKey('error') && response.length == 1) {
      return response['error'].toString();
    }
    if (response['success'] == false && response.containsKey('message')) {
      return response['message'].toString();
    }
    if (response.containsKey('body')) {
      final body = response['body'];
      if (body is Map || body is List) {
        return const JsonEncoder.withIndent('  ').convert(body);
      }
      return body.toString();
    }
    return const JsonEncoder.withIndent('  ').convert(response);
  }

  Color _getMethodColor(String method) {
    switch (method) {
      case 'POST':
        return Colors.green;
      case 'DELETE':
        return Colors.red;
      case 'PUT':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }
}

class _KeyValueEditor extends StatefulWidget {
  final Map<String, String> data;
  final ValueChanged<Map<String, String>> onChanged;

  const _KeyValueEditor({required this.data, required this.onChanged});

  @override
  State<_KeyValueEditor> createState() => _KeyValueEditorState();
}

class _KeyValueEditorState extends State<_KeyValueEditor> {
  late List<MapEntry<TextEditingController, TextEditingController>>
  _controllers;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    _controllers = widget.data.entries
        .map(
          (e) => MapEntry(
            TextEditingController(text: e.key),
            TextEditingController(text: e.value),
          ),
        )
        .toList();
    // Add empty row
    _addEmptyRow();
  }

  void _addEmptyRow() {
    _controllers.add(
      MapEntry(TextEditingController(), TextEditingController()),
    );
  }

  void _updateData() {
    final newData = <String, String>{};
    for (var entry in _controllers) {
      if (entry.key.text.isNotEmpty) {
        newData[entry.key.text] = entry.value.text;
      }
    }
    widget.onChanged(newData);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListView.separated(
      itemCount: _controllers.length,
      separatorBuilder: (c, i) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final entry = _controllers[index];
        return Row(
          children: [
            Expanded(
              child: TextField(
                controller: entry.key,
                decoration: const InputDecoration(
                  hintText: 'Key',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                ),
                style: const TextStyle(fontSize: 13),
                onChanged: (v) {
                  if (index == _controllers.length - 1 && v.isNotEmpty) {
                    setState(() => _addEmptyRow());
                  }
                  _updateData();
                },
              ),
            ),
            Container(width: 1, height: 24, color: colors.outlineVariant),
            Expanded(
              child: TextField(
                controller: entry.value,
                decoration: const InputDecoration(
                  hintText: 'Value',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                ),
                style: const TextStyle(fontSize: 13),
                onChanged: (v) => _updateData(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 16),
              onPressed: () {
                if (index < _controllers.length - 1) {
                  setState(() {
                    _controllers.removeAt(index);
                    _updateData();
                  });
                }
              },
            ),
          ],
        );
      },
    );
  }
}
