import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/glass_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          132,
        ),
        children: [
          Row(
            children: [
              const Icon(Icons.menu_rounded),
              const SizedBox(width: 12),
              Text('SpendSplit', style: theme.textTheme.titleLarge),
              const Spacer(),
              IconButton(
                onPressed: null,
                icon: const Icon(Icons.settings_outlined),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          DecoratedBox(
            decoration: AppDecorations.heroCard(),
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
                          Text(
                            'BANGLADESH',
                            style: theme.textTheme.labelMedium,
                          ),
                        ],
                      ),
                      const Spacer(),
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
                      ),
                    ],
                  ),
                  const SizedBox(height: 34),
                  Text('TOTAL BALANCE', style: theme.textTheme.labelMedium),
                  const SizedBox(height: 8),
                  const AmountText(
                    amount: '84,250',
                    glow: true,
                    textStyle: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
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
                        Icons.contactless_rounded,
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
          const SizedBox(height: AppSpacing.lg),
          const Row(
            children: [
              Expanded(
                child: _BalanceSegment(
                  label: 'AVAILABLE',
                  amount: '52,100',
                  color: AppColors.teal,
                  alignEnd: false,
                ),
              ),
              SizedBox(width: 18),
              _VerticalDivider(),
              SizedBox(width: 18),
              Expanded(
                child: _BalanceSegment(
                  label: 'SAVINGS',
                  amount: '32,150',
                  color: AppColors.purple,
                  alignEnd: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.section),
          SizedBox(
            height: 112,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: const [
                _SnapshotCard(
                  label: 'INCOME',
                  amount: '42k',
                  icon: Icons.arrow_upward_rounded,
                  color: AppColors.green,
                ),
                SizedBox(width: 14),
                _SnapshotCard(
                  label: 'SPENT',
                  amount: '18k',
                  icon: Icons.arrow_downward_rounded,
                  color: AppColors.coral,
                ),
                SizedBox(width: 14),
                _SnapshotCard(
                  label: 'SAVED',
                  amount: '24k',
                  icon: Icons.savings_outlined,
                  color: AppColors.purple,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.section),
          GlassCard(
            glowColor: AppColors.teal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Phase 1 Shell', style: theme.textTheme.titleLarge),
                    const Spacer(),
                    TextButton(
                      onPressed: () => context.push('/dollar-tracker'),
                      child: const Text('Dollar Tracker'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const EmptyState(
                  icon: Icons.layers_outlined,
                  title: 'Foundation In Place',
                  message:
                      'Dashboard primitives, routing, and the floating add action are wired. Live data lands in the next phases.',
                ),
              ],
            ),
          ),
        ],
      ),
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
  final String amount;
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
        Text(
          '৳ $amount',
          style: theme.textTheme.titleLarge?.copyWith(
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

class _SnapshotCard extends StatelessWidget {
  const _SnapshotCard({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
  });

  final String label;
  final String amount;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 136,
      child: GlassCard(
        glowColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const Spacer(),
            Text(label, style: theme.textTheme.labelMedium),
            const SizedBox(height: 4),
            Text(amount, style: theme.textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}
