import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:spendsplit/core/icons/lucide_icons.dart';

import '../../../core/constants/enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../data/database/app_database.dart';
import '../../../providers/providers.dart';
import '../../transactions/widgets/add_transaction_sheet.dart';

/// Future-dated entries, which balances leave out until their date, and
/// what Available becomes once they post. Hidden when there are none.
class UpcomingCard extends ConsumerWidget {
  const UpcomingCard({super.key});

  static const _shown = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final upcoming = ref.watch(upcomingProvider);
    if (upcoming == null || upcoming.entries.isEmpty) {
      return const SizedBox.shrink();
    }
    final categories = <int, String>{
      for (final c
          in ref.watch(categoriesProvider).valueOrNull ??
              const <CategoriesTableData>[])
        c.id: c.name,
    };
    final shown = upcoming.entries.take(_shown).toList();
    final more = upcoming.entries.length - shown.length;

    return GlassCard(
      glowColor: AppColors.blue,
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.clock3, size: 18, color: AppColors.blue),
              const SizedBox(width: 8),
              Text('Upcoming', style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final entry in shown)
            _UpcomingRow(
              entry: entry,
              label: _label(entry, categories),
              onTap: () =>
                  showAddTransactionSheet(context, existingTransaction: entry),
            ),
          if (more > 0)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xxs),
              child: Text(
                '+$more more',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'AVAILABLE AFTER SCHEDULED',
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.textTertiary,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            formatBdtAmount(upcoming.availableAfter),
            style: theme.textTheme.titleLarge?.copyWith(
              color: upcoming.availableAfter < 0
                  ? AppColors.coral
                  : AppColors.teal,
            ),
          ),
        ],
      ),
    );
  }

  static String _label(TransactionsTableData entry, Map<int, String> cats) {
    final note = entry.note?.trim();
    if (note != null && note.isNotEmpty) return note;
    final category = cats[entry.categoryId];
    if (category != null) return category;
    return switch (TransactionType.fromDbValue(entry.type)) {
      TransactionType.income => 'Income',
      TransactionType.expense => 'Expense',
      TransactionType.savingsDeposit => 'To savings',
      TransactionType.savingsWithdrawal => 'From savings',
    };
  }
}

class _UpcomingRow extends StatelessWidget {
  const _UpcomingRow({
    required this.entry,
    required this.label,
    required this.onTap,
  });

  final TransactionsTableData entry;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final type = TransactionType.fromDbValue(entry.type);
    final adds =
        type == TransactionType.income ||
        type == TransactionType.savingsWithdrawal;
    final color = switch (type) {
      TransactionType.income => AppColors.green,
      TransactionType.expense => AppColors.coral,
      TransactionType.savingsDeposit ||
      TransactionType.savingsWithdrawal => AppColors.purple,
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            SizedBox(
              width: 52,
              child: Text(
                DateFormat('MMM d').format(entry.date).toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${adds ? '+' : '−'}${formatBdtAmount(entry.amount)}',
              style: theme.textTheme.bodyMedium?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
