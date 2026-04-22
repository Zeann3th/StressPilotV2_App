import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stress_pilot/core/themes/components/components.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/features/projects/domain/models/canvas.dart';
import 'package:stress_pilot/features/shared/presentation/provider/endpoint_provider.dart';
import 'package:stress_pilot/features/endpoints/domain/models/endpoint.dart' as domain_endpoint;

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

    return PilotDialog(
      title: 'Node Configuration',
      maxWidth: 800,
      content: SizedBox(
        height: 500,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ID: ${widget.node.id}',
              style: AppTypography.caption.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Details'),
                Tab(text: 'Pre-Processor'),
                Tab(text: 'Post-Processor'),
              ],
              labelColor: AppColors.accent,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.accent,
              labelStyle: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
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
          ],
        ),
      ),
      actions: [
        if (_endpointDetail != null)
          PilotButton.ghost(
            label: 'Navigate to Endpoint',
            icon: LucideIcons.externalLink,
            onPressed: () {
              Navigator.of(context).pop({
                'action': 'navigate',
                'endpoint': _endpointDetail,
              });
            },
          ),
        PilotButton.ghost(
          label: 'Cancel',
          onPressed: () => Navigator.of(context).pop(),
        ),
        PilotButton.primary(
          label: 'Save Changes',
          onPressed: () {
            Navigator.of(context).pop({
              'preProcessor': _preProcessor,
              'postProcessor': _postProcessor,
            });
          },
        ),
      ],
    );
  }

  Widget _buildDetailsTab() {
    if (_isLoadingEndpoint) {
      return const Center(child: CircularProgressIndicator());
    }

    final endpoint = _endpointDetail;
    final primaryTextColor = AppColors.textPrimary;
    final secondaryTextColor = AppColors.textSecondary;
    final mutedTextColor = AppColors.textMuted;

    if (endpoint == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 48, color: mutedTextColor),
            const SizedBox(height: 16),
            Text(
              'Endpoint details not available',
              style: TextStyle(color: mutedTextColor),
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
            _buildDetailRow('Name', endpoint.name, primaryTextColor, secondaryTextColor),
            _buildDetailRow('Type', endpoint.type, primaryTextColor, secondaryTextColor),
            _buildDetailRow('URL', endpoint.url ?? '—', primaryTextColor, secondaryTextColor),
            if (endpoint.httpMethod != null)
              _buildDetailRow('Method', endpoint.httpMethod!.toUpperCase(), primaryTextColor, secondaryTextColor),
          ]),

          if (endpoint.type == 'GRPC')
            _buildDetailSection('gRPC Configuration', [
              _buildDetailRow('Service', endpoint.grpcServiceName ?? '—', primaryTextColor, secondaryTextColor),
              _buildDetailRow('Method', endpoint.grpcMethodName ?? '—', primaryTextColor, secondaryTextColor),
            ]),

          const SizedBox(height: 8),
          Text(
            'DATA & PAYLOAD',
            style: AppTypography.label.copyWith(fontWeight: FontWeight.bold, color: AppColors.accent),
          ),
          const Divider(),

          if (endpoint.httpHeaders != null && endpoint.httpHeaders!.isNotEmpty)
            _buildCodeBlock('Headers', jsonEncode(endpoint.httpHeaders)),

          if (endpoint.body != null && endpoint.body!.toString().isNotEmpty)
            _buildCodeBlock('Body / Payload', endpoint.body.toString()),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: AppTypography.label.copyWith(fontWeight: FontWeight.bold, color: AppColors.accent),
        ),
        const Divider(),
        const SizedBox(height: 8),
        ...children,
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, Color primaryColor, Color secondaryColor) {
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
                color: secondaryColor,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(color: primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeBlock(String title, String code) {
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
            color: AppColors.elevated,
            borderRadius: AppRadius.br8,
            border: Border.all(color: AppColors.border),
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
  late TextEditingController _delayController;
  late TextEditingController _injectController;
  late TextEditingController _extractController;

  @override
  void initState() {
    super.initState();

    _delayController = TextEditingController(
      text: widget.data['delay']?.toString() ?? '',
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
    final newData = Map<String, dynamic>.from(widget.data);

    if (_delayController.text.isNotEmpty) {
      newData['delay'] = int.tryParse(_delayController.text);
    } else {
      newData.remove('delay');
    }

    if (_injectController.text.isNotEmpty) {
      try {
        newData['inject'] = jsonDecode(_injectController.text);
      } catch (_) {}
    } else {
      newData.remove('inject');
    }

    if (_extractController.text.isNotEmpty) {
      try {
        newData['extract'] = jsonDecode(_extractController.text);
      } catch (_) {}
    } else {
      newData.remove('extract');
    }

    widget.onChanged(newData);
  }

  @override
  void dispose() {
    _delayController.dispose();
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
          'Delay (ms)',
          'Delay execution by milliseconds',
          _delayController,
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
    bool isMultiline = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        PilotInput(
          controller: controller,
          placeholder: hint,
          maxLines: isMultiline ? 8 : 1,
          onChanged: (_) => _updateData(),
          style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 13),
        ),
      ],
    );
  }
}
