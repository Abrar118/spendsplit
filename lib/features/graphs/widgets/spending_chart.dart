import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/panel.dart';
import '../../../data/database/app_database.dart';

class SpendingChart extends StatefulWidget {
  const SpendingChart({
    required this.transactions,
    super.key,
    this.onDetailsTap,
  });

  final List<TransactionsTableData> transactions;
  final VoidCallback? onDetailsTap;

  @override
  State<SpendingChart> createState() => _SpendingChartState();
}

class _SpendingChartState extends State<SpendingChart> {
  late List<_MonthSpend> _monthSeries;

  @override
  void initState() {
    super.initState();
    _monthSeries = _buildMonthSeries(widget.transactions);
  }

  @override
  void didUpdateWidget(covariant SpendingChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.transactions, widget.transactions)) {
      _monthSeries = _buildMonthSeries(widget.transactions);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxValue = _monthSeries.fold<double>(
      0,
      (cur, item) =>
          [cur, item.amount, item.income].reduce((a, b) => a > b ? a : b),
    );
    final normalizedMax = maxValue <= 0 ? 1.0 : maxValue;

    return Panel(
      color: AppColors.surfaceRaised,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Spending, last 12 months',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Bars are spending; the thin green bar is income.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (widget.onDetailsTap != null)
                TextButton(
                  onPressed: widget.onDetailsTap,
                  child: const Text('Details'),
                ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceBetween,
                maxY: normalizedMax * 1.15,
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
                      reservedSize: 44,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= _monthSeries.length) {
                          return const SizedBox.shrink();
                        }
                        final month = _monthSeries[index];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                month.label,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: month.isCurrent
                                      ? AppColors.textPrimary
                                      : AppColors.textTertiary,
                                  fontWeight: month.isCurrent
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  fontSize: 11,
                                ),
                              ),
                              if (month.showYear)
                                Text(
                                  "'${(_seriesYearFor(index) % 100).toString().padLeft(2, '0')}",
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: AppColors.textTertiary,
                                    fontSize: 11,
                                  ),
                                ),
                            ],
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
                    tooltipPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final month =
                          (groupIndex >= 0 && groupIndex < _monthSeries.length)
                          ? _monthSeries[groupIndex]
                          : null;
                      if (month == null) return null;
                      return BarTooltipItem(
                        'Spent ${formatBdtAmount(month.amount, fractionDigits: 0)}'
                        '\nEarned ${formatBdtAmount(month.income, fractionDigits: 0)}',
                        const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      );
                    },
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < _monthSeries.length; i++)
                    _buildBarGroup(i, normalizedMax),
                ],
              ),
              swapAnimationDuration: const Duration(milliseconds: 700),
              swapAnimationCurve: Curves.easeOutCubic,
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int i, double normalizedMax) {
    final month = _monthSeries[i];
    final expenseColor = month.amount <= 0
        ? AppColors.outlineVariant
        : month.isCurrent
        ? AppColors.spend
        : AppColors.spend.withValues(alpha: 0.45);

    return BarChartGroupData(
      x: i,
      barsSpace: 3,
      barRods: [
        BarChartRodData(
          toY: month.amount <= 0 ? normalizedMax * 0.06 : month.amount,
          width: month.isCurrent ? 14 : 11,
          borderRadius: BorderRadius.zero,
          color: expenseColor,
        ),
        if (month.income > 0)
          BarChartRodData(
            toY: month.income,
            width: 4,
            borderRadius: BorderRadius.zero,
            color: AppColors.income,
          ),
      ],
    );
  }

  int _seriesYearFor(int index) {
    final now = DateTime.now();
    final anchor = DateTime(now.year, now.month);
    return DateTime(anchor.year, anchor.month - 11 + index).year;
  }

  static List<_MonthSpend> _buildMonthSeries(
    List<TransactionsTableData> transactions,
  ) {
    final now = DateTime.now();
    final anchor = DateTime(now.year, now.month);

    return List.generate(12, (i) {
      final monthStart = DateTime(anchor.year, anchor.month - 11 + i);
      final nextMonth = DateTime(monthStart.year, monthStart.month + 1);
      var expense = 0.0;
      var income = 0.0;
      for (final entry in transactions) {
        if (entry.date.isBefore(monthStart) ||
            !entry.date.isBefore(nextMonth)) {
          continue;
        }
        switch (TransactionType.fromDbValue(entry.type)) {
          case TransactionType.expense:
            expense += entry.amount;
          case TransactionType.income:
            income += entry.amount;
          case TransactionType.savingsDeposit:
          case TransactionType.savingsWithdrawal:
            break;
        }
      }
      return _MonthSpend(
        label: _monthLabels[monthStart.month - 1],
        amount: expense,
        income: income,
        isCurrent: monthStart.year == now.year && monthStart.month == now.month,
        showYear: monthStart.month == 1,
      );
    });
  }

  static const _monthLabels = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
}

class _MonthSpend {
  const _MonthSpend({
    required this.label,
    required this.amount,
    required this.income,
    required this.isCurrent,
    required this.showYear,
  });

  final String label;
  final double amount;
  final double income;
  final bool isCurrent;
  final bool showYear;
}
