import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../data/models/financial_summaries.dart';
import '../../../providers/providers.dart';

class BalanceTrendChart extends ConsumerWidget {
  const BalanceTrendChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final trend = ref.watch(balanceTrendProvider);

    return GlassCard(
      glowColor: AppColors.purple,
      radius: 24,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Balance Trend',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '6-month history',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: trend.maybeWhen(
              orElse: () => const SizedBox.shrink(),
              data: (points) => points.length < 2
                  ? Center(
                      child: Text(
                        'Not enough history yet',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    )
                  : _TrendLineChart(points: points),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendLineChart extends StatelessWidget {
  const _TrendLineChart({required this.points});

  final List<BalancePoint> points;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxY = points
        .map((p) => p.total)
        .fold<double>(0, (cur, v) => v > cur ? v : cur);
    final minAvailable = points
        .map((p) => p.available)
        .fold<double>(0, (cur, v) => v < cur ? v : cur);
    final normalizedMax = maxY <= 0 ? 1.0 : maxY * 1.12;

    List<FlSpot> spots(double Function(BalancePoint) pick) => [
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), pick(points[i])),
    ];

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (points.length - 1).toDouble(),
        minY: minAvailable < 0 ? minAvailable * 1.1 : 0,
        maxY: normalizedMax,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: normalizedMax / 4,
          getDrawingHorizontalLine: (_) => FlLine(
            color: Colors.white.withValues(alpha: 0.06),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= points.length) return const SizedBox.shrink();
                final isLast = i == points.length - 1;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    DateFormat('MMM').format(points[i].month).toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isLast
                          ? AppColors.teal
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 9,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.surfaceLight,
            getTooltipItems: (touched) => touched.map((t) {
              final p = points[t.spotIndex];
              final label = t.barIndex == 0 ? 'Total' : 'Available';
              final value = t.barIndex == 0 ? p.total : p.available;
              return LineTooltipItem(
                '$label ${formatBdtAmount(value)}',
                const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          // Total (top line) — drawn first so the Available fill sits on top.
          LineChartBarData(
            spots: spots((p) => p.total),
            isCurved: true,
            barWidth: 2,
            color: AppColors.purple,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.purple.withValues(alpha: 0.16),
            ),
          ),
          // Available (bottom band) — gold.
          LineChartBarData(
            spots: spots((p) => p.available),
            isCurved: true,
            barWidth: 2,
            color: AppColors.teal,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.teal.withValues(alpha: 0.22),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
    );
  }
}
