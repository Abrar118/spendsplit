import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/glass_card.dart';

class TotalSavingsBanner extends StatelessWidget {
  const TotalSavingsBanner({
    required this.totalSavings,
    required this.activeGoalCount,
    required this.monthDelta,
    super.key,
  });

  final double totalSavings;
  final int activeGoalCount;
  final double monthDelta;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final positive = monthDelta >= 0;
    final percent = (monthDelta.abs() * 100).toStringAsFixed(0);

    return GlassCard(
      glowColor: AppColors.purple,
      radius: 32,
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TOTAL SAVINGS RESERVED',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                AnimatedAmountText(
                  value: totalSavings,
                  formatter: (value) =>
                      formatBdtAmount(value, fractionDigits: 0),
                  textStyle: theme.textTheme.headlineLarge?.copyWith(
                    fontSize: 32,
                    color: AppColors.purple,
                    fontWeight: FontWeight.w800,
                    shadows: [
                      Shadow(
                        color: AppColors.purple.withValues(alpha: 0.35),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: positive
                      ? AppColors.teal.withValues(alpha: 0.12)
                      : AppColors.coral.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: positive
                        ? AppColors.teal.withValues(alpha: 0.22)
                        : AppColors.coral.withValues(alpha: 0.22),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      positive
                          ? LucideIcons.trendingUp
                          : LucideIcons.trendingDown,
                      size: 14,
                      color: positive ? AppColors.teal : AppColors.coral,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${positive ? '+' : '-'}$percent% this month',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: positive ? AppColors.teal : AppColors.coral,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Across $activeGoalCount active goals',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
