import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../data/models/financial_summaries.dart';

class BalanceCard extends StatelessWidget {
  const BalanceCard({
    required this.summary,
    required this.cardNumber,
    required this.onEditCardNumber,
    super.key,
  });

  final BalanceSummary summary;
  final String cardNumber;
  final VoidCallback onEditCardNumber;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Hero(
          tag: 'balance-card',
          child: DecoratedBox(
            decoration: AppDecorations.heroCard(),
            child: Stack(
              children: [
                // Gloss finish overlay
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [
                          Colors.white.withValues(alpha: 0.05),
                          Colors.transparent,
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
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
                          Text(
                            'BANGLADESH',
                            style: theme.textTheme.labelMedium,
                          ),
                        ],
                      ),
                      const Spacer(),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'asset/chip.png',
                          width: 42,
                          height: 30,
                          fit: BoxFit.cover,
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
                      fontSize: 42,
                      color: AppColors.textPrimary,
                      shadows: [
                        const Shadow(color: Color(0x4DFFFFFF), blurRadius: 12),
                      ],
                    ),
                  ),
                  const SizedBox(height: 34),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _formatMaskedCardNumber(cardNumber),
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: AppColors.textPrimary.withValues(
                              alpha: 0.72,
                            ),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: onEditCardNumber,
                        splashRadius: 18,
                        style: IconButton.styleFrom(
                          minimumSize: const Size(32, 32),
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: const Icon(
                          LucideIcons.pencil,
                          color: AppColors.textPrimary,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 6),
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
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 12, right: 6),
                child: _BalanceSegment(
                  label: 'AVAILABLE',
                  amount: summary.availableBalance,
                  color: AppColors.teal,
                  alignEnd: false,
                ),
              ),
            ),
            const SizedBox(width: 18),
            const _VerticalDivider(),
            const SizedBox(width: 18),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 6, right: 12),
                child: _BalanceSegment(
                  label: 'SAVINGS',
                  amount: summary.savingsBalance,
                  color: AppColors.purple,
                  alignEnd: true,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

String _formatMaskedCardNumber(String rawValue) {
  final digits = rawValue.replaceAll(RegExp(r'\D'), '');
  if (digits.length < 12) return rawValue;

  final leading = digits.substring(0, 4);
  final trailing = digits.substring(digits.length - 4);
  return '$leading •••• •••• $trailing';
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
          textStyle: theme.textTheme.headlineMedium?.copyWith(
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
