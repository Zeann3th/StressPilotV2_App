import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stress_pilot/features/results/presentation/provider/results_provider.dart';
import 'package:stress_pilot/features/results/presentation/widgets/metrics_card.dart';
import 'package:stress_pilot/features/results/presentation/widgets/realtime_chart.dart';

class ResultsPage extends StatefulWidget {
  final int flowId;

  const ResultsPage({super.key, required this.flowId});

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ResultsProvider>().initialize(widget.flowId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ResultsProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Real-time Results'),
        actions: [
          // Filter Dropdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButton<int?>(
              value: provider.selectedEndpointId,
              hint: const Text('All Endpoints'),
              underline: const SizedBox(),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('All Endpoints'),
                ),
                ...provider.endpointNames.entries.map(
                  (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                ),
              ],
              onChanged: (value) => provider.setEndpointFilter(value),
            ),
          ),
          // Export Button
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export Report (PDF)',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'PDF Export should be handled by backend for complete data integrity.',
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Metrics Row
            Row(
              children: [
                Expanded(
                  child: MetricsCard(
                    title: 'Total Requests',
                    value: provider.totalRequests.toString(),
                    icon: Icons.numbers,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: MetricsCard(
                    title: 'Avg Response Time',
                    value: '${provider.avgResponseTime.toStringAsFixed(2)} ms',
                    icon: Icons.timer,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: MetricsCard(
                    title: 'Requests / Sec',
                    value: provider.requestsPerSecond.toStringAsFixed(1),
                    icon: Icons.speed,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: MetricsCard(
                    title: 'Errors',
                    value: provider.errorCount.toString(),
                    icon: Icons.error_outline,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Charts
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: RealtimeChart(
                      title: 'Response Time (ms)',
                      data: provider.responseTimePoints,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: RealtimeChart(
                      title: 'Requests Per Second',
                      data: provider.rpsPoints,
                      color: Colors.green,
                      isYAxisInteger: true,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
