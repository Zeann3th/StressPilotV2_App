import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stress_pilot/core/di/locator.dart';
import 'package:stress_pilot/core/themes/components/components.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/features/common/data/utility_service.dart';

import '../presentation/provider/endpoint_provider.dart';
import '../widgets/key_value_editor.dart';

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
  Map<String, String> _params = {};

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
      final capabilities = await getIt<UtilityService>().getCapabilities();
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

  @override
  void dispose() {
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
            if (_selectedType == 'HTTP') _buildHttpFields(),
            if (_selectedType == 'GRPC') _buildGrpcFields(),
            if (_selectedType == 'JDBC') _buildJdbcFields(),
            if (_selectedType == 'JS') _buildJsFields(),
            if (_selectedType == 'TCP') _buildTcpFields(),
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

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkElevated : AppColors.lightElevated,
        borderRadius: AppRadius.br8,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
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
          dropdownColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          style: AppTypography.body.copyWith(
            color: isDark ? AppColors.textPrimary : AppColors.textLight,
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
            border: Border.all(color: AppColors.darkBorder.withValues(alpha: 0.5)),
            borderRadius: AppRadius.br8,
          ),
          child: KeyValueEditor(data: _headers, onChanged: (d) => _headers = d),
        ),
        const SizedBox(height: 16),
        const _FieldLabel('Initial Body (JSON)'),
        const SizedBox(height: 6),
        PilotInput(
          controller: _bodyCtrl,
          placeholder: '{"key": "value"}',
          maxLines: 5,
          style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 13),
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
        const SizedBox(height: 16),
        const _FieldLabel('Initial Message (JSON)'),
        const SizedBox(height: 6),
        PilotInput(
          controller: _bodyCtrl,
          placeholder: '{"id": 123}',
          maxLines: 5,
          style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildJdbcFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('SQL Query *'),
        const SizedBox(height: 6),
        PilotInput(
          controller: _bodyCtrl,
          placeholder: 'SELECT * FROM users LIMIT 10',
          maxLines: 8,
          style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildJsFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('JavaScript Code *'),
        const SizedBox(height: 6),
        PilotInput(
          controller: _bodyCtrl,
          placeholder: '// Your JS code here',
          maxLines: 15,
          style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildTcpFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('Payload (Text/JSON) *'),
        const SizedBox(height: 6),
        PilotInput(
          controller: _bodyCtrl,
          placeholder: 'Enter TCP payload',
          maxLines: 5,
          style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 13),
        ),
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
