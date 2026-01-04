import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stress_pilot/features/projects/domain/flow.dart' as flow;
import 'package:stress_pilot/features/common/domain/endpoint.dart'
    as domain_endpoint;
import 'package:stress_pilot/features/common/presentation/widgets/endpoint_type_badge.dart';
import '../../../domain/canvas.dart';
import '../../../../common/presentation/provider/endpoint_provider.dart';

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

  void _onScroll() {
    final provider = context.read<EndpointProvider>();
    if (!provider.hasMore || provider.isLoadingMore) return;
    if (_scrollCtrl.position.maxScrollExtent - _scrollCtrl.position.pixels <
        200) {
      provider.loadMoreEndpoints(projectId: widget.projectId);
    }
  }

  Future<void> _handleUpload(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'yaml', 'yml', 'proto'],
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Uploading endpoints...')),
          );
        }

        if (!context.mounted) return;

        await context.read<EndpointProvider>().uploadEndpointsFile(
          filePath: filePath,
          projectId: widget.projectId,
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Endpoints uploaded successfully')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final endpointProvider = context.watch<EndpointProvider>();

    if (endpointProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final endpoints = endpointProvider.endpoints;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Text(
                'ENDPOINTS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.upload_file, size: 18),
                tooltip: 'Import Endpoints',
                onPressed: () => _handleUpload(context),
                visualDensity: VisualDensity.compact,
              ),
            ],
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
                    'No endpoints',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                )
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount:
                      endpoints.length + (endpointProvider.hasMore ? 1 : 0),
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
                          elevation: 8,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 240,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colors.secondaryContainer,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: colors.outline,
                                width: 2,
                              ),
                            ),
                            child: _buildEndpointItem(context, endpoint, true),
                          ),
                        ),
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
                endpoint.url,
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
