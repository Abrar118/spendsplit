import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:spendsplit/core/icons/lucide_icons.dart';

import '../../../core/constants/categories.dart';
import '../../../core/constants/enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/database/app_database.dart';

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
    final presentation = _presentationFor(transaction, category);

    return Slidable(
      key: ValueKey(transaction.id),
      startActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: onSaveAsTemplate != null ? 0.32 : 0.16,
        children: [
          SlidableAction(
            onPressed: (_) => onTap(),
            backgroundColor: AppColors.blue,
            foregroundColor: Colors.white,
            icon: LucideIcons.pencil,
            borderRadius: BorderRadius.circular(20),
          ),
          if (onSaveAsTemplate != null)
            SlidableAction(
              onPressed: (_) => onSaveAsTemplate!(),
              backgroundColor: AppColors.purple,
              foregroundColor: Colors.white,
              icon: LucideIcons.bookmark,
              borderRadius: BorderRadius.circular(20),
            ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.16,
        children: [
          SlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: AppColors.coral,
            foregroundColor: Colors.white,
            icon: LucideIcons.trash2,
            borderRadius: BorderRadius.circular(20),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          onLongPress: onLongPress,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surfaceLight.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: presentation.amountColor.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      presentation.icon,
                      color: presentation.amountColor,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Title + subtitle
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          presentation.title,
                          style: theme.textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (presentation.subtitle != presentation.title) ...[
                          const SizedBox(height: 4),
                          Text(
                            presentation.subtitle,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Amount
                  Text(
                    presentation.amountText,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: presentation.amountColor,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
            ),
          ),
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
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String amountText;
  final Color amountColor;
  final IconData icon;
}

/// Accent colour for a transaction, shared with the history timeline rail.
Color transactionAccentColor(TransactionsTableData transaction) {
  return switch (TransactionType.fromDbValue(transaction.type)) {
    TransactionType.expense => AppColors.coral,
    TransactionType.income => AppColors.green,
    TransactionType.savingsDeposit => AppColors.purple,
    TransactionType.savingsWithdrawal => AppColors.amber,
  };
}

_TransactionPresentation _presentationFor(
  TransactionsTableData transaction,
  CategoriesTableData? category,
) {
  final type = TransactionType.fromDbValue(transaction.type);
  final note = transaction.note?.trim();
  final hasNote = note != null && note.isNotEmpty;

  switch (type) {
    case TransactionType.expense:
      final categoryName = category?.name ?? 'Expense';
      return _TransactionPresentation(
        title: hasNote ? note : categoryName,
        subtitle: categoryName,
        amountText: '- ৳${transaction.amount.toStringAsFixed(2)}',
        amountColor: AppColors.coral,
        icon: iconForCategoryKey(category?.icon ?? 'category'),
      );
    case TransactionType.income:
      final sourceLabel = switch (transaction.source) {
        'salary' => 'Salary',
        'freelance' => 'Freelance',
        _ => 'Income',
      };
      return _TransactionPresentation(
        title: hasNote ? note : sourceLabel,
        subtitle: sourceLabel,
        amountText: '+ ৳${transaction.amount.toStringAsFixed(2)}',
        amountColor: AppColors.green,
        icon: LucideIcons.trendingUp,
      );
    case TransactionType.savingsDeposit:
      return _TransactionPresentation(
        title: hasNote ? note : 'Savings Deposit',
        subtitle: 'Savings',
        amountText: '↓ ৳${transaction.amount.toStringAsFixed(2)}',
        amountColor: AppColors.purple,
        icon: LucideIcons.arrowDownToLine,
      );
    case TransactionType.savingsWithdrawal:
      return _TransactionPresentation(
        title: hasNote ? note : 'Savings Withdrawal',
        subtitle: 'Savings',
        amountText: '↑ ৳${transaction.amount.toStringAsFixed(2)}',
        amountColor: AppColors.amber,
        icon: LucideIcons.arrowUpFromLine,
      );
  }
}
