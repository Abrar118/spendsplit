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
    final maxValue = _monthSeries
        .map((item) => item.amount)
        .fold<double>(0, (cur, v) => v > cur ? v : cur);
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
                      'Volume vs. trajectory',
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
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= _monthSeries.length) {
                          return const SizedBox.shrink();
                        }
                        final month = _monthSeries[index];
                        return Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            month.label,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: month.isCurrent
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
                    getTooltipColor: (_) => AppColors.teal,
                    tooltipRoundedRadius: 8,
                    tooltipPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final actualAmount =
                          (groupIndex >= 0 && groupIndex < _monthSeries.length)
                              ? _monthSeries[groupIndex].amount
                              : 0.0;
                      return BarTooltipItem(
                        formatBdtAmount(actualAmount, fractionDigits: 0),
                        const TextStyle(
                          color: AppColors.onPrimary,
                          fontWeight: FontWeight.w800,
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
    final now = DateTime.now();
    final currentMonthIndex = now.month - 1;
    final isFuture = i > currentMonthIndex;

    if (month.amount <= 0) {
      // Empty month: translucent white stub (past) or nothing (future)
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: normalizedMax * 0.08,
            width: 16,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(6),
            ),
            color: isFuture
                ? Colors.transparent
                : Colors.white.withValues(alpha: 0.05),
            borderSide: isFuture
                ? BorderSide(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1,
                    strokeAlign: BorderSide.strokeAlignInside,
                  )
                : BorderSide.none,
          ),
        ],
      );
    }

    if (month.isCurrent) {
      // Current month: glowing teal-to-blue gradient
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: month.amount,
            width: 20,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(8),
            ),
            gradient: const LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Color(0xFF2563EB), AppColors.teal],
            ),
          ),
        ],
      );
    }

    // Past months with data: dimmed teal-to-blue gradient
    return BarChartGroupData(
      x: i,
      barRods: [
        BarChartRodData(
          toY: month.amount,
          width: 16,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(6),
          ),
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              const Color(0xFF2563EB).withValues(alpha: 0.45),
              AppColors.teal.withValues(alpha: 0.35),
            ],
          ),
        ),
      ],
    );
  }

  static List<_MonthSpend> _buildMonthSeries(
    List<TransactionsTableData> transactions,
  ) {
    final now = DateTime.now();
    final currentYear = now.year;

    return List.generate(12, (index) {
      final month = index + 1;
      final total = transactions
          .where(
            (entry) =>
                TransactionType.fromDbValue(entry.type) ==
                    TransactionType.expense &&
                entry.date.year == currentYear &&
                entry.date.month == month,
          )
          .fold<double>(0, (sum, entry) => sum + entry.amount);

      return _MonthSpend(
        label: _monthLabels[index],
        amount: total,
        isCurrent: month == now.month,
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
    required this.isCurrent,
  });

  final String label;
  final double amount;
  final bool isCurrent;
}
