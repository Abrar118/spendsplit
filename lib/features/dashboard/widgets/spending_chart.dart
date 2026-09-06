import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/glass_card.dart';
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

    return GlassCard(
      glowColor: AppColors.teal,
      radius: 24,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
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
                      'Spending Velocity',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Last 12 months · spend vs. income',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: widget.onDetailsTap,
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Text(
                    'DETAILS',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.teal,
                    ),
                  ),
                ),
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
                      reservedSize: 38,
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
                                      ? AppColors.teal
                                      : AppColors.textSecondary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 9,
                                ),
                              ),
                              if (month.showYear)
                                Text(
                                  "'${(_seriesYearFor(index) % 100).toString().padLeft(2, '0')}",
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: AppColors.textTertiary,
                                    fontSize: 8,
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
                    getTooltipColor: (_) => AppColors.teal,
                    tooltipRoundedRadius: 8,
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
                          color: AppColors.onPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
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
    final expenseColor = month.isCurrent
        ? AppColors.teal
        : month.amount <= 0
        ? Colors.white.withValues(alpha: 0.05)
        : AppColors.teal.withValues(alpha: 0.4);

    return BarChartGroupData(
      x: i,
      barsSpace: 3,
      barRods: [
        BarChartRodData(
          toY: month.amount <= 0 ? normalizedMax * 0.06 : month.amount,
          width: month.isCurrent ? 14 : 11,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
          color: expenseColor,
        ),
        if (month.income > 0)
          BarChartRodData(
            toY: month.income,
            width: 4,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
            color: AppColors.green,
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
        isCurrent:
            monthStart.year == now.year && monthStart.month == now.month,
        showYear: monthStart.month == 1,
      );
    });
  }

  static const _monthLabels = [
    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
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
