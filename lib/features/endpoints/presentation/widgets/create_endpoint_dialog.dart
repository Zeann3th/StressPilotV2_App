import 'dart:convert';
import 'dart:async' as async_timer;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stress_pilot/core/di/locator.dart';
import 'package:stress_pilot/core/themes/components/components.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/features/shared/domain/repositories/utility_repository.dart';

import 'package:stress_pilot/features/endpoints/data/curl_parser.dart';
import 'package:stress_pilot/features/endpoints/presentation/provider/endpoint_provider.dart';
import 'key_value_editor.dart';

class CreateEndpointDialog extends StatefulWidget {
  final int projectId;

  const CreateEndpointDialog({super.key, required this.projectId});

  @override
  State<CreateEndpointDialog> createState() => _CreateEndpointDialogState();
}

class _CreateEndpointDialogState extends State<CreateEndpointDialog> {

  final _nameCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  String _selectedType = 'HTTP';
  final _descCtrl = TextEditingController();

  String _httpMethod = 'GET';
  final _bodyCtrl = TextEditingController();
  Map<String, String> _headers = {};
  final Map<String, String> _params = {};
  async_timer.Timer? _debounce;

  final _grpcServiceCtrl = TextEditingController();
  final _grpcMethodCtrl = TextEditingController();
  final _grpcStubCtrl = TextEditingController();

  List<String> _availableTypes = ['HTTP', 'GRPC', 'JDBC', 'JS', 'TCP'];

  @override
  void initState() {
    super.initState();
    _loadCapabilities();
  }

  Future<void> _loadCapabilities() async {
    try {
      final capabilities = await getIt<UtilityRepository>().getCapabilities();
      if (capabilities.endpointExecutors.isNotEmpty) {
        setState(() {
          _availableTypes = capabilities.endpointExecutors;
          if (!_availableTypes.contains(_selectedType)) {
            _selectedType = _availableTypes.first;
          }
        });
      }
    } catch (_) {}
  }

