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
    // Initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EndpointProvider>().loadEndpoints(projectId: widget.projectId);
    });
  }

  void _createNewEndpoint() {
    setState(() {
      _selectedEndpoint = null; // null indicates "New Mode" if we want,
      // but for master-detail, let's select a 'draft' object or handle 'new' differently.
      // simpler: Just deselect to clear the right pane form for creation
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final provider = context.watch<EndpointProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Endpoints'),
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: colors.outlineVariant),
        ),
      ),
      body: Row(
        children: [
          // --- LEFT PANE: LIST ---
          SizedBox(
            width: 300,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: FilledButton.icon(
                    onPressed: () {
                      setState(() => _selectedEndpoint = null);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('New Endpoint'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ),
                Expanded(
                  child: provider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.separated(
                    itemCount: provider.endpoints.length,
                    separatorBuilder: (c, i) => Divider(height: 1, color: colors.outlineVariant.withAlpha(50)),
                    itemBuilder: (context, index) {
                      final ep = provider.endpoints[index];
                      final isSelected = _selectedEndpoint?.id == ep.id;

                      return ListTile(
                        selected: isSelected,
                        selectedTileColor: colors.primaryContainer.withAlpha(50),
                        leading: _MethodBadge(method: ep.httpMethod ?? 'GET'),
                        title: Text(
                          ep.name,
                          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          ep.url,
                          style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant, fontFamily: 'monospace'),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => setState(() => _selectedEndpoint = ep),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          VerticalDivider(width: 1, color: colors.outlineVariant),

          // --- RIGHT PANE: DETAIL / EDIT / EXECUTE ---
          Expanded(
            child: _selectedEndpoint == null
                ? _CreateEndpointView(projectId: widget.projectId, onSaved: (newEp) {
              setState(() => _selectedEndpoint = newEp); // Auto select created
            })
                : _EndpointDetailView(
              key: ValueKey(_selectedEndpoint!.id), // Re-build on selection change
              endpoint: _selectedEndpoint!,
              projectId: widget.projectId,
              onDeleted: () {
                setState(() => _selectedEndpoint = null);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MethodBadge extends StatelessWidget {
  final String method;
  const _MethodBadge({required this.method});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (method.toUpperCase()) {
      case 'POST': color = Colors.green; break;
      case 'DELETE': color = Colors.red; break;
      case 'PUT': color = Colors.orange; break;
      case 'PATCH': color = Colors.purple; break;
      default: color = Colors.blue;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        method.toUpperCase(),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}

// --- VIEW FOR CREATING NEW ENDPOINT ---
class _CreateEndpointView extends StatelessWidget {
  final int projectId;
  final Function(Endpoint) onSaved;

  const _CreateEndpointView({required this.projectId, required this.onSaved});

  @override
  Widget build(BuildContext context) {
    return _EndpointForm(
        projectId: projectId,
        endpoint: null,
        onSaveSuccess: (data) async {
          // Since the provider reloads the list, we might need to find the new item
          // For simplicity, we just trigger the callback.
          // In a real app, the create API should return the full object.
          // Assuming createEndpoint returns void but refreshes list.
          // We'll rely on the user selecting it or simple feedback.
        }
    );
  }
}

// --- VIEW FOR EDITING & EXECUTING ---
class _EndpointDetailView extends StatefulWidget {
  final Endpoint endpoint;
  final int projectId;
  final VoidCallback onDeleted;

  const _EndpointDetailView({
    super.key,
    required this.endpoint,
    required this.projectId,
    required this.onDeleted
  });

  @override
  State<_EndpointDetailView> createState() => _EndpointDetailViewState();
}

class _EndpointDetailViewState extends State<_EndpointDetailView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(bottom: BorderSide(color: colors.outlineVariant)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.endpoint.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(widget.endpoint.url, style: TextStyle(color: colors.onSurfaceVariant, fontFamily: 'monospace', fontSize: 12)),
                  ],
                ),
              ),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: colors.primary,
                unselectedLabelColor: colors.onSurfaceVariant,
                indicatorColor: colors.primary,
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Definition', icon: Icon(Icons.edit_note, size: 18)),
                  Tab(text: 'Test & Execute', icon: Icon(Icons.play_circle_outline, size: 18)),
                ],
              ),
            ],
          ),
        ),

        // Body
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: Edit Form
              SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _EndpointForm(
                  projectId: widget.projectId,
                  endpoint: widget.endpoint,
                  onDelete: widget.onDeleted,
                ),
              ),

              // Tab 2: Execution
              _ExecutionPanel(endpoint: widget.endpoint),
            ],
          ),
        ),
      ],
    );
  }
}

// --- SHARED FORM COMPONENT ---
class _EndpointForm extends StatefulWidget {
  final int projectId;
  final Endpoint? endpoint;
  final VoidCallback? onDelete;
  final Function(Map<String, dynamic>)? onSaveSuccess;

