import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spendsplit/core/icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../providers/providers.dart';
import '../../transactions/widgets/add_transaction_sheet.dart';

class ExpectedThisMonthCard extends ConsumerWidget {
  const ExpectedThisMonthCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final expected = ref.watch(expectedThisMonthProvider);
    if (expected.isEmpty) return const SizedBox.shrink();

    return GlassCard(
      glowColor: AppColors.amber,
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.calendarDays,
                size: 18,
                color: AppColors.amber,
              ),
              const SizedBox(width: 8),
              Text('Expected this month', style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < expected.length; i++) ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expected[i].name,
                        style: theme.textTheme.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        expected[i].amount != null
                            ? formatBdtAmount(
                                expected[i].amount!,
                                fractionDigits: 0,
                              )
                            : '—',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => showAddTransactionSheet(
                    context,
                    fromTemplate: expected[i],
                  ),
                  child: const Text('Log'),
                ),
              ],
            ),
            if (i != expected.length - 1)
              Divider(color: Colors.white.withValues(alpha: 0.06), height: 8),
          ],
        ],
      ),
    );
  }
}
