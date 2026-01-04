import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../common/presentation/provider/endpoint_provider.dart';
import '../widgets/key_value_editor.dart';

class CreateEndpointDialog extends StatefulWidget {
  final int projectId;

  const CreateEndpointDialog({super.key, required this.projectId});

  @override
  State<CreateEndpointDialog> createState() => _CreateEndpointDialogState();
}

class _CreateEndpointDialogState extends State<CreateEndpointDialog> {
  final _formKey = GlobalKey<FormState>();

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
    if (!_formKey.currentState!.validate()) return;

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
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Dialog(
      child: Container(
        width: 800,
        constraints: const BoxConstraints(maxHeight: 900),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'New Endpoint',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _nameCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Name *',
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) =>
                                  v?.isEmpty == true ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 1,
                            child: DropdownButtonFormField<String>(
                              value: _selectedType,
                              decoration: const InputDecoration(
                                labelText: 'Type *',
                                border: OutlineInputBorder(),
                              ),
                              items: ['HTTP', 'GRPC', 'JDBC', 'JS', 'TCP']
                                  .map(
                                    (t) => DropdownMenuItem(
                                      value: t,
                                      child: Text(t),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _selectedType = v!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _urlCtrl,
                        decoration: InputDecoration(
                          labelText: _getUrlLabel(),
                          border: const OutlineInputBorder(),
                          helperText: _getUrlHelper(),
                        ),
                        validator: (v) {
                          if (_selectedType == 'JS')
                            return null; // Optional for JS
                          if (v == null || v.isEmpty) return 'Required';

                          if (_selectedType == 'JDBC' &&
                              !v.startsWith('jdbc:')) {
                            return 'Must start with "jdbc:"';
                          }
                          if (_selectedType == 'TCP' && !v.contains(':')) {
                            return 'Must be in "host:port" format';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                      Text(
                        'Protocol Details',
                        style: TextStyle(
                          color: colors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_selectedType == 'HTTP') _buildHttpFields(colors),
                      if (_selectedType == 'GRPC') _buildGrpcFields(),
                      if (_selectedType == 'JDBC') _buildJdbcFields(),
                      if (_selectedType == 'JS') _buildJsFields(),
                      if (_selectedType == 'TCP') _buildTcpFields(),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _create,
                    child: const Text('Create Endpoint'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getUrlLabel() {
    switch (_selectedType) {
      case 'JDBC':
        return 'Connection String (JDBC URL) *';
      case 'TCP':
        return 'Host:Port *';
      case 'JS':
        return 'Script Name / Identifier (Optional)';
      default:
        return 'URL *';
    }
  }

  String? _getUrlHelper() {
    if (_selectedType == 'JS') {
      return 'Can be left empty if script is self-contained';
    }
    return null;
  }

  Widget _buildHttpFields(ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: _httpMethod,
          decoration: const InputDecoration(
            labelText: 'HTTP Method *',
            border: OutlineInputBorder(),
          ),
          items: [
            'GET',
            'POST',
            'PUT',
            'DELETE',
            'PATCH',
            'HEAD',
            'OPTIONS',
          ].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
          onChanged: (v) => setState(() => _httpMethod = v!),
          validator: (v) => v == null ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        const Text('Headers'),
        const SizedBox(height: 8),
        Container(
          height: 150,
          decoration: BoxDecoration(
            border: Border.all(color: colors.outlineVariant),
            borderRadius: BorderRadius.circular(4),
          ),
          child: KeyValueEditor(data: _headers, onChanged: (d) => _headers = d),
        ),
        const SizedBox(height: 16),
        const Text('Parameters'),
        const SizedBox(height: 8),
        Container(
          height: 150,
          decoration: BoxDecoration(
            border: Border.all(color: colors.outlineVariant),
            borderRadius: BorderRadius.circular(4),
          ),
          child: KeyValueEditor(data: _params, onChanged: (d) => _params = d),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _bodyCtrl,
          decoration: const InputDecoration(
            labelText: 'Initial Body (JSON)',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          maxLines: 5,
          style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildGrpcFields() {
    return Column(
      children: [
        TextFormField(
          controller: _grpcServiceCtrl,
          decoration: const InputDecoration(
            labelText: 'Service Name *',
            border: OutlineInputBorder(),
          ),
          validator: (v) => v?.isEmpty == true ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _grpcMethodCtrl,
          decoration: const InputDecoration(
            labelText: 'Method Name *',
            border: OutlineInputBorder(),
          ),
          validator: (v) => v?.isEmpty == true ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _grpcStubCtrl,
          decoration: const InputDecoration(
            labelText: 'Stub Path (Proto File) *',
            border: OutlineInputBorder(),
          ),
          validator: (v) => v?.isEmpty == true ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _bodyCtrl,
          decoration: const InputDecoration(
            labelText: 'Initial Message (JSON Body)',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          maxLines: 5,
          style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildJdbcFields() {
    return Column(
      children: [
        TextFormField(
          controller: _bodyCtrl,
          decoration: const InputDecoration(
            labelText: 'SQL Query *',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
            hintText: 'SELECT * FROM users LIMIT 10',
          ),
          maxLines: 5,
          style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 13),
          validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
        ),
      ],
    );
  }

  Widget _buildJsFields() {
    return Column(
      children: [
        TextFormField(
          controller: _bodyCtrl,
          decoration: const InputDecoration(
            labelText: 'JavaScript Code *',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          maxLines: 15,
          style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 13),
          validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
        ),
      ],
    );
  }

  Widget _buildTcpFields() {
    return Column(
      children: [
        TextFormField(
          controller: _bodyCtrl,
          decoration: const InputDecoration(
            labelText: 'Payload (Text/JSON) *',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          maxLines: 5,
          style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 13),
          validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
        ),
      ],
    );
  }
}
