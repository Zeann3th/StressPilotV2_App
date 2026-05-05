import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';
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
    final bg = AppColors.elevatedSurface;
    final border = AppColors.border;
    final textSec = AppColors.textSecondary;

    double minX = 0;
    double maxX = 0;
    double xInterval = 1000;

    if (data.isNotEmpty) {
      minX = data.first.x;
      maxX = data.last.x;
      if (maxX <= minX) maxX = minX + 1000;
      xInterval = (maxX - minX) / 5;
      if (xInterval <= 0) xInterval = 1000;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.br12,
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.heading.copyWith(fontSize: 13),
          ),
          const SizedBox(height: AppSpacing.xl),
          Expanded(
            child: data.isEmpty
                ? Center(
                    child: Text(
                      'Waiting for data...',
                      style: AppTypography.body.copyWith(
                        color: textSec.withValues(alpha: 0.5),
                      ),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      minX: minX,
                      maxX: maxX,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: border.withValues(alpha: 0.5),
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
                                  style: AppTypography.caption,
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
                                style: AppTypography.caption,
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
                          curveSmoothness: 0.2,
                          color: color,
                          barWidth: 2,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                color.withValues(alpha: 0.2),
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

    return maxY / 4;
  }
}
