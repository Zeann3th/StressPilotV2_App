import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stress_pilot/features/projects/domain/flow.dart' as flow;
import 'package:stress_pilot/features/projects/domain/endpoint.dart' as domain_endpoint;
import '../../provider/endpoint_provider.dart';

class WorkspaceEndpointsList extends StatelessWidget {
  final flow.Flow? selectedFlow;

  const WorkspaceEndpointsList({super.key, required this.selectedFlow});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final endpointProvider = context.watch<EndpointProvider>();

    if (endpointProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (endpointProvider.error != null) {
      return Center(child: Text('Error: ${endpointProvider.error}'));
    }

    final endpoints = endpointProvider.endpoints;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
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
                icon: const Icon(Icons.add, size: 18),
                tooltip: 'Add Endpoint',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Add endpoint coming soon')),
                  );
                },
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
        if (selectedFlow != null)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.primaryContainer.withAlpha(100),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.primary.withAlpha(50), width: 1),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: colors.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Drag endpoints to canvas',
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        Expanded(
          child: endpoints.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.dns_outlined,
                          size: 48,
                          color: colors.onSurfaceVariant.withAlpha(100),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No endpoints yet',
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add endpoints to use\nin your flows',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colors.onSurfaceVariant.withAlpha(180),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: endpoints.length,
                  itemBuilder: (context, index) {
                    final endpoint = endpoints[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Draggable<domain_endpoint.Endpoint>(
                        data: endpoint,
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

  Widget _buildEndpointCard(BuildContext context, domain_endpoint.Endpoint endpoint) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('View ${endpoint.name} details')),
          );
        },
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

  Widget _buildEndpointItem(BuildContext context, domain_endpoint.Endpoint endpoint, bool isDragging) {
    final colors = Theme.of(context).colorScheme;
    Color methodColor;
    switch (endpoint.httpMethod) {
      case 'POST':
        methodColor = Colors.green;
        break;
      case 'PUT':
        methodColor = Colors.orange;
        break;
      case 'DELETE':
        methodColor = Colors.red;
        break;
      default:
        methodColor = Colors.blue;
    }
    return Row(
      children: [
        if (!isDragging) ...[
          Icon(
            Icons.drag_indicator,
            size: 16,
            color: colors.onSurfaceVariant.withAlpha(150),
          ),
          const SizedBox(width: 8),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: methodColor.withAlpha(40),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: methodColor, width: 1),
          ),
          child: Text(
            endpoint.httpMethod ?? 'GET',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: methodColor,
            ),
          ),
        ),
        const SizedBox(width: 8),
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
                  fontFamily: 'monospace',
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
