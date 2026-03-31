import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
    return SizedBox(
      height: 126,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        children: [
          _SnapshotCard(
            label: 'INCOME',
            rawAmount: summary.income,
            icon: LucideIcons.trendingUp,
            color: AppColors.green,
          ),
          const SizedBox(width: 14),
          _SnapshotCard(
            label: 'SPENT',
            rawAmount: summary.expenses,
            icon: LucideIcons.trendingDown,
            color: AppColors.coral,
          ),
          const SizedBox(width: 14),
          _SnapshotCard(
            label: 'SAVED',
            rawAmount: summary.saved,
            icon: LucideIcons.piggyBank,
            color: AppColors.purple,
          ),
        ],
      ),
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
    return SizedBox(
      width: 136,
      child: GlassCard(
        glowColor: color,
        radius: 16,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        opacity: 0.8,
        child: Column(
          children: [
            Container(
              width: 38,
              height: 38,
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
              child: Icon(icon, color: color, size: 18),
            ),
            const Spacer(),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedAmountText(
              value: rawAmount,
              formatter: (value) => formatCompactBdt(value),
              textStyle: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
