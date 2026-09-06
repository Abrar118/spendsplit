import 'package:flutter/material.dart';
import 'package:spendsplit/core/icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/financial_summaries.dart';

class MonthlySnapshotRow extends StatelessWidget {
  const MonthlySnapshotRow({required this.summary, super.key});

  final MonthlyFinanceSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 12),
          child: Text(
            'THIS MONTH',
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _SnapshotCard(
                  label: 'INCOME',
                  rawAmount: summary.income,
                  icon: LucideIcons.trendingUp,
                  color: AppColors.green,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SnapshotCard(
                  label: 'SPENT',
                  rawAmount: summary.expenses,
                  icon: LucideIcons.trendingDown,
                  color: AppColors.coral,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SnapshotCard(
                  label: 'SAVED',
                  rawAmount: summary.saved,
                  icon: LucideIcons.piggyBank,
                  color: AppColors.purple,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SnapshotCard extends StatelessWidget {
  const _SnapshotCard({
    required this.label,
    required this.rawAmount,
    required this.icon,
    required this.color,
  });

  final String label;
  final double rawAmount;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      glowColor: color,
      radius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      opacity: 0.8,
      child: Column(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.2),
                  blurRadius: 15,
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: AnimatedAmountText(
              value: rawAmount,
              formatter: (value) => formatCompactBdt(value),
              textStyle: theme.textTheme.titleSmall?.copyWith(
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
