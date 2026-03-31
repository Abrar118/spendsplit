import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/amount_text.dart';

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

    return Container(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 30),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF171A28), Color(0xFF23253A), Color(0xFF2B2940)],
          stops: [0.0, 0.58, 1.0],
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 18,
            top: 40,
            child: IgnorePointer(
              child: Container(
                width: 440,
                height: 220,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      AppColors.purple.withValues(alpha: 0.24),
                      AppColors.purple.withValues(alpha: 0.10),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TOTAL SAVINGS RESERVED',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 18,
                  letterSpacing: 7,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),
              AnimatedAmountText(
                value: totalSavings,
                formatter: (value) => formatBdtAmount(value, fractionDigits: 0),
                textStyle: theme.textTheme.displayLarge?.copyWith(
                  fontSize: 72,
                  height: 0.95,
                  color: AppColors.softPurple,
                  fontWeight: FontWeight.w800,
                  shadows: [
                    Shadow(
                      color: AppColors.purple.withValues(alpha: 0.24),
                      blurRadius: 10,
                    ),
                    Shadow(
                      color: AppColors.purple.withValues(alpha: 0.42),
                      blurRadius: 24,
                    ),
                    Shadow(
                      color: AppColors.purple.withValues(alpha: 0.24),
                      blurRadius: 48,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: positive
                      ? AppColors.teal.withValues(alpha: 0.14)
                      : AppColors.coral.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: positive
                        ? AppColors.teal.withValues(alpha: 0.30)
                        : AppColors.coral.withValues(alpha: 0.30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (positive ? AppColors.teal : AppColors.coral)
                          .withValues(alpha: 0.16),
                      blurRadius: 18,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      positive
                          ? LucideIcons.trendingUp
                          : LucideIcons.trendingDown,
                      size: 28,
                      color: positive ? AppColors.teal : AppColors.coral,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${positive ? '+' : '-'}$percent% this month',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: positive ? AppColors.teal : AppColors.coral,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'Across $activeGoalCount active goals',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: AppColors.textPrimary.withValues(alpha: 0.76),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
