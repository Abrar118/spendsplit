import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:spendsplit/core/icons/lucide_icons.dart';

import '../../../core/constants/categories.dart';
import '../../../core/constants/enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/coupon.dart';
import '../../../data/database/app_database.dart';

/// A History row: the entry as a coupon, time on the stub. Swipe left to
/// delete, right to save as a template.
class TransactionTile extends StatelessWidget {
  const TransactionTile({
    required this.transaction,
    required this.category,
    required this.onTap,
    required this.onDelete,
    this.onLongPress,
    this.onSaveAsTemplate,
    super.key,
  });

  final TransactionsTableData transaction;
  final CategoriesTableData? category;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback? onLongPress;
  final VoidCallback? onSaveAsTemplate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = _presentationFor(transaction, category);
    final upcoming = transaction.date.isAfter(DateTime.now());
    final time = DateFormat('h:mm').format(transaction.date);
    final meridiem = DateFormat('a').format(transaction.date).toLowerCase();

    return Slidable(
      key: ValueKey(transaction.id),
      startActionPane: onSaveAsTemplate == null
          ? null
          : ActionPane(
              motion: const BehindMotion(),
              extentRatio: 0.2,
              children: [
                CustomSlidableAction(
                  onPressed: (_) => onSaveAsTemplate!(),
                  backgroundColor: Colors.transparent,
                  foregroundColor: AppColors.textPrimary,
                  padding: EdgeInsets.zero,
                  child: const Icon(
                    LucideIcons.bookmark,
                    size: 22,
                    semanticLabel: 'Save as template',
                  ),
                ),
              ],
            ),
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.2,
        children: [
          CustomSlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: Colors.transparent,
            foregroundColor: AppColors.spend,
            padding: EdgeInsets.zero,
            child: const Icon(
              LucideIcons.trash2,
              size: 22,
              semanticLabel: 'Delete',
            ),
          ),
        ],
      ),
      child: Coupon(
        state: transaction.needsReview
            ? CouponState.review
            : upcoming
            ? CouponState.upcoming
            : CouponState.posted,
        onTap: onTap,
        onLongPress: onLongPress,
        semanticLabel:
            '${p.title}, ${p.subtitle}, ${p.amountText}'
            '${transaction.needsReview ? ', needs review' : ''}',
        stub: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(time, style: theme.textTheme.labelLarge),
            Text(meridiem, style: theme.textTheme.labelSmall),
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
                    p.title,
                    style: theme.textTheme.bodyLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (p.subtitle != p.title) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (p.marker != null) ...[
                          Container(width: 8, height: 8, color: p.marker),
                          const SizedBox(width: 6),
                        ],
                        Flexible(
                          child: Text(
                            p.subtitle,
                            style: theme.textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              p.amountText,
              style: theme.textTheme.titleMedium?.copyWith(
                color: p.amountColor,
              ),
              textAlign: TextAlign.right,
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionPresentation {
  const _TransactionPresentation({
    required this.title,
    required this.subtitle,
    required this.amountText,
    required this.amountColor,
    this.marker,
  });

  final String title;
  final String subtitle;
  final String amountText;
  final Color amountColor;

  /// Category colour, drawn as a small square before the subtitle.
  final Color? marker;
}

_TransactionPresentation _presentationFor(
  TransactionsTableData transaction,
  CategoriesTableData? category,
) {
  final type = TransactionType.fromDbValue(transaction.type);
  final note = transaction.note?.trim();
  final hasNote = note != null && note.isNotEmpty;
  final amount = formatBdtExact(transaction.amount);
  // Imported rows name their source until the user writes a note.
  final fromSms = transaction.smsRef != null;

  switch (type) {
    case TransactionType.expense:
      final categoryName = category?.name ?? 'Expense';
      return _TransactionPresentation(
        title: hasNote ? note : (fromSms ? 'Card debit' : categoryName),
        subtitle: fromSms ? 'Trust Bank SMS · $categoryName' : categoryName,
        amountText: '−$amount',
        amountColor: AppColors.textPrimary,
        marker: category == null ? null : categoryColor(category.color),
      );
    case TransactionType.income:
      final sourceLabel = switch (transaction.source) {
        'salary' => 'Salary',
        'freelance' => 'Freelance',
        _ => 'Income',
      };
      return _TransactionPresentation(
        title: hasNote ? note : (fromSms ? 'Card credit' : sourceLabel),
        subtitle: fromSms ? 'Trust Bank SMS · $sourceLabel' : sourceLabel,
        amountText: '+$amount',
        amountColor: AppColors.income,
      );
    case TransactionType.savingsDeposit:
      return _TransactionPresentation(
        title: hasNote ? note : 'Moved to savings',
        subtitle: 'Savings',
        amountText: amount,
        amountColor: AppColors.savings,
      );
    case TransactionType.savingsWithdrawal:
      return _TransactionPresentation(
        title: hasNote ? note : 'Taken from savings',
        subtitle: 'Savings',
        amountText: amount,
        amountColor: AppColors.savingsDim,
      );
  }
}