  const _EndpointForm({
    required this.projectId,
    this.endpoint,
    this.onDelete,
    this.onSaveSuccess,
  });

  @override
  State<_EndpointForm> createState() => _EndpointFormState();
}

class _EndpointFormState extends State<_EndpointForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _urlCtrl;
  late TextEditingController _descCtrl;
  String _method = 'GET';

  final _methods = ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'HEAD', 'OPTIONS'];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.endpoint?.name ?? '');
    _urlCtrl = TextEditingController(text: widget.endpoint?.url ?? '');
    _descCtrl = TextEditingController(text: widget.endpoint?.description ?? '');
    if (widget.endpoint?.httpMethod != null) {
      _method = widget.endpoint!.httpMethod!;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _urlCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<EndpointProvider>();
    final data = {
      'name': _nameCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'url': _urlCtrl.text.trim(),
      'httpMethod': _method,
      'type': 'HTTP',
      'projectId': widget.projectId,
    };

    try {
      if (widget.endpoint != null) {
        await provider.updateEndpoint(widget.endpoint!.id, data);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved changes')));
      } else {
        await provider.createEndpoint(data);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Endpoint created')));
        // If creating, we might want to clear form or select it.
        if (widget.onSaveSuccess != null) widget.onSaveSuccess!(data);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isEditing = widget.endpoint != null;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isEditing ? 'Edit Definition' : 'Create New Endpoint', style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          Row(
            children: [
              SizedBox(
                width: 120,
                child: DropdownButtonFormField<String>(
                  value: _method,
                  decoration: const InputDecoration(labelText: 'Method'),
                  items: _methods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  onChanged: (v) => setState(() => _method = v!),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _urlCtrl,
            decoration: const InputDecoration(labelText: 'URL Endpoint', prefixIcon: Icon(Icons.link)),
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descCtrl,
            decoration: const InputDecoration(labelText: 'Description'),
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.check),
                label: const Text('Save Definition'),
              ),
              if (isEditing && widget.onDelete != null) ...[
                const Spacer(),
                TextButton.icon(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Confirm Delete'),
                        content: const Text('Are you sure?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await context.read<EndpointProvider>().deleteEndpoint(widget.endpoint!.id, widget.projectId);
                      widget.onDelete!();
                    }
                  },
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('Delete Endpoint'),
                  style: TextButton.styleFrom(foregroundColor: colors.error),
                )
              ]
            ],
          )
        ],
      ),
    );
  }
}

// --- EXECUTION PANEL ---
class _ExecutionPanel extends StatefulWidget {
  final Endpoint endpoint;
  const _ExecutionPanel({required this.endpoint});

  @override
  State<_ExecutionPanel> createState() => _ExecutionPanelState();
}

class _ExecutionPanelState extends State<_ExecutionPanel> {
  final TextEditingController _bodyCtrl = TextEditingController(text: "{\n  \n}");
  String? _responseJson;
  int? _statusCode; // Mock status code for now since result is just Map

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final provider = context.watch<EndpointProvider>();

    return Row(
      children: [
        // Left: Request Config
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.all(16),
            color: colors.surfaceContainerLow.withAlpha(50),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Request Body (JSON)', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Expanded(
                  child: TextField(
                    controller: _bodyCtrl,
                    maxLines: null,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: colors.surface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: provider.isExecuting ? null : _run,
                    icon: provider.isExecuting
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send_rounded),
                    label: Text(provider.isExecuting ? 'Sending...' : 'Send Request'),
                  ),
                ),
              ],
            ),
          ),
        ),

        VerticalDivider(width: 1, color: colors.outlineVariant),

        // Right: Response
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.all(16),
            color: colors.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Response', style: TextStyle(fontWeight: FontWeight.bold)),
                    if (_statusCode != null) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                            color: Colors.green.withAlpha(30),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.green)
                        ),
                        child: const Text('200 OK', style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
                      )
                    ]
                  ],
                ),
                const Divider(),
                Expanded(
                  child: _responseJson == null
                      ? Center(child: Text('Hit Send to see response', style: TextStyle(color: colors.onSurfaceVariant)))
                      : SingleChildScrollView(
                    child: SelectableText(
                      _responseJson!,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _run() async {
    try {
      // Validate JSON
      Map<String, dynamic> body = {};
      if (_bodyCtrl.text.trim().isNotEmpty) {
        try {
          body = jsonDecode(_bodyCtrl.text);
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid JSON in body'), backgroundColor: Colors.red));
          return;
        }
      }

      final result = await context.read<EndpointProvider>().executeEndpoint(widget.endpoint.id, body);

      setState(() {
        _responseJson = const JsonEncoder.withIndent('  ').convert(result);
        _statusCode = 200; // Assuming success if no error thrown
      });

    } catch (e) {
      setState(() {
        _responseJson = "Error: $e";
        _statusCode = null;
      });
    }
  }
}