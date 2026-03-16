import 'dart:convert';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stress_pilot/core/navigation/app_router.dart';

import 'package:stress_pilot/features/common/presentation/app_topbar.dart';
import '../domain/endpoint.dart';
import '../presentation/provider/endpoint_provider.dart';
import 'package:stress_pilot/features/environments/presentation/widgets/environment_dialog.dart';
import 'package:stress_pilot/features/endpoints/presentation/widgets/endpoint_type_badge.dart';
import 'package:stress_pilot/features/common/presentation/widgets/json_viewer.dart';
import 'package:stress_pilot/features/projects/domain/project.dart';

import '../widgets/key_value_editor.dart';
import 'create_endpoint_dialog.dart';
import 'package:stress_pilot/core/design/tokens.dart';

class ProjectEndpointsPage extends StatefulWidget {
  final Project project;

  const ProjectEndpointsPage({super.key, required this.project});

  @override
  State<ProjectEndpointsPage> createState() => _ProjectEndpointsPageState();
}

class _ProjectEndpointsPageState extends State<ProjectEndpointsPage> {
  Endpoint? _selectedEndpoint;
  late ScrollController _scrollCtrl;

  @override
  void initState() {
    super.initState();
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

    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

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
                border: Border.all(color: border.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    offset: const Offset(0, 4),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: AppRadius.br16,
                child: Row(
                  children: [
                    // ── Sidebar ──
                    Container(
                      width: 300,
                      decoration: BoxDecoration(
                        color: surface,
                        border: Border(
                          right: BorderSide(
                            color: border.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Header
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                            child: Row(
                              children: [
                                Material(
                                  color: colors.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(8),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(8),
                                    onTap: () => Navigator.of(context).pop(),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Icon(LucideIcons.arrowLeft, size: 16, color: colors.onSurfaceVariant),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    widget.project.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: colors.onSurface,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Material(
                                  color: colors.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(8),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(8),
                                    onTap: () => EnvironmentManagerDialog.show(
                                      context,
                                      widget.project.environmentId,
                                      widget.project.name,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Icon(LucideIcons.layers, size: 16, color: colors.primary),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Search bar
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: SizedBox(
                              height: 40,
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: 'Search endpoints...',
                                  hintStyle: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
                                  prefixIcon: Icon(LucideIcons.search, size: 16, color: colors.onSurfaceVariant),
                                  filled: true,
                                  fillColor: isDark ? colors.surfaceContainerHighest : const Color(0xFFF0F0F5),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                  isDense: true,
                                ),
                                style: const TextStyle(fontSize: 13),
                                onChanged: (value) {},
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // List header
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 16, 8),
                            child: Row(
                              children: [
                                Text(
                                  'ENDPOINTS',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.8,
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                                const Spacer(),
                                Material(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(6),
                                    onTap: _createNewEndpoint,
                                    child: Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: Icon(LucideIcons.plus, size: 16, color: colors.onSurfaceVariant),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Endpoint list
                          Expanded(
                            child: provider.isLoading
                                ? Center(
                                    child: SizedBox(
                                      width: 20, height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: colors.primary),
                                    ),
                                  )
                                : RefreshIndicator(
                                    onRefresh: () => provider.refreshEndpoints(projectId: widget.project.id),
                                    child: ListView.builder(
                                      controller: _scrollCtrl,
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
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
                                                      child: CircularProgressIndicator(strokeWidth: 2, color: colors.primary),
                                                    )
                                                  : const SizedBox.shrink(),
                                            ),
                                          );
                                        }

                                        final ep = provider.endpoints[index];
                                        final isSelected = _selectedEndpoint?.id == ep.id;

                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 2),
                                          child: Material(
                                            color: isSelected
                                                ? (isDark ? colors.primary.withValues(alpha: 0.15) : colors.primary.withValues(alpha: 0.08))
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(10),
                                            child: InkWell(
                                              onTap: () => setState(() => _selectedEndpoint = ep),
                                              borderRadius: BorderRadius.circular(10),
                                              hoverColor: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                                decoration: isSelected ? BoxDecoration(
                                                  borderRadius: BorderRadius.circular(10),
                                                  border: Border.all(color: colors.primary.withValues(alpha: 0.3), width: 1),
                                                ) : null,
                                                child: Row(
                                                  children: [
                                                    EndpointTypeBadge(type: ep.type, compact: true, inverse: false),
                                                    const SizedBox(width: 10),
                                                    Expanded(
                                                      child: Text(
                                                        ep.name,
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                                          color: isSelected ? colors.primary : colors.onSurface,
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
                                        );
                                      },
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),

                    Expanded(
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
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              shape: BoxShape.circle,
              border: Border.all(color: Theme.of(context).colorScheme.outline),
            ),
            child: Icon(
              LucideIcons.box,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Endpoint Selected',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select an endpoint from the sidebar\nor create a new one to get started.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => _showCreateDialog(context),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Create Endpoint'),
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

  bool? _isSuccess;

  late TabController _reqTabCtrl;
  late TabController _resTabCtrl;

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
    _resTabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _nameCtrl.dispose();
    _bodyCtrl.dispose();
    _successConditionCtrl.dispose();
    _reqTabCtrl.dispose();
    _resTabCtrl.dispose();
    super.dispose();
  }

  void _handleUrlChanged(String value) {
    if (value.trim().toLowerCase().startsWith('curl ')) {
      _parseCurlCommand(value);
    }
  }

  void _parseCurlCommand(String curlCommand) {
    String method = 'GET';
    String url = '';
    Map<String, String> headers = {};
    String body = '';

    final urlMatch = RegExp(r'''['"]?(https?://[^'"\s]+)['"]?''').firstMatch(curlCommand);
    if (urlMatch != null) {
      url = urlMatch.group(1)!;
    }

    final methodMatch = RegExp(r'''-X\s+(['"]?)([A-Z]+)\1''').firstMatch(curlCommand);
    if (methodMatch != null) {
      method = methodMatch.group(2)!;
    } else if (curlCommand.contains('-d') || curlCommand.contains('--data')) {
      method = 'POST';
    }

    final headerRegExp = RegExp(r'''(?:-H|--header)\s+['"]([^:]+):\s*(.*?)['"]''');
    for (final match in headerRegExp.allMatches(curlCommand)) {
      headers[match.group(1)!.trim()] = match.group(2)!.trim();
    }

    final dataRegExp = RegExp(r'''(?:-d|--data(?:-raw|-binary)?)\s+('([^']*)'|"([^"]*)")''');
    final dataMatch = dataRegExp.firstMatch(curlCommand);
    if (dataMatch != null) {
      body = dataMatch.group(2) ?? dataMatch.group(3) ?? '';
    }

    setState(() {
      _urlCtrl.text = url;
      _method = method;
      _headers = {...headers};
      _bodyCtrl.text = body;
    });
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
      widget.onUpdated(updated);
      AppNavigator.scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Saved')),
      );
    } catch (e) {
      AppNavigator.scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _send() async {
    setState(() {
      _isLoading = true;
      _response = null;
      _statusCode = null;
      _isSuccess = null;
    });

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
      setState(() {
        _response = {'error': e.toString()};
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? colors.surface : const Color(0xFFF5F5F7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ──
          Container(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? colors.outlineVariant : const Color(0xFFE8E8ED),
                ),
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
                      hintStyle: TextStyle(color: colors.onSurfaceVariant),
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: colors.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(LucideIcons.save, size: 16),
                  label: const Text('Save'),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: isDark ? colors.surfaceContainerHighest : const Color(0xFFF0F0F5),
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: widget.onDeleted,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Icon(LucideIcons.trash2, size: 18, color: colors.error),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Request Panel ──
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isDark ? colors.outlineVariant : const Color(0xFFE8E8ED)),
                      boxShadow: isDark ? [] : [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Column(
                    children: [
                      // URL bar
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: isDark ? colors.surfaceContainerHighest : const Color(0xFFF5F5F7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isDark ? colors.outlineVariant : const Color(0xFFE0E0E5)),
                          ),
                          child: Row(
                            children: [
                              // Method selector
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                decoration: BoxDecoration(
                                  border: Border(right: BorderSide(color: isDark ? colors.outlineVariant : const Color(0xFFE0E0E5))),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _method,
                                    dropdownColor: colors.surface,
                                    icon: Icon(LucideIcons.chevronDown, size: 12, color: colors.onSurfaceVariant),
                                    items: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'].map((m) {
                                      final methodColor = {
                                        'GET': const Color(0xFF10B981),
                                        'POST': const Color(0xFF3B82F6),
                                        'PUT': const Color(0xFFF59E0B),
                                        'DELETE': const Color(0xFFEF4444),
                                        'PATCH': const Color(0xFF8B5CF6),
                                      }[m] ?? colors.primary;
                                      return DropdownMenuItem(value: m, child: Text(m, style: TextStyle(color: methodColor, fontSize: 13, fontWeight: FontWeight.w700)));
                                    }).toList(),
                                    onChanged: (v) => setState(() => _method = v!),
                                  ),
                                ),
                              ),
                              // URL input
                              Expanded(
                                child: TextField(
                                  controller: _urlCtrl,
                                  decoration: InputDecoration(
                                    hintText: 'https://api.example.com/v1/resource',
                                    hintStyle: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                                    isDense: true,
                                  ),
                                  style: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 13, color: colors.onSurface),
                                  textAlignVertical: TextAlignVertical.center,
                                  onChanged: _handleUrlChanged,
                                ),
                              ),
                              // Send button
                              Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: SizedBox(
                                  height: 36,
                                  child: FilledButton.icon(
                                    onPressed: _isLoading ? null : _send,
                                    icon: _isLoading
                                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                        : const Icon(LucideIcons.play, size: 14),
                                    label: const Text('Send'),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: colors.primary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(horizontal: 18),
                                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SizedBox(
                          height: 32,
                          child: _SegmentedTabControl(
                            controller: _reqTabCtrl,
                            tabs: const [
                              'Params',
                              'Headers',
                              'Body',
                              'Configuration',
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: Theme.of(context).dividerTheme.color!,
                              ),
                            ),
                          ),
                          child: TabBarView(
                            controller: _reqTabCtrl,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: KeyValueEditor(
                                  data: _params,
                                  onChanged: (d) => _params = d,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: KeyValueEditor(
                                  data: _headers,
                                  onChanged: (d) => _headers = d,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(1),
                                child: TextField(
                                  controller: _bodyCtrl,
                                  maxLines: null,
                                  expands: true,
                                  style: TextStyle(
                                    fontFamily: 'JetBrains Mono',
                                    fontSize: 13,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Request Body (JSON)',
                                    hintStyle: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.all(16),
                                  ),
                                ),
                              ),
                              ListView(
                                padding: const EdgeInsets.all(16),
                                children: [
                                  Text(
                                    'Success Condition (SpEL)',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _successConditionCtrl,
                                    decoration: const InputDecoration(
                                      hintText:
                                          'e.g., #statusCode == 200 && #body.status == "OK"',
                                      border: OutlineInputBorder(),
                                      helperText:
                                          'Available variables: #statusCode, #body, #headers, #responseTime',
                                    ),
                                    minLines: 1,
                                    maxLines: 3,
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    'Variables',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    constraints: const BoxConstraints(
                                      minHeight: 100,
                                      maxHeight: 300,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Theme.of(
                                          context,
                                        ).dividerTheme.color!,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: KeyValueEditor(
                                      data: _variables,
                                      onChanged: (d) => _variables = d,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  ),
                ),
                const SizedBox(height: 16),
                // ── Response Panel ──
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isDark ? colors.outlineVariant : const Color(0xFFE8E8ED)),
                      boxShadow: isDark ? [] : [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                          border: Border(
                            bottom: BorderSide(color: isDark ? colors.outlineVariant : const Color(0xFFE8E8ED)),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Response',
                              style: TextStyle(
                                color: colors.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const Spacer(),
                            if (_statusCode != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (_isSuccess == true)
                                      ? const Color(0xFF10B981).withValues(alpha: 0.12)
                                      : const Color(0xFFEF4444).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _isSuccess == true
                                      ? 'SUCCESS (${_statusCode ?? '-'})'
                                      : 'FAILED (${_statusCode ?? '-'})',
                                  style: TextStyle(
                                    color: (_isSuccess == true)
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFEF4444),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '${_responseTime}ms',
                                style: TextStyle(
                                  color: colors.onSurfaceVariant,
                                  fontSize: 12,
                                  fontFamily: 'JetBrains Mono',
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Expanded(
                        child: _response == null
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(LucideIcons.send, size: 32, color: colors.onSurfaceVariant.withValues(alpha: 0.4)),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Hit Send to execute the request',
                                      style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
                                    ),
                                  ],
                                ),
                              )
                            : SingleChildScrollView(
                                padding: const EdgeInsets.all(16),
                                child: JsonViewer(
                                  json: () {
                                    final r = Map<String, dynamic>.from(
                                      _response!,
                                    );
                                    final filtered = <String, dynamic>{};
                                    if (r.containsKey('message')) {
                                      filtered['message'] = r['message'];
                                    }
                                    if (r.containsKey('data')) {
                                      filtered['data'] = r['data'];
                                    } else if (r.containsKey('body')) {
                                      filtered['data'] = r['body'];
                                    } else {
                                      if (r.containsKey('error')) {
                                        filtered['error'] = r['error'];
                                      }
                                    }
                                    if (filtered.isEmpty) {
                                      final metadataKeys = [
                                        'statusCode',
                                        'success',
                                        'responseTimeMs',
                                        'timestamp',
                                        'headers',
                                      ];
                                      r.removeWhere(
                                        (k, v) => metadataKeys.contains(k),
                                      );
                                      return r;
                                    }
                                    return filtered;
                                  }(),
                                ),
                              ),
                      ),
                    ],
                  ),
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
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: List.generate(widget.tabs.length, (index) {
          final isSelected = widget.controller.index == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => widget.controller.animateTo(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).cardTheme.color
                      : Colors.transparent,
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
                ),
                alignment: Alignment.center,
                child: Text(
                  widget.tabs[index],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: isSelected
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(context).colorScheme.onSurfaceVariant,
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
