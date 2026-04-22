import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/features/endpoints/domain/models/endpoint.dart';
import 'package:stress_pilot/features/shared/presentation/provider/endpoint_provider.dart';
import 'package:stress_pilot/features/endpoints/presentation/widgets/json_viewer.dart';

class EndpointEditor extends StatefulWidget {
  final Endpoint endpoint;
  const EndpointEditor({super.key, required this.endpoint});

  @override
  State<EndpointEditor> createState() => _EndpointEditorState();
}

class _EndpointEditorState extends State<EndpointEditor> with TickerProviderStateMixin {
  late TextEditingController _urlCtrl;
  late TextEditingController _nameCtrl;
  late String _method;
  late TextEditingController _bodyCtrl;

  Map<String, String> _headers = {};
  Map<String, String> _params = {};

  Map<String, dynamic>? _response;
  bool _isLoading = false;
  int? _statusCode;
  int? _responseTime;

  late TabController _reqTabCtrl;

  @override
  void initState() {
    super.initState();
    _urlCtrl = TextEditingController(text: widget.endpoint.url ?? '');
    _nameCtrl = TextEditingController(text: widget.endpoint.name);
    _method = widget.endpoint.httpMethod ?? 'GET';

    String bodyText = '';
    if (widget.endpoint.body != null) {
      if (widget.endpoint.body is String) {
        bodyText = widget.endpoint.body;
      } else {
        bodyText = const JsonEncoder.withIndent('  ').convert(widget.endpoint.body);
      }
    }
    _bodyCtrl = TextEditingController(text: bodyText);

    if (widget.endpoint.httpHeaders != null) {
      widget.endpoint.httpHeaders!.forEach((k, v) => _headers[k] = v.toString());
    }
    if (widget.endpoint.httpParameters != null) {
      widget.endpoint.httpParameters!.forEach((k, v) => _params[k] = v.toString());
    }

    _reqTabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _nameCtrl.dispose();
    _bodyCtrl.dispose();
    _reqTabCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final provider = context.read<EndpointProvider>();
    setState(() {
      _isLoading = true;
      _response = null;
    });

    try {
      dynamic bodyPayload = _bodyCtrl.text;
      try {
        if (bodyPayload.trim().isNotEmpty) {
          bodyPayload = jsonDecode(bodyPayload);
        }
      } catch (_) {}

      final result = await provider.executeEndpoint(widget.endpoint.id, {
        'url': _urlCtrl.text,
        'httpMethod': _method,
        'body': bodyPayload,
        'httpHeaders': _headers,
        'httpParameters': _params,
      });

      if (!mounted) return;
      setState(() {
        _response = result;
        final responseData = result.containsKey('data') && result['data'] is Map
            ? result['data'] as Map<String, dynamic>
            : result;
        _statusCode = responseData['statusCode'];
        _responseTime = responseData['responseTimeMs'];
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _response = {'error': e.toString()});
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.baseBackground,
      child: Column(
        children: [
          // Toolbar
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              children: [
                _MethodDropdown(
                  value: _method,
                  onChanged: (v) => setState(() => _method = v!),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _UrlField(controller: _urlCtrl),
                ),
                const SizedBox(width: 8),
                ShadButton(
                  onPressed: _isLoading ? null : _send,
                  child: Text(_isLoading ? 'Stop' : 'Send'),
                ),
              ],
            ),
          ),

          // Tabs
          Container(
            height: 32,
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.divider)),
            ),
            child: TabBar(
              controller: _reqTabCtrl,
              isScrollable: true,
              indicatorColor: AppColors.accent,
              labelColor: AppColors.textPrimary,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: AppTypography.label,
              tabs: const [
                Tab(text: 'Params'),
                Tab(text: 'Headers'),
                Tab(text: 'Body'),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _reqTabCtrl,
              children: [
                _buildPlaceholder('Params'),
                _buildPlaceholder('Headers'),
                _buildBodyEditor(),
              ],
            ),
          ),

          // Response area
          if (_response != null)
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.divider)),
                ),
                child: Column(
                  children: [
                    Container(
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Text('Response', style: AppTypography.label),
                          const Spacer(),
                          if (_statusCode != null)
                            _StatusBadge(code: _statusCode!),
                          const SizedBox(width: 8),
                          if (_responseTime != null)
                            Text('${_responseTime}ms', style: AppTypography.caption),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: JsonViewer(json: _response!),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBodyEditor() {
    return TextField(
      controller: _bodyCtrl,
      maxLines: null,
      expands: true,
      style: AppTypography.code,
      decoration: const InputDecoration(
        border: InputBorder.none,
        contentPadding: EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildPlaceholder(String text) {
    return Center(child: Text(text, style: AppTypography.body.copyWith(color: AppColors.textSecondary)));
  }
}

class _MethodDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String?> onChanged;

  const _MethodDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: value,
      items: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'].map((m) {
        return DropdownMenuItem(value: m, child: Text(m, style: AppTypography.code.copyWith(fontWeight: FontWeight.bold)));
      }).toList(),
      onChanged: onChanged,
      underline: const SizedBox(),
      dropdownColor: AppColors.elevatedSurface,
    );
  }
}

class _UrlField extends StatelessWidget {
  final TextEditingController controller;
  const _UrlField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: AppTypography.code,
      decoration: InputDecoration(
        hintText: 'Enter URL...',
        hintStyle: AppTypography.code.copyWith(color: AppColors.textDisabled),
        border: InputBorder.none,
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final int code;
  const _StatusBadge({required this.code});

  @override
  Widget build(BuildContext context) {
    final color = code < 400 ? AppColors.methodGet : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.br4,
      ),
      child: Text(code.toString(), style: AppTypography.label.copyWith(color: color)),
    );
  }
}
