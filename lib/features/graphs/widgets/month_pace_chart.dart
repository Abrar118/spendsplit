import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/panel.dart';
import '../../../data/database/app_database.dart';
import '../graph_series.dart';

/// This month's running spend against last month's, day by day.
class MonthPaceChart extends StatelessWidget {
  const MonthPaceChart({required this.transactions, super.key});

  final List<TransactionsTableData> transactions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pace = buildMonthPace(transactions, DateTime.now());
    final diff = pace.spentSoFar - pace.previousBySameDay;
    final days = pace.current.length > pace.previous.length
        ? pace.current.length
        : pace.previous.length;
    final top = [
      ...pace.current,
      ...pace.previous,
    ].fold<double>(0, (a, b) => a > b ? a : b);
    final maxY = top <= 0 ? 1.0 : top * 1.1;

    return Panel(
      color: AppColors.surfaceRaised,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('This month vs last', style: theme.textTheme.titleMedium),
          const SizedBox(height: 2),
          Text(
            '${formatBdtAmount(pace.spentSoFar)} spent so far, '
            '${diff == 0 ? 'the same as' : '${formatBdtAmount(diff.abs())} ${diff > 0 ? 'more' : 'less'} than'} '
            'by this day last month.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              _Key(color: AppColors.spend, label: 'This month'),
              SizedBox(width: 16),
              _Key(
                color: AppColors.textTertiary,
                label: 'Last month',
                dashed: true,
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                minX: 1,
                maxX: days.toDouble(),
                minY: 0,
                maxY: maxY,
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: AppColors.gridLine, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  topTitles: const AxisTitles(),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final day = value.toInt();
                        final today = pace.current.length;
                        final show =
                            day == 1 ||
                            day == today ||
                            (day % 7 == 1 && (day - today).abs() > 3);
                        if (!show || day != value) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '$day',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 11,
                              color: day == today
                                  ? AppColors.textPrimary
                                  : AppColors.textTertiary,
                              fontWeight: day == today
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppColors.outlineVariant,
                    tooltipRoundedRadius: 0,
                    tooltipPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    getTooltipItems: (spots) => [
                      for (final spot in spots)
                        LineTooltipItem(
                          '${spot.barIndex == 0 ? 'Last month' : 'This month'}'
                          ', day ${spot.x.toInt()}: '
                          '${formatBdtAmount(spot.y)}',
                          const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),
                lineBarsData: [
                  _line(pace.previous, AppColors.textTertiary, dashed: true),
                  _line(pace.current, AppColors.spend, markEnd: true),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static LineChartBarData _line(
    List<double> totals,
    Color color, {
    bool dashed = false,
    bool markEnd = false,
  }) {
    return LineChartBarData(
      spots: [
        for (var i = 0; i < totals.length; i++)
          FlSpot((i + 1).toDouble(), totals[i]),
      ],
      color: color,
      barWidth: 2,
      isStrokeJoinRound: true,
      dashArray: dashed ? const [5, 4] : null,
      dotData: FlDotData(
        show: markEnd,
        checkToShowDot: (spot, bar) => spot == bar.spots.last,
        getDotPainter: (spot, percent, bar, index) => FlDotSquarePainter(
          size: 9,
          color: color,
          strokeWidth: 2,
          strokeColor: AppColors.surfaceRaised,
        ),
      ),
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.color, required this.label, this.dashed = false});

  final Color color;
  final String label;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 16,
          height: 2,
          child: dashed
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (var i = 0; i < 3; i++)
                      Container(width: 4, height: 2, color: color),
                  ],
                )
              : ColoredBox(color: color),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
