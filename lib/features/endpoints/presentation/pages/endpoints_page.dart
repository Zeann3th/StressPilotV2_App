import 'dart:convert';
import 'dart:async' as async_timer;
import 'package:flutter/services.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:stress_pilot/core/navigation/navigation_tracker.dart';
import 'package:stress_pilot/features/shared/presentation/widgets/app_topbar.dart';
import 'package:stress_pilot/features/endpoints/domain/models/endpoint.dart';
import 'package:stress_pilot/features/endpoints//data/curl_parser.dart';
import 'package:stress_pilot/features/endpoints/presentation/provider/endpoint_provider.dart';
import 'package:stress_pilot/features/environments/presentation/widgets/environment_dialog.dart';
import 'package:stress_pilot/features/endpoints/presentation/widgets/endpoint_type_badge.dart';
import 'package:stress_pilot/features/shared/presentation/widgets/json_viewer.dart';
import 'package:stress_pilot/features/projects/domain/models/project.dart';

import '../widgets/key_value_editor.dart';
import '../widgets/create_endpoint_dialog.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/core/themes/components/components.dart';

class ProjectEndpointsPage extends StatefulWidget {
  final Project project;
  final Endpoint? initialEndpoint;

  const ProjectEndpointsPage({
    super.key,
    required this.project,
    this.initialEndpoint,
  });

  @override
  State<ProjectEndpointsPage> createState() => _ProjectEndpointsPageState();
}

class _ProjectEndpointsPageState extends State<ProjectEndpointsPage> {
  Endpoint? _selectedEndpoint;
  late ScrollController _scrollCtrl;

