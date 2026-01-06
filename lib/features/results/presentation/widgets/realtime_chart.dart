import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stress_pilot/features/results/presentation/provider/results_provider.dart';
import 'dart:math' as math;

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
    final colors = Theme.of(context).colorScheme;

    // --- OPTIMIZATION: Stabilize Axis Calculation ---
    double minX = 0;
    double maxX = 0;
    double xInterval = 1000; // Default 1 second

    if (data.isNotEmpty) {
      // Lock the start of the chart to the first data point
      minX = data.first.x;
      // Lock the end of the chart to the latest data point
      maxX = data.last.x;

      // Prevent crash if only 1 data point exists
      if (maxX <= minX) maxX = minX + 1000;

      // Calculate interval to show exactly 5 labels
      xInterval = (maxX - minX) / 5;
      if (xInterval <= 0) xInterval = 1000;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: data.isEmpty
                ? Center(
                    child: Text(
                      'Waiting for data...',
                      style: TextStyle(
                        color: colors.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      // Explicitly set min/max to stop "jumping"
                      minX: minX,
                      maxX: maxX,

                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: colors.outlineVariant.withValues(alpha: 0.5),
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
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: xInterval,
                            getTitlesWidget: (value, meta) {
                              // Hide labels that fall outside our fixed range
                              if (value < minX || value > maxX) {
                                return const SizedBox.shrink();
                              }

                              final date = DateTime.fromMillisecondsSinceEpoch(
                                value.toInt(),
                              );
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  DateFormat('HH:mm:ss').format(date),
                                  style: TextStyle(
                                    color: colors.onSurfaceVariant,
                                    fontSize: 10,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            interval: _calculateYInterval(),
                            getTitlesWidget: (value, meta) {
                              if (isYAxisInteger && value % 1 != 0) {
                                return const SizedBox.shrink();
                              }
                              return Text(
                                value.toInt().toString(),
                                style: TextStyle(
                                  color: colors.onSurfaceVariant,
                                  fontSize: 10,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: data.map((e) => FlSpot(e.x, e.y)).toList(),
                          isCurved: true,
                          curveSmoothness:
                              0.2, // Lower smoothness = higher performance
                          color: color,
                          barWidth: 2,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                color.withValues(alpha: 0.3),
                                color.withValues(alpha: 0.0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                    duration: const Duration(milliseconds: 250),
                  ),
          ),
        ],
      ),
    );
  }

  double? _calculateYInterval() {
    if (data.isEmpty) return null;
    double maxY = data.map((e) => e.y).reduce(math.max);
    if (maxY == 0) return 1;
    // Divide by 4 to get ~4 horizontal grid lines
    return maxY / 4;
  }
}
