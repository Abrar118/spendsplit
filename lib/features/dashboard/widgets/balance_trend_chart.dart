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
          const SizedBox(height: 8),
          Row(
            children: [
              _LegendDot(color: AppColors.teal, label: 'Available'),
              const SizedBox(width: 16),
              _LegendDot(color: AppColors.purple, label: 'Savings'),
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
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
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
              reservedSize: 26,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= points.length) return const SizedBox.shrink();
                final isLast = i == points.length - 1;
                return Padding(
                  padding: const EdgeInsets.only(top: 10),
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
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppColors.surfaceLight,
            tooltipRoundedRadius: 10,
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
                  fontSize: 11,
                ),
                children: [
                  TextSpan(
                    text: 'Available ${formatBdtAmount(available)}',
                    style: const TextStyle(
                      color: AppColors.teal,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                  const TextSpan(
                    text: '   ',
                    style: TextStyle(fontSize: 11),
                  ),
                  TextSpan(
                    text: 'Savings ${formatBdtAmount(savings)}',
                    style: const TextStyle(
                      color: AppColors.purple,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
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
          borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
          rodStackItems: [
            BarChartRodStackItem(
              0,
              available,
              AppColors.teal.withValues(alpha: dim),
            ),
            BarChartRodStackItem(
              available,
              top,
              AppColors.purple.withValues(alpha: dim),
            ),
          ],
        ),
      ],
    );
  }
}