  final GlobalKey _sidebarKey = GlobalKey();
  final GlobalKey _workspaceKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _selectedEndpoint = widget.initialEndpoint;
    _scrollCtrl = ScrollController();
    _scrollCtrl.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EndpointProvider>().loadEndpoints(
        projectId: widget.project.id,
      );
    });
  }

  void _onScroll() {
    final provider = context.read<EndpointProvider>();
    if (!provider.hasMore || provider.isLoadingMore) return;

    if (_scrollCtrl.position.maxScrollExtent - _scrollCtrl.position.pixels <
        200) {
      provider.loadMoreEndpoints(projectId: widget.project.id);
    }
  }

  void _createNewEndpoint() {
    setState(() {
      _selectedEndpoint = null;
    });
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EndpointProvider>();

    final bg = AppColors.background;
    final surface = AppColors.surface;
    final border = AppColors.border;
    final textColor = AppColors.textPrimary;
    final secondaryText = AppColors.textSecondary;

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          const AppTopBar(),
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: AppRadius.br16,
                border: Border.all(color: border.withValues(alpha: 0.5)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    offset: const Offset(0, 4),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: AppRadius.br16,
                child: Row(
                  children: [

                    Container(
                      key: _sidebarKey,
                      width: 300,
                      decoration: BoxDecoration(
                        color: surface,
                        border: Border(
                          right: BorderSide(
                            color: border.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                            child: Row(
                              children: [
                                PilotButton.ghost(
                                  icon: LucideIcons.arrowLeft,
                                  compact: true,
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    widget.project.name,
                                    style: AppTypography.heading.copyWith(color: textColor, fontSize: 15),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                PilotButton.ghost(
                                  icon: LucideIcons.layers,
                                  compact: true,
                                  onPressed: () => EnvironmentManagerDialog.show(
                                    context,
                                    widget.project.environmentId,
                                    widget.project.name,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: SizedBox(
                              height: 36,
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: 'Search endpoints...',
                                  hintStyle: TextStyle(fontSize: 12, color: secondaryText),
                                  prefixIcon: Icon(LucideIcons.search, size: 14, color: secondaryText),
                                  filled: true,
                                  fillColor: AppColors.elevated,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: EdgeInsets.zero,
                                  isDense: true,
                                ),
                                style: TextStyle(fontSize: 12, color: textColor),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 16, 8),
                            child: Row(
                              children: [
                                Text(
                                  'ENDPOINTS',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                    color: secondaryText,
                                  ),
                                ),
                                const Spacer(),
                                PilotButton.ghost(
                                  icon: LucideIcons.plus,
                                  compact: true,
                                  onPressed: _createNewEndpoint,
                                ),
                              ],
                            ),
                          ),

                          Expanded(
                            child: provider.isLoading
                                ? Center(
                                    child: SizedBox(
                                      width: 20, height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.accent,
                                      ),
                                    ),
                                  )
                                : RefreshIndicator(
                                    onRefresh: () => provider.refreshEndpoints(projectId: widget.project.id),
                                    child: ListView.builder(
                                      controller: _scrollCtrl,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      physics: const AlwaysScrollableScrollPhysics(),
                                      itemCount: provider.endpoints.length + (provider.hasMore ? 1 : 0),
                                      itemBuilder: (context, index) {
                                        if (index >= provider.endpoints.length) {
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            child: Center(
                                              child: provider.isLoadingMore
                                                  ? SizedBox(
                                                      width: 16, height: 16,
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: AppColors.accent,
                                                      ),
                                                    )
                                                  : const SizedBox.shrink(),
                                            ),
                                          );
                                        }

                                        final ep = provider.endpoints[index];
                                        final isSelected = _selectedEndpoint?.id == ep.id;

                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 4),
                                          child: PilotContextMenu(
                                            items: [
                                              PilotContextMenuItem(
                                                label: 'Clone',
                                                icon: LucideIcons.copy,
                                                onTap: () async {
                                                  final cloned = await provider.cloneEndpoint(ep);
                                                  if (!context.mounted) return;
                                                  setState(() => _selectedEndpoint = cloned);
                                                  PilotToast.show(context, 'Endpoint cloned');
                                                },
                                              ),
                                              PilotContextMenuItem.divider(),
                                              PilotContextMenuItem(
                                                label: 'Delete',
                                                icon: LucideIcons.trash2,
                                                onTap: () async {
                                                  await provider.deleteEndpoint(ep.id, widget.project.id);
                                                  if (!context.mounted) return;
                                                  if (_selectedEndpoint?.id == ep.id) {
                                                    setState(() => _selectedEndpoint = null);
                                                  }
                                                  PilotToast.show(context, 'Endpoint deleted');
                                                },
                                              ),
                                            ],
                                            child: AnimatedContainer(
                                              duration: AppDurations.short,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(10),
                                                gradient: isSelected ? AppGradients.green(Theme.of(context).brightness == Brightness.dark) : null,
                                              ),
                                              child: Material(
                                                color: Colors.transparent,
                                                borderRadius: BorderRadius.circular(10),
                                                child: InkWell(
                                                  onTap: () {
                                                    setState(() => _selectedEndpoint = ep);
                                                    NavigationTracker.trackEndpoint(
                                                      ep.name,
                                                      ep.url ?? ep.grpcServiceName ?? ep.graphqlOperationType,
                                                      ep.type,
                                                      {
                                                        'project': widget.project.toJson(),
                                                        'initialEndpoint': ep.toJson(),
                                                      },
                                                    );
                                                  },
                                                  borderRadius: BorderRadius.circular(10),
                                                  child: Padding(
                                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                                    child: Row(
                                                      children: [
                                                        EndpointTypeBadge(type: ep.type, compact: true, inverse: isSelected),
                                                        const SizedBox(width: 10),
                                                        Expanded(
                                                          child: Text(
                                                            ep.name,
                                                            style: TextStyle(
                                                              fontSize: 13,
                                                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                                              color: isSelected ? Colors.white : textColor,
                                                            ),
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      key: _workspaceKey,
                      child: _selectedEndpoint == null
                          ? _EmptyState(
                              projectId: widget.project.id,
                              onCreated: (ep) => setState(() => _selectedEndpoint = ep),
                            )
                          : _EndpointWorkspace(
                              key: ValueKey(_selectedEndpoint!.id),
                              endpoint: _selectedEndpoint!,
                              projectId: widget.project.id,
                              onDeleted: () async {
                                await context.read<EndpointProvider>().deleteEndpoint(
                                      _selectedEndpoint!.id,
                                      widget.project.id,
                                    );
                                setState(() => _selectedEndpoint = null);
                              },
                              onUpdated: (updated) =>
                                  setState(() => _selectedEndpoint = updated),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
    final secondaryText = AppColors.textSecondary;
    final textColor = AppColors.textPrimary;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
            ),
            child: Icon(
              LucideIcons.box,
              size: 48,
              color: secondaryText.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Endpoint Selected',
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select an endpoint from the sidebar\nor create a new one to get started.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: secondaryText,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 24),
          PilotButton.primary(
            label: 'Create Endpoint',
            icon: LucideIcons.plus,
            onPressed: () => _showCreateDialog(context),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context) async {
    final endpointProvider = context.read<EndpointProvider>();
    final result = await showDialog(
      context: context,
      builder: (ctx) => ChangeNotifierProvider.value(
        value: endpointProvider,
        child: CreateEndpointDialog(projectId: projectId),
      ),
    );

    if (result != null && result is Endpoint) {
      onCreated(result);
    }
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

  late TextEditingController _bodyCtrl;
  late TextEditingController _successConditionCtrl;
  Map<String, String> _headers = {};
  Map<String, String> _params = {};
  Map<String, String> _variables = {};

  Map<String, dynamic>? _response;
  bool _isLoading = false;
  int? _statusCode;
  int? _responseTime;
  int _elapsedMs = 0;
  async_timer.Timer? _executionTimer;
  async_timer.Timer? _debounce;

  bool? _isSuccess;
  bool _showRaw = false;
  double _responsePanelHeight = 260.0;

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
        bodyText = const JsonEncoder.withIndent(
          '  ',
        ).convert(widget.endpoint.body);
      }
    }
    _bodyCtrl = TextEditingController(text: bodyText);
    _successConditionCtrl = TextEditingController(
      text: widget.endpoint.successCondition ?? '',
    );

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

    _reqTabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _executionTimer?.cancel();
    _debounce?.cancel();
    _urlCtrl.dispose();
    _nameCtrl.dispose();
    _bodyCtrl.dispose();
    _successConditionCtrl.dispose();
    _reqTabCtrl.dispose();
    super.dispose();
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

  void _handleUrlChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = async_timer.Timer(const Duration(milliseconds: 300), () {
      if (value.trim().toLowerCase().startsWith('curl ')) {
        _parseCurlCommand(value);
      }
    });
  }

  void _parseCurlCommand(String curlCommand) {
    final data = CurlParser.parse(curlCommand);

    setState(() {
      if (data.url != null && data.url!.isNotEmpty) _urlCtrl.text = data.url!;
      if (data.method != null) _method = data.method!;
      if (data.headers != null) _headers = {...data.headers!};
      if (data.body != null && data.body!.isNotEmpty) _bodyCtrl.text = data.body!;
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid JSON')),
        );
      }
    }
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
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
                  child: SelectableText(
                    curlCommand,
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 13,
                      color: AppColors.textPrimary,
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
                          child: Icon(
                            LucideIcons.copy,
                            size: 18,
                            color: AppColors.textPrimary.withValues(alpha: 0.5),
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
        if (bodyPayload.trim().startsWith('{') ||
            bodyPayload.trim().startsWith('[')) {
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
        'projectId': widget.projectId,
      };

      final updated = await context.read<EndpointProvider>().updateEndpoint(
        widget.endpoint.id,
        data,
      );
      if (!mounted) return;
      widget.onUpdated(updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _send() async {
    setState(() {
      _isLoading = true;
      _response = null;
      _statusCode = null;
      _responseTime = null;
      _isSuccess = null;
    });

    _startTimer();

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
            'body': bodyPayload,
            'httpHeaders': _headers,
            'httpParameters': _params,
            'variables': _variables,
            'successCondition': _successConditionCtrl.text,
          });

      if (!mounted) return;
      _stopTimer();

      setState(() {
        _response = result;

        final responseData = result.containsKey('data') && result['data'] is Map
            ? result['data'] as Map<String, dynamic>
            : result;

        _statusCode = responseData['statusCode'];
        _responseTime = responseData['responseTimeMs'];
        if (responseData.containsKey('success')) {
          _isSuccess = responseData['success'] as bool?;
        }
      });
    } catch (e) {
      _stopTimer();
      if (!mounted) return;
      setState(() {
        _response = {'error': e.toString()};
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = AppColors.background;
    final surface = AppColors.surface;
    final border = AppColors.border;
    final textColor = AppColors.textPrimary;
    final secondaryText = AppColors.textSecondary;
    final accentColor = AppColors.accent;

    return Container(
      color: bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

          Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            decoration: BoxDecoration(
              color: surface,
              border: Border(
                bottom: BorderSide(color: border.withValues(alpha: 0.5)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameCtrl,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Endpoint Name',
                      hintStyle: TextStyle(color: secondaryText),
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                    style: AppTypography.heading.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                PilotButton.ghost(
                  icon: LucideIcons.code,
                  onPressed: _showExportCurlDialog,
                  compact: true,
                ),
                const SizedBox(width: 8),
                PilotButton.danger(
                  icon: LucideIcons.trash2,
                  onPressed: widget.onDeleted,
                  compact: true,
                ),
                const SizedBox(width: 8),
                PilotButton.primary(
                  label: 'Save',
                  icon: LucideIcons.save,
                  onPressed: _save,
                  compact: true,
                ),
              ],
            ),
          ),

          Expanded(
            child: Column(
              children: [

                Container(
                  padding: const EdgeInsets.all(16),
                  color: surface,
                  child: Row(
                    children: [
                      Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.elevated,
                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                          border: Border.all(color: border.withValues(alpha: 0.5)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _method,
                            dropdownColor: surface,
                            icon: Icon(LucideIcons.chevronDown, size: 12, color: secondaryText),
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
                            onChanged: (v) => setState(() => _method = v!),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.elevated,
                            border: Border(
                              top: BorderSide(color: border.withValues(alpha: 0.5)),
                              bottom: BorderSide(color: border.withValues(alpha: 0.5)),
                            ),
                          ),
                          child: TextField(
                            controller: _urlCtrl,
                            decoration: InputDecoration(
                              hintText: 'https://api.example.com/v1/resource',
                              hintStyle: TextStyle(color: secondaryText.withValues(alpha: 0.5), fontSize: 13),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                              isDense: true,
                            ),
                            style: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 13, color: textColor),
                            textAlignVertical: TextAlignVertical.center,
                            onChanged: _handleUrlChanged,
                          ),
                        ),
                      ),
                      PilotButton.primary(
                        label: 'Send',
                        icon: LucideIcons.send,
                        onPressed: _isLoading ? null : _send,
                        compact: false,
                      ),
                    ],
                  ),
                ),

                Container(
                  height: 36,
                  color: surface,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _SegmentedTabControl(
                    controller: _reqTabCtrl,
                    tabs: const ['Params', 'Headers', 'Body', 'Settings'],
                  ),
                ),

                Expanded(
                  child: LayoutBuilder(
                    builder: (ctx, constraints) {
                      final totalH = constraints.maxHeight;
                      final respH = _responsePanelHeight.clamp(80.0, totalH - 80.0);
                      return Column(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border(top: BorderSide(color: border.withValues(alpha: 0.3))),
                              ),
                              child: TabBarView(
                                controller: _reqTabCtrl,
                                physics: const NeverScrollableScrollPhysics(),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: KeyValueEditor(data: _params, onChanged: (d) => _params = d),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: KeyValueEditor(data: _headers, onChanged: (d) => _headers = d),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(1),
                                    child: Stack(
                                      children: [
                                        TextField(
                                          controller: _bodyCtrl,
                                          maxLines: null,
                                          expands: true,
                                          style: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 13, color: textColor),
                                          decoration: InputDecoration(
                                            hintText: 'Request Body (JSON)',
                                            hintStyle: TextStyle(color: secondaryText),
                                            border: InputBorder.none,
                                            contentPadding: const EdgeInsets.all(16),
                                            fillColor: bg.withValues(alpha: 0.3),
                                            filled: true,
                                          ),
                                        ),
                                        Positioned(
                                          top: 8,
                                          right: 16,
                                          child: PilotButton.ghost(
                                            label: 'Beautify',
                                            icon: LucideIcons.sparkles,
                                            onPressed: _beautifyJson,
                                            compact: true,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  _buildSettingsTab(textColor, secondaryText, border),
                                ],
                              ),
                            ),
                          ),

                          MouseRegion(
                            cursor: SystemMouseCursors.resizeRow,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onVerticalDragUpdate: (d) {
                                setState(() {
                                  _responsePanelHeight = (_responsePanelHeight - d.delta.dy)
                                      .clamp(80.0, totalH - 80.0);
                                });
                              },
                              child: Container(
                                height: 8,
                                color: border.withValues(alpha: 0.4),
                                alignment: Alignment.center,
                                child: Container(
                                  width: 36,
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: secondaryText.withValues(alpha: 0.3),
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
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: surface,
                                      border: Border(bottom: BorderSide(color: border.withValues(alpha: 0.3))),
                                    ),
                                    child: Row(
                                      children: [
                                        _buildRespTab('Response', !_showRaw, secondaryText),
                                        const SizedBox(width: 4),
                                        _buildRespTab('Raw', _showRaw, secondaryText),
                                        const Spacer(),
                                        if (_isLoading)
                                          Text('${_elapsedMs}ms', style: TextStyle(color: accentColor, fontSize: 12, fontFamily: 'JetBrains Mono')),
                                        if (_statusCode != null && !_isLoading) ...[
                                          _buildStatusBadge(_isSuccess == true, _statusCode!),
                                          const SizedBox(width: 10),
                                          Text('${_responseTime}ms', style: TextStyle(color: secondaryText, fontSize: 12, fontFamily: 'JetBrains Mono')),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: _response == null
                                        ? _buildResponseEmptyState(secondaryText)
                                        : _showRaw
                                            ? SingleChildScrollView(
                                                padding: const EdgeInsets.all(16),
                                                child: SelectableText(
                                                  _getRawResponse(_response!),
                                                  style: TextStyle(
                                                    fontFamily: 'JetBrains Mono',
                                                    fontSize: 12,
                                                    color: textColor,
                                                  ),
                                                ),
                                              )
                                            : SingleChildScrollView(
                                                padding: const EdgeInsets.all(16),
                                                child: JsonViewer(json: _getResponseData(_response!)),
                                              ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab(Color textColor, Color secondaryText, Color border) {
    return ListView(
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
        Text('Variables', style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 13)),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(minHeight: 100, maxHeight: 300),
          decoration: BoxDecoration(
            border: Border.all(color: border.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: KeyValueEditor(data: _variables, onChanged: (d) => _variables = d),
        ),
      ],
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
          Text('Hit Send to execute the request', style: TextStyle(color: secondaryText, fontSize: 13)),
        ],
      ),
    );
  }

  Map<String, dynamic> _getResponseData(Map<String, dynamic> r) {
    if (r.containsKey('error')) return {'error': r['error']};
    final outerData = r['data'];
    if (outerData is Map<String, dynamic>) {
      final innerData = outerData['data'];
      if (innerData is Map<String, dynamic>) return innerData;

      final cleaned = Map<String, dynamic>.from(outerData);
      cleaned.removeWhere((k, _) => const {
        'statusCode', 'success', 'responseTimeMs', 'message', 'rawResponse'
      }.contains(k));
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

  Widget _buildRespTab(String label, bool active, Color secondaryText) {
    return GestureDetector(
      onTap: () => setState(() => _showRaw = label == 'Raw'),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active ? AppColors.accent.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: active ? AppColors.accent.withValues(alpha: 0.4) : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? AppColors.accent : secondaryText,
            fontSize: 12,
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _SegmentedTabControl extends StatefulWidget {
  final TabController controller;
  final List<String> tabs;

  const _SegmentedTabControl({required this.controller, required this.tabs});

  @override
  State<_SegmentedTabControl> createState() => _SegmentedTabControlState();
}

class _SegmentedTabControlState extends State<_SegmentedTabControl> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final surface = AppColors.surface;
    final elevated = AppColors.elevated;
    final textColor = AppColors.textPrimary;
    final secondaryText = AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: List.generate(widget.tabs.length, (index) {
          final isSelected = widget.controller.index == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => widget.controller.animateTo(index),
              child: AnimatedContainer(
                duration: AppDurations.short,
                curve: Curves.easeOut,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: isSelected ? surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                  border: isSelected
                    ? Border.all(color: AppColors.border.withValues(alpha: 0.5))
                    : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  widget.tabs[index],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? textColor : secondaryText,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
