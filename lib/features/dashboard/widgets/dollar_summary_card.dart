import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/financial_summaries.dart';

class DollarSummaryCard extends StatelessWidget {
  const DollarSummaryCard({
    required this.summary,
    required this.onTap,
    super.key,
  });

  final DollarTrackerSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final progress = summary.annualLimit <= 0
        ? 0.0
        : (summary.spentYtd / summary.annualLimit).clamp(0.0, 1.0);

    final remainingColor = summary.remaining >= 0
        ? AppColors.green
        : AppColors.coral;

    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        glowColor: AppColors.blue,
        radius: 24,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    LucideIcons.dollarSign,
                    color: AppColors.teal,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Travel Allowance',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Limit: ${formatUsdAmount(summary.annualLimit)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const Icon(LucideIcons.chevronRight),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _AmountColumn(
                    label: 'SPENT',
                    amount: summary.spentYtd,
                    color: AppColors.coral,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _AmountColumn(
                    label: 'REMAINING',
                    amount: summary.remaining,
                    color: remainingColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _GlowingProgressBar(progress: progress),
          ],
        ),
      ),
    );
  }
}

class _AmountColumn extends StatelessWidget {
  const _AmountColumn({
    required this.label,
    required this.amount,
    required this.color,
  });

  final String label;
  final double amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 6),
          AnimatedAmountText(
            value: amount,
            formatter: (value) => formatUsdAmount(value),
            textStyle: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _GlowingProgressBar extends StatelessWidget {
  const _GlowingProgressBar({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress),
      duration: const Duration(milliseconds: 750),
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, _) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 6,
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: animatedValue,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.teal,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.teal.withValues(alpha: 0.45),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
