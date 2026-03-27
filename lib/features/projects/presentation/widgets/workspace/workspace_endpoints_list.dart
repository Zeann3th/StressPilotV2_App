import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stress_pilot/core/navigation/app_router.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/features/projects/domain/models/flow.dart' as flow;
import 'package:stress_pilot/features/endpoints/domain/models/endpoint.dart'
    as domain_endpoint;
import 'package:stress_pilot/features/endpoints/presentation/widgets/endpoint_type_badge.dart';
import 'package:stress_pilot/core/di/locator.dart';
import 'package:stress_pilot/features/shared/domain/repositories/utility_repository.dart';
import 'package:stress_pilot/features/projects/domain/models/canvas.dart';
import '../../../../endpoints/presentation/provider/endpoint_provider.dart';

class WorkspaceEndpointsList extends StatefulWidget {
  final flow.Flow? selectedFlow;
  final int projectId;

  const WorkspaceEndpointsList({
    super.key,
    required this.selectedFlow,
    required this.projectId,
  });

  @override
  State<WorkspaceEndpointsList> createState() => _WorkspaceEndpointsListState();
}

class _WorkspaceEndpointsListState extends State<WorkspaceEndpointsList> {
  late ScrollController _scrollCtrl;
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _scrollCtrl = ScrollController();
    _scrollCtrl.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EndpointProvider>().loadEndpoints(
        projectId: widget.projectId,
      );
    });
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() => _query = value.trim().toLowerCase());
    });
  }

  void _onScroll() {
    if (_query.isNotEmpty) return;
    final provider = context.read<EndpointProvider>();
    if (!provider.hasMore || provider.isLoadingMore) return;
    if (_scrollCtrl.position.maxScrollExtent - _scrollCtrl.position.pixels <
        200) {
      provider.loadMoreEndpoints(projectId: widget.projectId);
    }
  }

  Future<void> _handleUpload(BuildContext context) async {
    try {
      final capabilities = await getIt<UtilityRepository>().getCapabilities();
      final formats = capabilities.parsers
          .expand((p) => p.formats)
          .map((e) => e.toLowerCase().replaceAll('.', ''))
          .toSet()
          .toList();

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: formats.isEmpty ? ['json', 'yaml', 'yml', 'proto'] : formats,
      );

      final filePath = result?.files.firstOrNull?.path;
      if (filePath != null) {
        AppNavigator.scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(content: Text('Uploading endpoints...')),
        );

        if (!context.mounted) return;

        await context.read<EndpointProvider>().uploadEndpointsFile(
          filePath: filePath,
          projectId: widget.projectId,
        );

        AppNavigator.scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(content: Text('Endpoints uploaded successfully')),
        );
      }
    } catch (e) {
      AppNavigator.scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Upload failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final endpointProvider = context.watch<EndpointProvider>();

    if (endpointProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final allEndpoints = endpointProvider.endpoints;
    final endpoints = _query.isEmpty
        ? allEndpoints
        : allEndpoints
            .where((e) =>
                e.name.toLowerCase().contains(_query) ||
                (e.url?.toLowerCase().contains(_query) ?? false) ||
                e.type.toLowerCase().contains(_query))
            .toList();

    return Column(
      children: [
        // Header row
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 8, 4),
          child: Row(
            children: [
              Text(
                'ENDPOINTS',
                style: AppTypography.label.copyWith(color: AppColors.textMuted),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.upload_file, size: 16, color: AppColors.textMuted),
                tooltip: 'Import Endpoints',
                onPressed: () => _handleUpload(context),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
            ],
          ),
        ),

        // Search box
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
          child: SizedBox(
            height: 30,
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              style: AppTypography.caption.copyWith(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search endpoints...',
                hintStyle: AppTypography.caption.copyWith(color: AppColors.textMuted),
                prefixIcon: Icon(Icons.search_rounded, size: 14, color: AppColors.textMuted),
                prefixIconConstraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                filled: true,
                fillColor: AppColors.elevated,
                contentPadding: const EdgeInsets.symmetric(vertical: 6),
                border: OutlineInputBorder(
                  borderRadius: AppRadius.br8,
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppRadius.br8,
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadius.br8,
                  borderSide: BorderSide(color: AppColors.accent, width: 1.5),
                ),
                isDense: true,
              ),
              cursorColor: AppColors.accent,
            ),
          ),
        ),

        if (endpointProvider.error != null)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Error: ${endpointProvider.error}',
              style: const TextStyle(color: Colors.red),
            ),
          ),

        Expanded(
          child: endpoints.isEmpty
              ? Center(
                  child: Text(
                    _query.isEmpty ? 'No endpoints' : 'No results',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                )
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: endpoints.length +
                      (_query.isEmpty && endpointProvider.hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= endpoints.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: endpointProvider.isLoadingMore
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      );
                    }

                    final endpoint = endpoints[index];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Draggable<DragData>(
                        data: DragData(
                          type: FlowNodeType.endpoint,
                          payload: {
                            'id': endpoint.id,
                            'name': endpoint.name,
                            'method': endpoint.httpMethod,
                            'url': endpoint.url,
                            'type': endpoint.type,
                          },
                        ),
                        feedback: Material(
                          elevation: 12,
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.transparent,
                          child: Container(
                            width: 240,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: colors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: colors.primary.withValues(alpha: 0.5),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: colors.primary.withValues(alpha: 0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: _buildEndpointItem(context, endpoint, true),
                          ),
                        ),
                        dragAnchorStrategy: (draggable, context, position) {
                          return const Offset(120, 30);
                        },
                        childWhenDragging: Opacity(
                          opacity: 0.3,
                          child: _buildEndpointCard(context, endpoint),
                        ),
                        child: _buildEndpointCard(context, endpoint),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEndpointCard(
    BuildContext context,
    domain_endpoint.Endpoint endpoint,
  ) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: _buildEndpointItem(context, endpoint, false),
        ),
      ),
    );
  }

  Widget _buildEndpointItem(
    BuildContext context,
    domain_endpoint.Endpoint endpoint,
    bool isDragging,
  ) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        if (!isDragging) ...[
          Icon(
            Icons.drag_indicator,
            size: 16,
            color: colors.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 8),
        ],
        EndpointTypeBadge(type: endpoint.type, compact: true),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                endpoint.name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                endpoint.url ?? '—',
                style: TextStyle(
                  fontSize: 11,
                  color: colors.onSurfaceVariant,
                  fontFamily: 'JetBrains Mono',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