  void _handleUrlChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = async_timer.Timer(const Duration(milliseconds: 300), () {
      if (value.trim().toLowerCase().startsWith('curl ')) {
        final data = CurlParser.parse(value);
        setState(() {
          if (data.url != null && data.url!.isNotEmpty) _urlCtrl.text = data.url!;
          if (data.method != null) _httpMethod = data.method!;
          if (data.headers != null) _headers = {...data.headers!};
          if (data.body != null) _bodyCtrl.text = data.body!;
          _selectedType = 'HTTP';
        });
      }
    });
  }

  void _beautifyJson() {
    try {
      final content = _bodyCtrl.text.trim();
      if (content.isEmpty) return;
      final decoded = jsonDecode(content);
      const encoder = JsonEncoder.withIndent('  ');
      setState(() {
        _bodyCtrl.text = encoder.convert(decoded);
      });
    } catch (e) {
      PilotToast.show(context, 'Invalid JSON', isError: true);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _nameCtrl.dispose();
    _urlCtrl.dispose();
    _descCtrl.dispose();
    _bodyCtrl.dispose();
    _grpcServiceCtrl.dispose();
    _grpcMethodCtrl.dispose();
    _grpcStubCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_nameCtrl.text.trim().isEmpty) {
      PilotToast.show(context, 'Name is required', isError: true);
      return;
    }

    try {
      dynamic bodyPayload = _bodyCtrl.text;
      try {
        if (bodyPayload.trim().startsWith('{') ||
            bodyPayload.trim().startsWith('[')) {
          bodyPayload = jsonDecode(bodyPayload);
        }
      } catch (_) {}

      final data = {
        'projectId': widget.projectId,
        'name': _nameCtrl.text,
        'url': _urlCtrl.text,
        'type': _selectedType,
        'description': _descCtrl.text,

        'httpMethod': _httpMethod,
        'body': bodyPayload,
        'httpHeaders': _headers,
        'httpParameters': _params,

        'grpcServiceName': _grpcServiceCtrl.text.isNotEmpty
            ? _grpcServiceCtrl.text
            : null,
        'grpcMethodName': _grpcMethodCtrl.text.isNotEmpty
            ? _grpcMethodCtrl.text
            : null,
        'grpcStubPath': _grpcStubCtrl.text.isNotEmpty
            ? _grpcStubCtrl.text
            : null,
      };

      final ep = await context.read<EndpointProvider>().createEndpoint(data);
      if (mounted) {
        Navigator.pop(context, ep);
        PilotToast.show(context, 'Endpoint created');
      }
    } catch (e) {
      if (mounted) {
        PilotToast.show(context, 'Error: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PilotDialog(
      title: 'New Endpoint',
      maxWidth: 800,
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _FieldLabel('Name *'),
                      const SizedBox(height: 6),
                      PilotInput(
                        controller: _nameCtrl,
                        placeholder: 'e.g. Get User Profile',
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _FieldLabel('Type *'),
                      const SizedBox(height: 6),
                      _buildDropdown(
                        value: _selectedType,
                        items: _availableTypes,
                        onChanged: (v) => setState(() => _selectedType = v!),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const _FieldLabel('URL / Connection String *'),
            const SizedBox(height: 6),
            PilotInput(
              controller: _urlCtrl,
              placeholder: _getUrlLabel(),
              onChanged: _handleUrlChanged,
            ),
            const SizedBox(height: 16),
            const _FieldLabel('Description'),
            const SizedBox(height: 6),
            PilotInput(
              controller: _descCtrl,
              placeholder: 'Optional description...',
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            Text(
              'PROTOCOL DETAILS',
              style: AppTypography.label.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            const Divider(),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const _FieldLabel('Body / Payload'),
                PilotButton.ghost(
                  label: 'Beautify',
                  onPressed: _beautifyJson,
                ),
              ],
            ),
            const SizedBox(height: 6),
            PilotInput(
              controller: _bodyCtrl,
              placeholder: _getBodyPlaceholder(),
              maxLines: 8,
              style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 13),
            ),
            const SizedBox(height: 24),

            if (_selectedType == 'HTTP') _buildHttpFields(),
            if (_selectedType == 'GRPC') _buildGrpcFields(),
          ],
        ),
      ),
      actions: [
        PilotButton.ghost(
          label: 'Cancel',
          onPressed: () => Navigator.pop(context),
        ),
        PilotButton.primary(
          label: 'Create Endpoint',
          onPressed: _create,
        ),
      ],
    );
  }

  String _getBodyPlaceholder() {
    switch (_selectedType) {
      case 'JDBC':
        return 'SELECT * FROM users LIMIT 10';
      case 'JS':
        return '// Your JS code here';
      case 'GRPC':
        return '{"id": 123}';
      default:
        return '{"key": "value"}';
    }
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.elevated,
        borderRadius: AppRadius.br8,
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: items
              .map((t) => DropdownMenuItem(value: t, child: Text(t)))
              .toList(),
          onChanged: onChanged,
          dropdownColor: AppColors.surface,
          style: AppTypography.body.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  String _getUrlLabel() {
    switch (_selectedType) {
      case 'JDBC':
        return 'jdbc:mysql://localhost:3306/db';
      case 'TCP':
        return 'localhost:8080';
      case 'JS':
        return 'Script Identifier';
      default:
        return 'https://api.example.com/v1/resource';
    }
  }

  Widget _buildHttpFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('HTTP Method *'),
        const SizedBox(height: 6),
        _buildDropdown(
          value: _httpMethod,
          items: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'HEAD', 'OPTIONS'],
          onChanged: (v) => setState(() => _httpMethod = v!),
        ),
        const SizedBox(height: 16),
        const _FieldLabel('Headers'),
        const SizedBox(height: 6),
        Container(
          height: 150,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
            borderRadius: AppRadius.br8,
          ),
          child: KeyValueEditor(data: _headers, onChanged: (d) => _headers = d),
        ),
      ],
    );
  }

  Widget _buildGrpcFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('Service Name *'),
        const SizedBox(height: 6),
        PilotInput(controller: _grpcServiceCtrl, placeholder: 'com.example.UserService'),
        const SizedBox(height: 16),
        const _FieldLabel('Method Name *'),
        const SizedBox(height: 6),
        PilotInput(controller: _grpcMethodCtrl, placeholder: 'GetUser'),
        const SizedBox(height: 16),
        const _FieldLabel('Stub Path (Proto File) *'),
        const SizedBox(height: 6),
        PilotInput(controller: _grpcStubCtrl, placeholder: '/path/to/service.proto'),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.label.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
