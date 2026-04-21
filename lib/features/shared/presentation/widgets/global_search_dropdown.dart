import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:stress_pilot/core/navigation/app_router.dart';
import 'package:stress_pilot/core/network/http_client.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/features/endpoints/domain/models/endpoint.dart';
import 'package:stress_pilot/features/projects/data/repositories/project_repository_impl.dart';
import 'package:stress_pilot/features/projects/domain/models/flow.dart' as flow_domain;
import 'package:stress_pilot/features/projects/domain/models/project.dart';
import 'package:stress_pilot/features/projects/presentation/provider/flow_provider.dart';
import 'package:stress_pilot/features/projects/presentation/provider/project_provider.dart';
import 'package:stress_pilot/features/shared/presentation/widgets/navigation_item.dart';

class _SearchResults {
  final List<Project> projects;
  final List<flow_domain.Flow> flows;
  final List<Endpoint> endpoints;

  const _SearchResults({
    this.projects = const [],
    this.flows = const [],
    this.endpoints = const [],
  });

  bool get isEmpty => projects.isEmpty && flows.isEmpty && endpoints.isEmpty;
}

class GlobalSearchDropdown extends StatefulWidget {
  const GlobalSearchDropdown({super.key});

  @override
  State<GlobalSearchDropdown> createState() => _GlobalSearchDropdownState();
}

