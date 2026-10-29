import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:spendsplit/core/icons/lucide_icons.dart';

import '../../../core/constants/enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/coupon.dart';
import '../../../core/widgets/section_header.dart';
import '../../../data/database/app_database.dart';
import '../../../providers/providers.dart';
import '../../transactions/widgets/add_transaction_sheet.dart';

/// Bank-SMS entries waiting to be checked, as stamped coupons: up to two,
/// newest first, each opening in the edit sheet where saving clears the
/// stamp. More than two adds a row into History's review filter.
class SmsReviewCard extends ConsumerWidget {
  const SmsReviewCard({super.key});

  static const _shown = 2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final pending =
        (ref.watch(transactionsProvider).valueOrNull ??
                const <TransactionsTableData>[])
            .where((t) => t.needsReview)
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    if (pending.isEmpty) return const SizedBox.shrink();
    final categories = <int, String>{
      for (final c
          in ref.watch(categoriesProvider).valueOrNull ??
              const <CategoriesTableData>[])
        c.id: c.name,
    };
    final more = pending.length - _shown;
    void openAll() => context.go('${AppRoute.transactions.path}?review=1');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader('To review', action: 'All', onAction: openAll),
        for (final entry in pending.take(_shown))
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ReviewCoupon(
              entry: entry,
              category: categories[entry.categoryId],
              onTap: () =>
                  showAddTransactionSheet(context, existingTransaction: entry),
            ),
          ),
        if (more > 0)
          InkWell(
            onTap: openAll,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '$more more to review',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  const Icon(
                    LucideIcons.chevronRight,
                    size: 18,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ReviewCoupon extends StatelessWidget {
  const _ReviewCoupon({
    required this.entry,
    required this.category,
    required this.onTap,
  });

  final TransactionsTableData entry;
  final String? category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final income =
        TransactionType.fromDbValue(entry.type) == TransactionType.income;
    final amount = '${income ? '+' : '−'}${formatBdtExact(entry.amount)}';
    final title = (entry.note?.trim().isNotEmpty ?? false)
        ? entry.note!.trim()
        : income
        ? 'Card credit'
        : 'Card debit';
    final day = DateFormat('d').format(entry.date);
    final month = DateFormat('MMM').format(entry.date);

    return Coupon(
      state: CouponState.review,
      onTap: onTap,
      semanticLabel: '$title, $amount, $day $month, needs review',
      stub: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(day, style: theme.textTheme.titleMedium),
          Text(month, style: theme.textTheme.labelSmall),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 2),
                Text(
                  'Trust Bank SMS${category == null ? '' : ' · $category'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            amount,
            style: theme.textTheme.titleMedium?.copyWith(
              color: income ? AppColors.income : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
