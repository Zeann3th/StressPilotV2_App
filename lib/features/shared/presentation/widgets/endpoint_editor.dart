import 'dart:convert';
import 'dart:async' as async_timer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/core/themes/components/components.dart';
import 'package:stress_pilot/features/endpoints/domain/models/endpoint.dart';
import 'package:stress_pilot/features/shared/presentation/provider/endpoint_provider.dart';
import 'package:stress_pilot/features/endpoints/data/curl_parser.dart';
import 'package:stress_pilot/features/endpoints/presentation/widgets/json_viewer.dart';
import 'package:stress_pilot/features/endpoints/presentation/widgets/key_value_editor.dart';

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
  late TextEditingController _successConditionCtrl;

  final Map<String, String> _headers = {};
  final Map<String, String> _params = {};
  Map<String, String> _variables = {};

  Map<String, dynamic>? _response;
  int? _statusCode;
  int? _responseTime;
  int _elapsedMs = 0;
  bool? _isSuccess;
  bool _showRaw = false;
  double _responsePanelHeight = 300.0;

  final TextEditingController _searchCtrl = TextEditingController();
  bool _showSearch = false;
  final FocusNode _searchFocusNode = FocusNode();
  final FocusNode _keyboardFocusNode = FocusNode();
  int _currentSearchMatchIndex = 0;
  int _totalMatchesCount = 0;

  late TabController _reqTabCtrl;
  late ScrollController _responseScrollCtrl;
  late ScrollController _bodyScrollCtrl;
  late ScrollController _paramsScrollCtrl;
  late ScrollController _headersScrollCtrl;
  late ScrollController _settingsScrollCtrl;

  async_timer.Timer? _syncTimer;
  async_timer.Timer? _beautifyTimer;
  async_timer.Timer? _debounce;
  async_timer.Timer? _executionTimer;

  @override
  void initState() {
    super.initState();
    _urlCtrl = TextEditingController(text: widget.endpoint.url ?? '');
    _nameCtrl = TextEditingController(text: widget.endpoint.name);
    _method = widget.endpoint.httpMethod ?? 'GET';
    _responseScrollCtrl = ScrollController();
    _bodyScrollCtrl = ScrollController();
    _paramsScrollCtrl = ScrollController();
    _headersScrollCtrl = ScrollController();
    _settingsScrollCtrl = ScrollController();

    String bodyText = '';
    if (widget.endpoint.body != null) {
      if (widget.endpoint.body is String) {
        bodyText = widget.endpoint.body;
      } else {
        bodyText = const JsonEncoder.withIndent('  ').convert(widget.endpoint.body);
      }
    }
    _bodyCtrl = TextEditingController(text: bodyText);
    _successConditionCtrl = TextEditingController(text: widget.endpoint.successCondition ?? '');

    if (widget.endpoint.httpHeaders != null) {
      widget.endpoint.httpHeaders!.forEach((k, v) => _headers[k] = v.toString());
    }
    if (widget.endpoint.httpParameters != null) {
      widget.endpoint.httpParameters!.forEach((k, v) => _params[k] = v.toString());
    }

    _reqTabCtrl = TabController(length: 4, vsync: this);

    _loadResults();

    _bodyCtrl.addListener(_queueSync);
    _successConditionCtrl.addListener(_queueSync);
  }

  void _startTimer() {
    _executionTimer?.cancel();
    _elapsedMs = 0;
    _executionTimer = async_timer.Timer.periodic(const Duration(milliseconds: 10), (timer) {
      if (mounted) {
        setState(() {
          _elapsedMs += 10;
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _stopTimer() {
    _executionTimer?.cancel();
    _executionTimer = null;
  }
  void _loadResults() {
    final provider = context.read<EndpointProvider>();
    if (provider.isEndpointExecuting(widget.endpoint.id)) {
      if (_executionTimer == null) _startTimer();
    } else {
      _stopTimer();
    }

    final cachedResult = provider.getExecutionResult(widget.endpoint.id);
    if (cachedResult != null) {
      _response = cachedResult;
      final responseData = cachedResult.containsKey('data') && cachedResult['data'] is Map
          ? cachedResult['data'] as Map<String, dynamic>
          : cachedResult;
      _statusCode = responseData['statusCode'];
      _responseTime = responseData['responseTimeMs'];
      if (responseData.containsKey('success')) {
        _isSuccess = responseData['success'] as bool?;
      }
    }
  }

  void _queueSync() {
    _syncTimer?.cancel();
    _syncTimer = async_timer.Timer(const Duration(milliseconds: 500), _syncToProvider);
  }

  void _syncToProvider() {
    if (!mounted) return;

    dynamic bodyPayload = _bodyCtrl.text;
    try {
      if (bodyPayload.trim().startsWith('{') ||
          bodyPayload.trim().startsWith('[')) {
        bodyPayload = jsonDecode(bodyPayload);
      }
    } catch (_) {}

    final transientData = {
      'url': _urlCtrl.text,
      'httpMethod': _method,
      'httpHeaders': _headers,
      'httpParameters': _params,
      'body': bodyPayload,
      'successCondition': _successConditionCtrl.text,
    };

    context.read<EndpointProvider>().updateTransientState(widget.endpoint.id, transientData);
  }

  void _scheduleBeautify() {
    _beautifyTimer?.cancel();
    _beautifyTimer = async_timer.Timer(const Duration(milliseconds: 700), () {
      final text = _bodyCtrl.text.trim();
      if (text.isEmpty) return;
      try {
        final decoded = jsonDecode(text);
        final pretty = const JsonEncoder.withIndent('  ').convert(decoded);
        if (pretty != _bodyCtrl.text) {
          final sel = _bodyCtrl.selection;
          _bodyCtrl.value = TextEditingValue(
            text: pretty,
            selection: sel.isValid && sel.end <= pretty.length
                ? sel
                : TextSelection.collapsed(offset: pretty.length),
          );
        }
      } catch (_) {}
    });
  }

  void _handleUrlChanged(String value) {
    _queueSync();
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = async_timer.Timer(const Duration(milliseconds: 300), () {
      if (value.trim().toLowerCase().startsWith('curl ')) {
        final data = CurlParser.parse(value);
        setState(() {
          if (data.url != null && data.url!.isNotEmpty) _urlCtrl.text = data.url!;
          if (data.method != null) _method = data.method!;
          if (data.headers != null) _headers.addAll(data.headers!);
          if (data.body != null && data.body!.isNotEmpty) _bodyCtrl.text = data.body!;
        });
        _queueSync();
      }
    });
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _beautifyTimer?.cancel();
    _debounce?.cancel();
    _executionTimer?.cancel();
    _urlCtrl.dispose();
    _nameCtrl.dispose();
    _bodyCtrl.dispose();
    _successConditionCtrl.dispose();
    _reqTabCtrl.dispose();
    _responseScrollCtrl.dispose();
    _bodyScrollCtrl.dispose();
    _paramsScrollCtrl.dispose();
    _headersScrollCtrl.dispose();
    _settingsScrollCtrl.dispose();
    _searchCtrl.dispose();
    _searchFocusNode.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  String _generateCurlCommand() {
    final url = _urlCtrl.text;
    final method = _method;
    final headers = _headers;
    final body = _bodyCtrl.text;

    var curl = 'curl -X $method "$url"';
    headers.forEach((key, value) {
      curl += ' \\\n  -H "$key: $value"';
    });

    if (body.isNotEmpty && (method == 'POST' || method == 'PUT' || method == 'PATCH' || method == 'DELETE')) {
      final escapedBody = body.replaceAll("'", "'\\''");
      curl += " \\\n  -d '$escapedBody'";
    }
    return curl;
  }

  void _showExportCurlDialog() {
    final curlCommand = _generateCurlCommand();
    final scrollCtrl = ScrollController();
    showDialog(
      context: context,
      builder: (context) {
        return PilotDialog(
          title: 'Export to cURL',
          maxWidth: 600,
          content: Container(
            constraints: const BoxConstraints(maxHeight: 400),
            child: Stack(
              children: [
                Scrollbar(
                  controller: scrollCtrl,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
                    child: SelectableText(
                      curlCommand,
                      style: const TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Tooltip(
                    message: 'Copy to clipboard',
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: curlCommand));
                          PilotToast.show(context, 'Copied to clipboard');
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: const Icon(
                            LucideIcons.copy,
                            size: 18,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            PilotButton.primary(
              label: 'Done',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  Future<void> _save() async {
    try {
      dynamic bodyPayload = _bodyCtrl.text;
      try {
        if (bodyPayload.trim().startsWith('{') || bodyPayload.trim().startsWith('[')) {
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
        'projectId': widget.endpoint.projectId,
      };

      await context.read<EndpointProvider>().updateEndpoint(widget.endpoint.id, data);
      if (mounted) PilotToast.show(context, 'Saved');
    } catch (e) {
      if (mounted) PilotToast.show(context, 'Error: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final border = AppColors.border;
    final textColor = AppColors.textPrimary;
    final secondaryText = AppColors.textSecondary;
    final bg = AppColors.baseBackground;
    final surface = AppColors.sidebarBackground;

    final endpointProvider = context.watch<EndpointProvider>();
    _loadResults();

    return KeyboardListener(
      focusNode: _keyboardFocusNode,
      onKeyEvent: (event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.keyF &&
            (HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed)) {
          setState(() {
            _showSearch = !_showSearch;
            if (_showSearch) {
              _searchFocusNode.requestFocus();
            } else {
              _searchCtrl.clear();
            }
          });
        }
      },
      child: Column(
        children: [

          Container(
            decoration: BoxDecoration(
              color: bg,
              border: Border(bottom: BorderSide(color: AppColors.divider)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _MethodDropdown(
                        value: _method,
                        onChanged: (v) {
                          setState(() => _method = v!);
                          _queueSync();
                        },
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _UrlField(
                          controller: _urlCtrl,
                          onChanged: _handleUrlChanged,
                        ),
                      ),
                      const SizedBox(width: 16),
                      PilotButton.ghost(
                        icon: LucideIcons.code,
                        onPressed: _showExportCurlDialog,
                        compact: true,
                      ),
                      const SizedBox(width: 8),
                      PilotButton.ghost(
                        icon: LucideIcons.save,
                        onPressed: _save,
                        compact: true,
                        tooltip: 'Save',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Container(
            height: 38,
            decoration: BoxDecoration(
              color: bg,
              border: Border(bottom: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TabBar(
                  controller: _reqTabCtrl,
                  isScrollable: true,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorColor: AppColors.accent,
                  indicatorWeight: 2,
                  dividerColor: Colors.transparent,
                  labelColor: AppColors.textPrimary,
                  unselectedLabelColor: AppColors.textSecondary,
                  labelStyle: AppTypography.label.copyWith(fontWeight: FontWeight.w600),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  tabs: const [
                    Tab(text: 'Params'),
                    Tab(text: 'Headers'),
                    Tab(text: 'Body'),
                    Tab(text: 'Configuration'),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: LayoutBuilder(
              builder: (ctx, constraints) {
                final totalH = constraints.maxHeight;
                final respH = _responsePanelHeight.clamp(40.0, totalH - 100.0);

                return Column(
                  children: [
                    Expanded(
                      child: TabBarView(
                        controller: _reqTabCtrl,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: KeyValueEditor(
                              data: _params,
                              onChanged: (d) {
                                _params.addAll(d);
                                _queueSync();
                              },
                              controller: _paramsScrollCtrl,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: KeyValueEditor(
                              data: _headers,
                              onChanged: (d) {
                                _headers.addAll(d);
                                _queueSync();
                              },
                              controller: _headersScrollCtrl,
                            ),
                          ),
                          TextField(
                            controller: _bodyCtrl,
                            scrollController: _bodyScrollCtrl,
                            maxLines: null,
                            expands: true,
                            style: AppTypography.code.copyWith(fontSize: 13),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(16),
                              hintText: 'Request Body (JSON)',
                            ),
                            onChanged: (v) {
                              _queueSync();
                              _scheduleBeautify();
                            },
                          ),
                          _buildConfigurationTab(textColor, secondaryText, border),
                        ],
                      ),
                    ),

                    if (endpointProvider.isResponsePanelVisible) ...[
                      MouseRegion(
                        cursor: SystemMouseCursors.resizeRow,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onVerticalDragUpdate: (d) {
                            setState(() {
                              _responsePanelHeight = (_responsePanelHeight - d.delta.dy)
                                  .clamp(40.0, totalH - 100.0);
                            });
                          },
                          child: Container(
                            height: 8,
                            color: border.withValues(alpha: 0.1),
                            alignment: Alignment.center,
                            child: Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: border.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(
                        height: respH,
                        child: Container(
                          color: bg,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [

                              Container(
                                height: 36,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: surface,
                                  border: Border(bottom: BorderSide(color: border.withValues(alpha: 0.1))),
                                ),
                                child: Row(
                                  children: [
                                    _buildRespTab('Response', !_showRaw, secondaryText),
                                    const SizedBox(width: 4),
                                    _buildRespTab('Raw', _showRaw, secondaryText),
                                    const Spacer(),
                                    if (endpointProvider.isEndpointExecuting(widget.endpoint.id))
                                      Text('${_elapsedMs}ms', style: TextStyle(color: secondaryText, fontSize: 12, fontFamily: 'JetBrains Mono'))
                                    else if (_statusCode != null) ...[
                                      _buildStatusBadge(_isSuccess ?? (_statusCode! < 400), _statusCode!),
                                      const SizedBox(width: 10),
                                      Text('${_responseTime}ms', style: TextStyle(color: secondaryText, fontSize: 12, fontFamily: 'JetBrains Mono')),
                                    ],
                                    const SizedBox(width: 8),
                                    _IconButton(
                                      icon: LucideIcons.minus,
                                      onTap: () => endpointProvider.setResponsePanelVisible(false),
                                    ),
                                  ],
                                ),
                              ),

                              if (_showSearch)
                                Container(
                                  height: 38,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: surface,
                                    border: Border(bottom: BorderSide(color: border.withValues(alpha: 0.1))),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(LucideIcons.search, size: 14, color: secondaryText),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextField(
                                          controller: _searchCtrl,
                                          focusNode: _searchFocusNode,
                                          textInputAction: TextInputAction.next,
                                          decoration: const InputDecoration(
                                            hintText: 'Find in response...',
                                            border: InputBorder.none,
                                            isDense: true,
                                          ),
                                          style: TextStyle(fontSize: 13, color: textColor),
                                          onChanged: (v) {
                                            setState(() {
                                              _currentSearchMatchIndex = 0;
                                            });
                                          },
                                          onSubmitted: (_) {
                                            if (_totalMatchesCount > 0) {
                                              setState(() {
                                                _currentSearchMatchIndex = (_currentSearchMatchIndex + 1) % _totalMatchesCount;
                                              });
                                              _searchFocusNode.requestFocus();
                                            }
                                          },
                                        ),
                                      ),
                                      if (_totalMatchesCount > 0) ...[
                                        Text(
                                          '${_currentSearchMatchIndex + 1} / $_totalMatchesCount',
                                          style: TextStyle(fontSize: 11, color: secondaryText, fontFamily: 'JetBrains Mono'),
                                        ),
                                        const SizedBox(width: 8),
                                        PilotButton.ghost(
                                          icon: LucideIcons.chevronUp,
                                          compact: true,
                                          onPressed: () {
                                            if (_totalMatchesCount > 0) {
                                              setState(() {
                                                _currentSearchMatchIndex = (_currentSearchMatchIndex - 1 + _totalMatchesCount) % _totalMatchesCount;
                                              });
                                            }
                                          },
                                        ),
                                        PilotButton.ghost(
                                          icon: LucideIcons.chevronDown,
                                          compact: true,
                                          onPressed: () {
                                            if (_totalMatchesCount > 0) {
                                              setState(() {
                                                _currentSearchMatchIndex = (_currentSearchMatchIndex + 1) % _totalMatchesCount;
                                              });
                                            }
                                          },
                                        ),
                                        const VerticalDivider(width: 16, indent: 8, endIndent: 8),
                                      ],
                                      PilotButton.ghost(
                                        icon: LucideIcons.x,
                                        compact: true,
                                        onPressed: () => setState(() {
                                          _showSearch = false;
                                          _searchCtrl.clear();
                                          _totalMatchesCount = 0;
                                          _currentSearchMatchIndex = 0;
                                        }),
                                      ),
                                    ],
                                  ),
                                ),

                              Expanded(
                                child: _response == null
                                    ? _buildResponseEmptyState(secondaryText)
                                    : Scrollbar(
                                        controller: _responseScrollCtrl,
                                        thumbVisibility: true,
                                        child: SingleChildScrollView(
                                          controller: _responseScrollCtrl,
                                          child: Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                _showRaw
                                                    ? SelectableText(
                                                        _getRawResponse(_response!),
                                                        style: TextStyle(
                                                          fontFamily: 'JetBrains Mono',
                                                          fontSize: 12,
                                                          color: textColor,
                                                        ),
                                                      )
                                                    : JsonViewer(
                                                        json: _getResponseData(_response!),
                                                        searchQuery: _searchCtrl.text,
                                                        activeMatchIndex: _currentSearchMatchIndex,
                                                        onMatchesCountChanged: (count) {
                                                          if (_totalMatchesCount != count) {
                                                            setState(() => _totalMatchesCount = count);
                                                          }
                                                        },
                                                      ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigurationTab(Color textColor, Color secondaryText, Color border) {
    return ListView(
      controller: _settingsScrollCtrl,
      padding: const EdgeInsets.all(16),
      children: [
        Text('Success Condition (SpEL)', style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 13)),
        const SizedBox(height: 8),
        TextField(
          controller: _successConditionCtrl,
          style: TextStyle(fontSize: 13, color: textColor),
          decoration: InputDecoration(
            hintText: 'e.g., #statusCode == 200 && #body.status == "OK"',
            hintStyle: TextStyle(color: secondaryText.withValues(alpha: 0.5)),
            filled: true,
            fillColor: AppColors.elevated,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            helperText: 'Available variables: #statusCode, #body, #headers, #responseTime',
            helperStyle: TextStyle(color: secondaryText, fontSize: 11),
          ),
          minLines: 1,
          maxLines: 3,
        ),
        const SizedBox(height: 24),
        Text('Result Variables', style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 13)),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(minHeight: 100, maxHeight: 300),
          decoration: BoxDecoration(
            border: Border.all(color: border.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: KeyValueEditor(
            data: _variables,
            onChanged: (d) {
              _variables = d;
              _queueSync();
            },
            controller: _settingsScrollCtrl,
          ),
        ),
      ],
    );
  }

  Widget _buildRespTab(String label, bool active, Color secondaryText) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _showRaw = label == 'Raw';
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active ? AppColors.accent : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active ? AppColors.textPrimary : secondaryText,
              fontSize: 12,
              fontWeight: active ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool success, int code) {
    final color = success ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        success ? 'SUCCESS ($code)' : 'FAILED ($code)',
        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 10, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildResponseEmptyState(Color secondaryText) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.send, size: 32, color: secondaryText.withValues(alpha: 0.2)),
          const SizedBox(height: 12),
          Text('Run endpoint to see results', style: TextStyle(color: secondaryText, fontSize: 13)),
        ],
      ),
    );
  }

  Map<String, dynamic> _getResponseData(Map<String, dynamic> r) {
    if (r.containsKey('error')) return {'error': r['error']};
    
    final outerData = r['data'];
    if (outerData is Map<String, dynamic>) {
      final innerData = outerData['data'];
      
      // If innerData is a Map, that's what we want.
      if (innerData is Map<String, dynamic>) return innerData;
      
      // If innerData is null but outerData is the response wrapper, 
      // try to return outerData without metadata.
      final cleaned = Map<String, dynamic>.from(outerData);
      cleaned.removeWhere((k, _) => const {
        'statusCode', 'success', 'responseTimeMs', 'message', 'rawResponse'
      }.contains(k));
      
      // If after cleaning we still have a 'data' key that is null, 
      // it means the actual server payload was null.
      return cleaned;
    }
    return r;
  }

  String _getRawResponse(Map<String, dynamic> r) {
    final outerData = r['data'];
    if (outerData is Map<String, dynamic>) {
      final raw = outerData['rawResponse'];
      if (raw is String) {
        try {
          final decoded = jsonDecode(raw);
          return const JsonEncoder.withIndent('  ').convert(decoded);
        } catch (_) {
          return raw;
        }
      }
    }
    return const JsonEncoder.withIndent('  ').convert(r);
  }
}

class _MethodDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String?> onChanged;

  const _MethodDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final accentColor = AppColors.accent;
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        dropdownColor: AppColors.elevatedSurface,
        icon: Icon(LucideIcons.chevronDown, size: 12, color: AppColors.textSecondary),
        items: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'].map((m) {
          final methodColor = {
            'GET': const Color(0xFF10B981),
            'POST': const Color(0xFF3B82F6),
            'PUT': const Color(0xFFF59E0B),
            'DELETE': const Color(0xFFEF4444),
            'PATCH': const Color(0xFF8B5CF6),
          }[m] ?? accentColor;
          return DropdownMenuItem(
            value: m,
            child: Text(m, style: TextStyle(color: methodColor, fontSize: 13, fontWeight: FontWeight.w700))
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _UrlField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  const _UrlField({required this.controller, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: AppTypography.code.copyWith(fontSize: 13),
      decoration: InputDecoration(
        hintText: 'https://api.example.com/v1/resource',
        hintStyle: AppTypography.code.copyWith(color: AppColors.textDisabled, fontSize: 13),
        border: InputBorder.none,
      ),
    );
  }
}

class _IconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconButton({required this.icon, required this.onTap});

  @override
  State<_IconButton> createState() => _IconButtonState();
}

class _IconButtonState extends State<_IconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: _isHovered ? AppColors.hoverItem : Colors.transparent,
            borderRadius: AppRadius.br4,
          ),
          child: Icon(
            widget.icon,
            size: 14,
            color: _isHovered ? AppColors.accent : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
