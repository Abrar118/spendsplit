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
    super.key,
  });

  final TransactionsTableData transaction;
  final CategoriesTableData? category;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final presentation = _presentationFor(transaction, category);

    return Slidable(
      key: ValueKey(transaction.id),
      startActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.22,
        children: [
          SlidableAction(
            onPressed: (_) => onTap(),
            backgroundColor: AppColors.blue,
            foregroundColor: Colors.white,
            icon: LucideIcons.pencil,
            label: 'Edit',
            borderRadius: BorderRadius.circular(20),
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.24,
        children: [
          SlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: AppColors.coral,
            foregroundColor: Colors.white,
            icon: LucideIcons.trash2,
            label: 'Delete',
            borderRadius: BorderRadius.circular(20),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  // 3dp accent bar — stretches to match tile height
                  Container(
                    width: 3,
                    decoration: BoxDecoration(
                      color: presentation.amountColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: presentation.amountColor.withValues(
                                alpha: 0.14,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              presentation.icon,
                              color: presentation.amountColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
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
                          const SizedBox(width: 12),
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
