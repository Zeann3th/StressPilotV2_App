import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:stress_pilot/features/results/presentation/provider/results_provider.dart';

class RealtimeChart extends StatelessWidget {
  final String title;
  final List<FlSpotData> data;
  final Color color;
  final bool isYAxisInteger;

  const RealtimeChart({
    super.key,
    required this.title,
    required this.data,
    required this.color,
    this.isYAxisInteger = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          Expanded(
            child: data.isEmpty
                ? Center(
                    child: Text(
                      'Waiting for data...',
                      style: TextStyle(color: theme.colorScheme.outline),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: theme.colorScheme.outlineVariant.withValues(
                              alpha: 0.5,
                            ),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              if (isYAxisInteger && value % 1 != 0) {
                                return const SizedBox.shrink();
                              }
                              return Text(
                                value.toInt().toString(),
                                style: TextStyle(
                                  color: theme.colorScheme.outline,
                                  fontSize: 10,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: data.isNotEmpty ? data.first.x : 0,
                      maxX: data.isNotEmpty ? data.last.x : 0,
                      minY: 0,
                      lineBarsData: [
                        LineChartBarData(
                          spots: data.map((e) => FlSpot(e.x, e.y)).toList(),
                          isCurved: true,
                          color: color,
                          barWidth: 2,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: color.withValues(alpha: 0.1),
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