class _GlobalSearchDropdownState extends State<GlobalSearchDropdown> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  final Dio _dio = HttpClient.getInstance();

  OverlayEntry? _overlayEntry;
  Timer? _debounce;
  _SearchResults _results = const _SearchResults();
  bool _isLoading = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() => _isFocused = _focusNode.hasFocus);
    if (!_focusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 150), _removeOverlay);
    }
  }

  void _onChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _results = const _SearchResults();
        _isLoading = false;
      });
      _removeOverlay();
      return;
    }

    setState(() => _isLoading = true);
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(query.trim()));
  }

  Future<void> _search(String query) async {
    try {
      final responses = await Future.wait([
        _searchProjects(query),
        _searchFlows(query),
        _searchEndpoints(query),
      ]);

      if (!mounted) return;
      setState(() {
        _results = _SearchResults(
          projects: responses[0] as List<Project>,
          flows: responses[1] as List<flow_domain.Flow>,
          endpoints: responses[2] as List<Endpoint>,
        );
        _isLoading = false;
      });

      _updateOverlay();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _updateOverlay();
    }
  }

  Future<List<Project>> _searchProjects(String query) async {
    try {
      final response = await _dio.get(
        '/api/v1/projects',
        queryParameters: {'name': query, 'page': 0, 'size': 5},
      );
      final content = response.data['data']['content'] as List? ?? [];
      return content.map((e) => Project.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<flow_domain.Flow>> _searchFlows(String query) async {
    try {
      final response = await _dio.get(
        '/api/v1/flows',
        queryParameters: {'name': query, 'page': 0, 'size': 5},
      );
      final content = response.data['data']['content'] as List? ?? [];
      return content.map((e) => flow_domain.Flow.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Endpoint>> _searchEndpoints(String query) async {
    try {
      final response = await _dio.get(
        '/api/v1/endpoints',
        queryParameters: {'name': query, 'page': 0, 'size': 5},
      );
      final content = response.data['data']['content'] as List? ?? [];
      return content.map((e) => Endpoint.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  void _showOverlay() {
    _removeOverlay();
    if (!mounted) return;

    _overlayEntry = OverlayEntry(builder: (_) => _buildDropdown());
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _updateOverlay() {
    if (_overlayEntry == null) {
      _showOverlay();
    } else {
      _overlayEntry!.markNeedsBuild();
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _buildDropdown() {
    return Positioned(
      width: 420,
      child: CompositedTransformFollower(
        link: _layerLink,
        showWhenUnlinked: false,
        offset: const Offset(-35, 44),
        child: Material(
          color: Colors.transparent,
          child: _SearchDropdownPanel(
            results: _results,
            isLoading: _isLoading,
            onProjectTap: _navigateToProject,
            onFlowTap: _navigateToFlow,
            onEndpointTap: _navigateToEndpoint,
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToProject(Project project) async {
    _removeOverlay();
    _controller.clear();
    _focusNode.unfocus();

    await context.read<ProjectProvider>().selectProject(project);
    AppNavigator.pushReplacementNamed(AppRouter.workspaceRoute);
  }

  Future<void> _navigateToFlow(flow_domain.Flow flow) async {
    _removeOverlay();
    _controller.clear();
    _focusNode.unfocus();

    final projectProvider = context.read<ProjectProvider>();
    final flowProvider = context.read<FlowProvider>();

    try {
      final project = await ProjectRepositoryImpl().getProjectDetail(flow.projectId);
      if (!mounted) return;
      await projectProvider.selectProject(project);
      await flowProvider.selectFlow(flow);
      AppNavigator.pushReplacementNamed(AppRouter.workspaceRoute);
    } catch (_) {}
  }

  Future<void> _navigateToEndpoint(Endpoint endpoint) async {
    _removeOverlay();
    _controller.clear();
    _focusNode.unfocus();

    final projectProvider = context.read<ProjectProvider>();

    try {
      final project = await ProjectRepositoryImpl().getProjectDetail(endpoint.projectId);
      if (!mounted) return;
      await projectProvider.selectProject(project);
      AppNavigator.pushNamed(
        AppRouter.projectEndpointsRoute,
        arguments: {
          'project': project,
          'initialEndpoint': endpoint,
        },
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = AppColors.elevated;
    final borderColor = _isFocused ? AppColors.accent : AppColors.border;

    return CompositedTransformTarget(
      link: _layerLink,
      child: AnimatedContainer(
        duration: AppDurations.short,
        height: 36,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: AppRadius.br8,
          border: Border.all(
            color: borderColor,
            width: _isFocused ? 2 : 1,
          ),
          boxShadow: _isFocused
              ? [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.2),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            const SizedBox(width: 10),
            Icon(Icons.search_rounded, size: 16, color: AppColors.textMuted),
            const SizedBox(width: 6),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                onChanged: _onChanged,
                style: AppTypography.body.copyWith(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search projects, flows, endpoints...',
                  hintStyle: AppTypography.body.copyWith(color: AppColors.textMuted),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  suffixIcon: _isLoading
                      ? Padding(
                          padding: const EdgeInsets.all(10),
                          child: SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: AppColors.accent,
                            ),
                          ),
                        )
                      : null,
                ),
                cursorColor: AppColors.accent,
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

class _SearchDropdownPanel extends StatelessWidget {
  final _SearchResults results;
  final bool isLoading;
  final ValueChanged<Project> onProjectTap;
  final ValueChanged<flow_domain.Flow> onFlowTap;
  final ValueChanged<Endpoint> onEndpointTap;

  const _SearchDropdownPanel({
    required this.results,
    required this.isLoading,
    required this.onProjectTap,
    required this.onFlowTap,
    required this.onEndpointTap,
  });

  @override
  Widget build(BuildContext context) {
    final surface = AppColors.surface;
    final border = AppColors.border;

    final sections = <Widget>[];

    if (results.projects.isNotEmpty) {
      sections.add(_SectionLabel(label: 'Projects', icon: LucideIcons.folder));
      for (final project in results.projects) {
        sections.add(NavigationItem(
          title: project.name,
          subtitle: project.description.isNotEmpty ? project.description : null,
          icon: LucideIcons.folder,
          onTap: () => onProjectTap(project),
        ));
      }
    }

    if (results.flows.isNotEmpty) {
      if (sections.isNotEmpty) sections.add(_Divider());
      sections.add(_SectionLabel(label: 'Flows', icon: LucideIcons.gitBranch));
      for (final flow in results.flows) {
        sections.add(NavigationItem(
          title: flow.name,
          subtitle: flow.description,
          icon: LucideIcons.gitBranch,
          onTap: () => onFlowTap(flow),
        ));
      }
    }

    if (results.endpoints.isNotEmpty) {
      if (sections.isNotEmpty) sections.add(_Divider());
      sections.add(_SectionLabel(label: 'Endpoints', icon: LucideIcons.zap));
      for (final endpoint in results.endpoints) {
        sections.add(NavigationItem(
          title: endpoint.name,
          subtitle: endpoint.url ?? endpoint.grpcServiceName ?? endpoint.graphqlOperationType,
          badge: endpoint.type,
          icon: LucideIcons.zap,
          onTap: () => onEndpointTap(endpoint),
        ));
      }
    }

    if (sections.isEmpty && !isLoading) {
      sections.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Center(
            child: Text(
              'No results found',
              style: AppTypography.caption,
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: AppRadius.br12,
        border: Border.all(color: border.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: AppRadius.br12,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: sections,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;

  const _SectionLabel({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
      child: Row(
        children: [
          Icon(icon, size: 11, color: AppColors.textMuted),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: AppTypography.label.copyWith(
              fontSize: 10,
              letterSpacing: 0.8,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: AppColors.border.withValues(alpha: 0.3),
    );
  }
}
