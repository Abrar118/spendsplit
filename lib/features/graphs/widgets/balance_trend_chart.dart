import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/panel.dart';
import '../../../data/models/financial_summaries.dart';
import '../../../providers/providers.dart';

class BalanceTrendChart extends ConsumerWidget {
  const BalanceTrendChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final trend = ref.watch(balanceTrendProvider);

    return Panel(
      color: AppColors.surfaceRaised,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Balance, last 6 months', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              _LegendDot(color: AppColors.accent, label: 'Available'),
              const SizedBox(width: 16),
              _LegendDot(color: AppColors.savings, label: 'Savings'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: trend.maybeWhen(
              orElse: () => const SizedBox.shrink(),
              data: (points) => points.isEmpty
                  ? const SizedBox.shrink()
                  : _TrendBarChart(points: points),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, color: color),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}

class _TrendBarChart extends StatelessWidget {
  const _TrendBarChart({required this.points});

  final List<BalancePoint> points;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxTotal = points
        .map((p) => p.total)
        .fold<double>(0, (cur, v) => v > cur ? v : cur);
    final normalizedMax = maxTotal <= 0 ? 1.0 : maxTotal * 1.15;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceBetween,
        maxY: normalizedMax,
        minY: 0,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: normalizedMax / 4,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: AppColors.gridLine, strokeWidth: 1),
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
              reservedSize: 26,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= points.length) return const SizedBox.shrink();
                final isLast = i == points.length - 1;
                return Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    DateFormat('MMM').format(points[i].month),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isLast
                          ? AppColors.textPrimary
                          : AppColors.textTertiary,
                      fontWeight: isLast ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppColors.outlineVariant,
            tooltipRoundedRadius: 6,
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            tooltipPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              if (groupIndex < 0 || groupIndex >= points.length) return null;
              final p = points[groupIndex];
              final available = p.available.abs() < 0.5 ? 0.0 : p.available;
              final savings = p.savings.abs() < 0.5 ? 0.0 : p.savings;
              return BarTooltipItem(
                '${DateFormat('MMM yyyy').format(p.month)}\n',
                const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
                children: [
                  TextSpan(
                    text: 'Available ${formatBdtAmount(available)}',
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const TextSpan(text: '   ', style: TextStyle(fontSize: 11)),
                  TextSpan(
                    text: 'Savings ${formatBdtAmount(savings)}',
                    style: const TextStyle(
                      color: AppColors.savings,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        barGroups: [
          for (var i = 0; i < points.length; i++)
            _barGroup(i, points[i], i == points.length - 1),
        ],
      ),
      swapAnimationDuration: const Duration(milliseconds: 700),
      swapAnimationCurve: Curves.easeOutCubic,
    );
  }

  BarChartGroupData _barGroup(int x, BalancePoint p, bool isCurrent) {
    final available = p.available < 0 ? 0.0 : p.available;
    final savings = p.savings < 0 ? 0.0 : p.savings;
    final top = available + savings;
    final dim = isCurrent ? 1.0 : 0.82;

    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: top <= 0 ? 0.0001 : top,
          width: isCurrent ? 30 : 26,
          borderRadius: BorderRadius.zero,
          // Explicit: with no stack items fl_chart falls back to its own cyan.
          color: AppColors.hairline,
          rodStackItems: [
            BarChartRodStackItem(
              0,
              available,
              AppColors.accent.withValues(alpha: dim),
            ),
            BarChartRodStackItem(
              available,
              top,
              AppColors.savings.withValues(alpha: dim),
            ),
          ],
        ),
      ],
    );
  }
}
