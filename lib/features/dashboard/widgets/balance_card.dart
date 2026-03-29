import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../data/models/financial_summaries.dart';

class BalanceCard extends StatelessWidget {
  const BalanceCard({required this.summary, super.key});

  final BalanceSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Hero(
          tag: 'balance-card',
          child: DecoratedBox(
          decoration: AppDecorations.heroCard(radius: 20),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trust Bank PLC',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text('BANGLADESH', style: theme.textTheme.labelMedium),
                      ],
                    ),
                    const Spacer(),
                    // Card chip with contact line texture
                    Container(
                      width: 42,
                      height: 30,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFD4AF37),
                            Color(0xFFF5E050),
                            Color(0xFFB8860B),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            4,
                            (_) => Container(
                              width: 1.5,
                              height: 16,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              color: const Color(
                                0xFF8B7500,
                              ).withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 34),
                Text('TOTAL BALANCE', style: theme.textTheme.labelMedium),
                const SizedBox(height: 8),
                // Balance amount with text glow
                AnimatedAmountText(
                  value: summary.totalBalance,
                  formatter: (value) =>
                      formatBdtAmount(value, fractionDigits: 0),
                  textStyle: theme.textTheme.displayLarge?.copyWith(
                    fontSize: 36,
                    color: AppColors.textPrimary,
                    shadows: [
                      const Shadow(color: Color(0x4DFFFFFF), blurRadius: 12),
                    ],
                  ),
                ),
                const SizedBox(height: 34),
                Row(
                  children: [
                    Text(
                      '4532 •••• •••• 8291',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppColors.textPrimary.withValues(alpha: 0.72),
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      LucideIcons.nfc,
                      color: AppColors.textPrimary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'VISA',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _BalanceSegment(
                label: 'AVAILABLE',
                amount: summary.availableBalance,
                color: AppColors.teal,
                alignEnd: false,
              ),
            ),
            const SizedBox(width: 18),
            const _VerticalDivider(),
            const SizedBox(width: 18),
            Expanded(
              child: _BalanceSegment(
                label: 'SAVINGS',
                amount: summary.savingsBalance,
                color: AppColors.purple,
                alignEnd: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BalanceSegment extends StatelessWidget {
  const _BalanceSegment({
    required this.label,
    required this.amount,
    required this.color,
    required this.alignEnd,
  });

  final String label;
  final double amount;
  final Color color;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelMedium),
        const SizedBox(height: 6),
        AnimatedAmountText(
          value: amount,
          formatter: (value) => formatBdtAmount(value, fractionDigits: 0),
          textStyle: theme.textTheme.titleLarge?.copyWith(
            color: color,
            shadows: [
              Shadow(color: color.withValues(alpha: 0.35), blurRadius: 16),
            ],
          ),
          textAlign: alignEnd ? TextAlign.right : TextAlign.left,
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 42,
      color: AppColors.outlineVariant.withValues(alpha: 0.3),
    );
  }
}
