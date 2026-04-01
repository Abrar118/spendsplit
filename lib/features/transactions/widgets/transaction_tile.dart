import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 16, 0),
              child: Row(
                children: [
                  // Accent bar
                  Container(
                    width: 3,
                    height: 68,
                    decoration: BoxDecoration(
                      color: presentation.amountColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(width: 14),
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
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
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
                      ),
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

_TransactionPresentation _presentationFor(
  TransactionsTableData transaction,
  CategoriesTableData? category,
) {
  final type = TransactionType.fromDbValue(transaction.type);
  final dateText = DateFormat('MMM d • h:mm a').format(transaction.date);

  switch (type) {
    case TransactionType.expense:
      return _TransactionPresentation(
        title: transaction.note?.trim().isNotEmpty == true
            ? transaction.note!.trim()
            : (category?.name ?? 'Expense'),
        subtitle: '${category?.name ?? 'Expense'} • $dateText',
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
        title: transaction.note?.trim().isNotEmpty == true
            ? transaction.note!.trim()
            : sourceLabel,
        subtitle: '$sourceLabel • $dateText',
        amountText: '+ ৳${transaction.amount.toStringAsFixed(2)}',
        amountColor: AppColors.green,
        icon: LucideIcons.trendingUp,
      );
    case TransactionType.savingsDeposit:
      return _TransactionPresentation(
        title: transaction.note?.trim().isNotEmpty == true
            ? transaction.note!.trim()
            : 'Savings Deposit',
        subtitle: 'Savings • $dateText',
        amountText: '↓ ৳${transaction.amount.toStringAsFixed(2)}',
        amountColor: AppColors.purple,
        icon: LucideIcons.arrowDownToLine,
      );
    case TransactionType.savingsWithdrawal:
      return _TransactionPresentation(
        title: transaction.note?.trim().isNotEmpty == true
            ? transaction.note!.trim()
            : 'Savings Withdrawal',
        subtitle: 'Savings • $dateText',
        amountText: '↑ ৳${transaction.amount.toStringAsFixed(2)}',
        amountColor: AppColors.amber,
        icon: LucideIcons.arrowUpFromLine,
      );
  }
}
