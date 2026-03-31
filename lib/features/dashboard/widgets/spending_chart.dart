import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../data/database/app_database.dart';

/// Spending overview bar chart showing Jan–Dec of the current year.
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
  static const _plotAreaHeight = 184.0;

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
    final maxValue = _monthSeries
        .map((item) => item.amount)
        .fold<double>(0, (current, value) => value > current ? value : current);
    final normalizedMax = maxValue <= 0 ? 1.0 : maxValue;
    final chartMax = normalizedMax * 1.2;

    return GlassCard(
      glowColor: AppColors.teal,
      radius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Spending Overview',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
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
                    style: Theme.of(
                      context,
                    ).textTheme.labelMedium?.copyWith(color: AppColors.teal),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
            child: Stack(
              children: [
                BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceBetween,
                    maxY: chartMax,
                    minY: 0,
                    gridData: const FlGridData(show: false),
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
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= _monthSeries.length) {
                              return const SizedBox.shrink();
                            }
                            final month = _monthSeries[index];
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                month.label,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: month.isCurrent
                                          ? AppColors.teal
                                          : AppColors.textSecondary,
                                      fontWeight: month.isCurrent
                                          ? FontWeight.w800
                                          : FontWeight.w500,
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
                        getTooltipColor: (group) =>
                            AppColors.surfaceContainerHighest,
                        tooltipRoundedRadius: 16,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final actualAmount =
                              (groupIndex >= 0 &&
                                  groupIndex < _monthSeries.length)
                              ? _monthSeries[groupIndex].amount
                              : 0.0;
                          return BarTooltipItem(
                            formatBdtAmount(actualAmount, fractionDigits: 0),
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          );
                        },
                      ),
                    ),
                    barGroups: [
                      for (var i = 0; i < _monthSeries.length; i++)
                        BarChartGroupData(
                          x: i,
                          barRods: _monthSeries[i].amount <= 0
                              ? []
                              : [
                                  BarChartRodData(
                                    toY: _monthSeries[i].amount,
                                    width: _monthSeries[i].isCurrent ? 14 : 11,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(999),
                                    ),
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: _monthSeries[i].isCurrent
                                          ? const [
                                              AppColors.teal,
                                              AppColors.blue,
                                            ]
                                          : [
                                              AppColors.teal.withValues(
                                                alpha: 0.7,
                                              ),
                                              AppColors.blue.withValues(
                                                alpha: 0.62,
                                              ),
                                            ],
                                    ),
                                  ),
                                ],
                        ),
                    ],
                  ),
                  swapAnimationDuration: const Duration(milliseconds: 700),
                  swapAnimationCurve: Curves.easeOutCubic,
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 28),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (var i = 0; i < _monthSeries.length; i++)
                            Expanded(
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    bottom: _glowOffset(
                                      amount: _monthSeries[i].amount,
                                      maxY: chartMax,
                                    ),
                                  ),
                                  child: _monthSeries[i].amount <= 0
                                      ? const SizedBox.shrink()
                                      : _ChartPointGlow(
                                          color: _monthSeries[i].isCurrent
                                              ? AppColors.teal
                                              : AppColors.blue,
                                        ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
        isCurrent: currentYear == now.year && month == now.month,
      );
    });
  }

  double _glowOffset({required double amount, required double maxY}) {
    final ratio = maxY <= 0 ? 0.0 : (amount / maxY).clamp(0.0, 1.0);
    return math.max(0, (_plotAreaHeight * ratio) - 5);
  }

  static const _monthLabels = [
    'J',
    'F',
    'M',
    'A',
    'M',
    'J',
    'J',
    'A',
    'S',
    'O',
    'N',
    'D',
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

class _ChartPointGlow extends StatelessWidget {
  const _ChartPointGlow({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.48),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}
