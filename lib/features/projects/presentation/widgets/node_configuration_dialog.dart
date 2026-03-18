import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/core/domain/entities/canvas.dart';
import 'package:stress_pilot/features/endpoints/presentation/provider/endpoint_provider.dart';
import 'package:stress_pilot/core/domain/entities/endpoint.dart' as domain_endpoint;

class NodeConfigurationDialog extends StatefulWidget {
  final CanvasNode node;

  const NodeConfigurationDialog({super.key, required this.node});

  @override
  State<NodeConfigurationDialog> createState() =>
      _NodeConfigurationDialogState();
}

class _NodeConfigurationDialogState extends State<NodeConfigurationDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Map<String, dynamic> _preProcessor;
  late Map<String, dynamic> _postProcessor;
  domain_endpoint.Endpoint? _endpointDetail;
  bool _isLoadingEndpoint = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    _preProcessor = Map<String, dynamic>.from(
      widget.node.data['preProcessor'] ?? {},
    );
    _postProcessor = Map<String, dynamic>.from(
      widget.node.data['postProcessor'] ?? {},
    );

    _fetchEndpointDetails();
  }

  Future<void> _fetchEndpointDetails() async {
    final endpointId = widget.node.data['id'];
    if (endpointId == null) return;

    setState(() => _isLoadingEndpoint = true);
    try {
      final provider = context.read<EndpointProvider>();
      final endpoint = await provider.getEndpoint(endpointId);
      if (mounted) {
        setState(() {
          _endpointDetail = endpoint;
          _isLoadingEndpoint = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingEndpoint = false);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenHeight = MediaQuery.of(context).size.height;
        final dialogHeight = (640.0).clamp(0.0, screenHeight * 0.9);

        return Dialog(
          backgroundColor: colors.surface,
          surfaceTintColor: colors.surfaceTint,
          child: Container(
            width: 800,
            height: dialogHeight,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Node Configuration',
                          style: AppTypography.title.copyWith(fontSize: 18),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ID: ${widget.node.id}',
                          style: AppTypography.caption.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Details'),
                    Tab(text: 'Pre-Processor'),
                    Tab(text: 'Post-Processor'),
                  ],
                  labelColor: colors.primary,
                  unselectedLabelColor: colors.onSurfaceVariant,
                  indicatorColor: colors.primary,
                  labelStyle:
                      AppTypography.body.copyWith(fontWeight: FontWeight.w600),
                  unselectedLabelStyle: AppTypography.body,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildDetailsTab(),
                      _ProcessorEditor(
                        key: const ValueKey('pre'),
                        data: _preProcessor,
                        onChanged: (data) => _preProcessor = data,
                      ),
                      _ProcessorEditor(
                        key: const ValueKey('post'),
                        data: _postProcessor,
                        onChanged: (data) => _postProcessor = data,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: () {
                        Navigator.of(context).pop({
                          'preProcessor': _preProcessor,
                          'postProcessor': _postProcessor,
                        });
                      },
                      child: const Text('Save Changes'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailsTab() {
    if (_isLoadingEndpoint) {
      return const Center(child: CircularProgressIndicator());
    }

    final endpoint = _endpointDetail;
    final colors = Theme.of(context).colorScheme;

    if (endpoint == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 48, color: colors.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              'Endpoint details not available',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailSection('Basic Information', [
            _buildDetailRow('Name', endpoint.name),
            _buildDetailRow('Type', endpoint.type),
            _buildDetailRow('URL', endpoint.url ?? '—'),
            if (endpoint.httpMethod != null)
              _buildDetailRow('Method', endpoint.httpMethod!.toUpperCase()),
            if (endpoint.description != null && endpoint.description!.isNotEmpty)
              _buildDetailRow('Description', endpoint.description!),
          ]),
          
          if (endpoint.type == 'GRPC')
            _buildDetailSection('gRPC Configuration', [
              _buildDetailRow('Service', endpoint.grpcServiceName ?? '—'),
              _buildDetailRow('Method', endpoint.grpcMethodName ?? '—'),
              _buildDetailRow('Stub Path', endpoint.grpcStubPath ?? '—'),
            ]),

          if (endpoint.type == 'GRAPHQL')
            _buildDetailSection('GraphQL Configuration', [
              _buildDetailRow('Operation', endpoint.graphqlOperationType ?? '—'),
            ]),

          if (endpoint.successCondition != null && endpoint.successCondition!.isNotEmpty)
            _buildDetailSection('Validation', [
              _buildDetailRow('Success Condition', endpoint.successCondition!),
            ]),

          const SizedBox(height: 8),
          Text(
            'Data & Payload',
            style: AppTypography.bodyLg.copyWith(fontWeight: FontWeight.bold, color: colors.primary),
          ),
          const Divider(),
          
          if (endpoint.httpHeaders != null && endpoint.httpHeaders!.isNotEmpty)
            _buildCodeBlock('Headers', jsonEncode(endpoint.httpHeaders)),
          
          if (endpoint.httpParameters != null && endpoint.httpParameters!.isNotEmpty)
            _buildCodeBlock('Query Parameters', jsonEncode(endpoint.httpParameters)),
          
          if (endpoint.body != null && endpoint.body!.toString().isNotEmpty)
            _buildCodeBlock('Body / Payload', endpoint.body.toString()),

          if (endpoint.graphqlVariables != null && endpoint.graphqlVariables!.isNotEmpty)
            _buildCodeBlock('GraphQL Variables', jsonEncode(endpoint.graphqlVariables)),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.bodyLg.copyWith(fontWeight: FontWeight.bold, color: colors.primary),
        ),
        const Divider(),
        const SizedBox(height: 8),
        ...children,
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(color: colors.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeBlock(String title, String code) {
    final colors = Theme.of(context).colorScheme;
    String formattedCode = code;
    try {
      final decoded = jsonDecode(code);
      formattedCode = const JsonEncoder.withIndent('  ').convert(decoded);
    } catch (_) {}

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: SelectableText(
            formattedCode,
            style: const TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProcessorEditor extends StatefulWidget {
  final Map<String, dynamic> data;
  final ValueChanged<Map<String, dynamic>> onChanged;

  const _ProcessorEditor({
    super.key,
    required this.data,
    required this.onChanged,
  });

  @override
  State<_ProcessorEditor> createState() => _ProcessorEditorState();
}

class _ProcessorEditorState extends State<_ProcessorEditor> {
  late TextEditingController _sleepController;
  late TextEditingController _injectController;
  late TextEditingController _extractController;

  @override
  void initState() {
    super.initState();

    _sleepController = TextEditingController(
      text: widget.data['sleep']?.toString() ?? '',
    );
    _injectController = TextEditingController(
      text: _formatJson(widget.data['inject']),
    );
    _extractController = TextEditingController(
      text: _formatJson(widget.data['extract']),
    );
  }

  String _formatJson(dynamic data) {
    if (data == null) return '';
    try {
      return const JsonEncoder.withIndent('  ').convert(data);
    } catch (e) {
      return data.toString();
    }
  }

  void _updateData() {
    final newData = <String, dynamic>{};

    if (_sleepController.text.isNotEmpty) {
      newData['sleep'] = int.tryParse(_sleepController.text);
    }

    if (_injectController.text.isNotEmpty) {
      try {
        newData['inject'] = jsonDecode(_injectController.text);
      } catch (_) {}
    }

    if (_extractController.text.isNotEmpty) {
      try {
        newData['extract'] = jsonDecode(_extractController.text);
      } catch (_) {}
    }

    widget.onChanged(newData);
  }

  @override
  void dispose() {
    _sleepController.dispose();
    _injectController.dispose();
    _extractController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _buildSection(
          context,
          'Sleep (ms)',
          'Delay execution by milliseconds',
          _sleepController,
          isNumeric: true,
        ),
        const SizedBox(height: 16),
        _buildSection(
          context,
          'Inject Variables (JSON)',
          '{"key": "value"}',
          _injectController,
          isMultiline: true,
        ),
        const SizedBox(height: 16),
        _buildSection(
          context,
          'Extract Variables (JSON)',
          '{"varName": "path.to.value"}',
          _extractController,
          isMultiline: true,
        ),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context,
    String label,
    String hint,
    TextEditingController controller, {
    bool isNumeric = false,
    bool isMultiline = false,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          onChanged: (_) => _updateData(),
          keyboardType: isNumeric
              ? TextInputType.number
              : TextInputType.multiline,
          maxLines: isMultiline ? 10 : 1,
          minLines: isMultiline ? 5 : 1,
          decoration: InputDecoration(
            hintText: hint,
            fillColor: colors.surfaceContainerLow,
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.outlineVariant),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
          style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 13),
        ),
      ],
    );
  }
}