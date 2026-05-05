import 'dart:convert';
import 'dart:async' as async_timer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/core/themes/components/components.dart';
import 'package:stress_pilot/features/endpoints/domain/models/endpoint.dart';
import 'package:stress_pilot/features/endpoints/presentation/provider/endpoint_provider.dart';
import 'package:stress_pilot/features/endpoints/data/curl_parser.dart';
import 'package:stress_pilot/features/endpoints/presentation/widgets/editor/endpoint_editor_header.dart';
import 'package:stress_pilot/features/endpoints/presentation/widgets/editor/endpoint_editor_tabs.dart';
import 'package:stress_pilot/features/endpoints/presentation/widgets/editor/endpoint_editor_response_panel.dart';

class EndpointEditor extends StatefulWidget {
  final Endpoint endpoint;
  const EndpointEditor({super.key, required this.endpoint});

  @override
  State<EndpointEditor> createState() => _EndpointEditorState();
}

class _EndpointEditorState extends State<EndpointEditor> with TickerProviderStateMixin {
  late TextEditingController _urlCtrl;
  late String _method;
  late TextEditingController _bodyCtrl;
  late TextEditingController _successConditionCtrl;

  final Map<String, String> _headers = {};
  final Map<String, String> _params = {};
  Map<String, String> _variables = {};

  Map<String, dynamic>? _response;
  int? _statusCode;
  int? _responseTime;
  final ValueNotifier<int> _elapsedMsNotifier = ValueNotifier(0);
  bool? _isSuccess;
  bool _showRaw = false;
  late ValueNotifier<double> _responsePanelHeight;

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
  async_timer.Timer? _debounce;
  async_timer.Timer? _executionTimer;

  @override
  void initState() {
    super.initState();
    _urlCtrl = TextEditingController(text: widget.endpoint.url ?? '');
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
    if (widget.endpoint.variables != null) {
      widget.endpoint.variables!.forEach((k, v) => _variables[k] = v.toString());
    }

    _reqTabCtrl = TabController(length: 4, vsync: this);
    _responsePanelHeight = ValueNotifier<double>(300.0);

    _loadResults();

    _successConditionCtrl.addListener(_queueSync);
  }

  void _startTimer() {
    _executionTimer?.cancel();
    _elapsedMsNotifier.value = 0;
    _executionTimer = async_timer.Timer.periodic(const Duration(milliseconds: 10), (timer) {
      if (mounted) {
        _elapsedMsNotifier.value += 10;
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
      'variables': _variables,
      'successCondition': _successConditionCtrl.text,
    };

    context.read<EndpointProvider>().updateTransientState(widget.endpoint.id, transientData);
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
    _debounce?.cancel();
    _executionTimer?.cancel();
    _urlCtrl.dispose();
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
    _responsePanelHeight.dispose();
    _elapsedMsNotifier.dispose();
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
                      style: AppTypography.code.copyWith(fontSize: 13),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Tooltip(
                    message: 'Copy to clipboard',
                    child: PilotButton.ghost(
                      icon: LucideIcons.copy,
                      compact: true,
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: curlCommand));
                        PilotToast.show(context, 'Copied to clipboard');
                      },
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
        if (bodyPayload.trim().startsWith('{') ||
            bodyPayload.trim().startsWith('[')) {
          bodyPayload = jsonDecode(bodyPayload);
        }
      } catch (_) {}

      final data = {
        'url': _urlCtrl.text,
        'httpMethod': _method,
        'body': bodyPayload,
        'httpHeaders': _headers,
        'httpParameters': _params,
        'variables': _variables,
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
          EndpointEditorHeader(
            method: _method,
            urlController: _urlCtrl,
            onMethodChanged: (v) {
              setState(() => _method = v!);
              _queueSync();
            },
            onUrlChanged: _handleUrlChanged,
            onExportCurl: _showExportCurlDialog,
            onSave: _save,
          ),

          Expanded(
            child: LayoutBuilder(
              builder: (ctx, constraints) {
                return Column(
                  children: [
                    Expanded(
                      child: EndpointEditorTabs(
                        tabController: _reqTabCtrl,
                        params: _params,
                        headers: _headers,
                        body: _bodyCtrl.text,
                        successConditionController: _successConditionCtrl,
                        variables: _variables,
                        onParamsChanged: (d) {
                          _params.addAll(d);
                          _queueSync();
                        },
                        onHeadersChanged: (d) {
                          _headers.addAll(d);
                          _queueSync();
                        },
                        onBodyChanged: (v) {
                          _bodyCtrl.text = v;
                          _queueSync();
                        },
                        onVariablesChanged: (d) {
                          _variables = d;
                          _queueSync();
                        },
                        paramsScrollCtrl: _paramsScrollCtrl,
                        headersScrollCtrl: _headersScrollCtrl,
                        bodyScrollCtrl: _bodyScrollCtrl,
                        settingsScrollCtrl: _settingsScrollCtrl,
                      ),
                    ),

                    if (endpointProvider.isResponsePanelVisible)
                      EndpointEditorResponsePanel(
                        response: _response,
                        showRaw: _showRaw,
                        isExecuting: endpointProvider.isEndpointExecuting(widget.endpoint.id),
                        elapsedMsNotifier: _elapsedMsNotifier,
                        statusCode: _statusCode,
                        responseTime: _responseTime,
                        isSuccess: _isSuccess,
                        onToggleRaw: () => setState(() => _showRaw = !_showRaw),
                        onClose: () => endpointProvider.setResponsePanelVisible(false),
                        heightNotifier: _responsePanelHeight,
                        maxHeight: constraints.maxHeight - 100.0,
                        showSearch: _showSearch,
                        searchController: _searchCtrl,
                        searchFocusNode: _searchFocusNode,
                        currentSearchMatchIndex: _currentSearchMatchIndex,
                        totalMatchesCount: _totalMatchesCount,
                        onSearchChanged: (v) => setState(() => _currentSearchMatchIndex = 0),
                        onSearchNext: () {
                          if (_totalMatchesCount > 0) {
                            setState(() => _currentSearchMatchIndex = (_currentSearchMatchIndex + 1) % _totalMatchesCount);
                          }
                        },
                        onSearchPrev: () {
                          if (_totalMatchesCount > 0) {
                            setState(() => _currentSearchMatchIndex = (_currentSearchMatchIndex - 1 + _totalMatchesCount) % _totalMatchesCount);
                          }
                        },
                        onCloseSearch: () => setState(() {
                          _showSearch = false;
                          _searchCtrl.clear();
                          _totalMatchesCount = 0;
                          _currentSearchMatchIndex = 0;
                        }),
                        onMatchesCountChanged: (count) {
                          if (_totalMatchesCount != count) {
                            setState(() => _totalMatchesCount = count);
                          }
                        },
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
