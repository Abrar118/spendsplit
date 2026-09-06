import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:spendsplit/core/icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../providers/providers.dart';

String _monthKey(DateTime month) =>
    '${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}';

/// Whether the month-end recap card should render right now (days 1–5, not
/// dismissed for that month, and there was activity to recap).
final monthRecapVisibleProvider = Provider<bool>((ref) {
  if (DateTime.now().day > 5) return false;
  final recap = ref.watch(monthRecapProvider).valueOrNull;
  if (recap == null) return false;
  if (recap.income == 0 && recap.expenses == 0 && recap.netSaved == 0) {
    return false;
  }
  final dismissed = ref.watch(
    appSettingsProvider.select((s) => s.recapDismissedMonth),
  );
  return dismissed != _monthKey(recap.month);
});

/// Dismissible summary of the prior month, shown only on days 1–5.
class MonthRecapCard extends ConsumerWidget {
  const MonthRecapCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(monthRecapVisibleProvider)) return const SizedBox.shrink();
    final recap = ref.watch(monthRecapProvider).valueOrNull;
    if (recap == null) return const SizedBox.shrink();
    final key = _monthKey(recap.month);

    final theme = Theme.of(context);
    final ratePct = (recap.savingsRate * 100).round();

    return GlassCard(
      glowColor: AppColors.purple,
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${DateFormat('MMMM').format(recap.month)} recap',
                style: theme.textTheme.titleMedium,
              ),
              const Spacer(),
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => ref
                    .read(appSettingsProvider.notifier)
                    .dismissRecapForMonth(key),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    LucideIcons.x,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Saved ${formatBdtAmount(recap.netSaved, fractionDigits: 0)}'
            '${recap.income > 0 ? ' ($ratePct% of income)' : ''}.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (recap.budgetDelta != null) ...[
            const SizedBox(height: 4),
            Text(
              recap.budgetDelta! >= 0
                  ? '${formatBdtAmount(recap.budgetDelta!, fractionDigits: 0)} under budget.'
                  : '${formatBdtAmount(-recap.budgetDelta!, fractionDigits: 0)} over budget.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: recap.budgetDelta! >= 0
                    ? AppColors.green
                    : AppColors.coral,
              ),
            ),
          ],
          if (recap.topCategories.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in recap.topCategories)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Color(c.colorValue).withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${c.name} · ${formatBdtAmount(c.amount, fractionDigits: 0)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Color(c.colorValue),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
