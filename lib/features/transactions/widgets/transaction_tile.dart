import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:spendsplit/core/icons/lucide_icons.dart';

import '../../../core/constants/categories.dart';
import '../../../core/constants/enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
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
    final presentation = _presentationFor(transaction, category);
    final iconColor =
        TransactionType.fromDbValue(transaction.type) ==
                TransactionType.expense &&
            category != null
        ? Color(category!.color)
        : presentation.amountColor;

    return Slidable(
      key: ValueKey(transaction.id),
      startActionPane: onSaveAsTemplate == null
          ? null
          : ActionPane(
              motion: const BehindMotion(),
              extentRatio: 0.18,
              children: [
                CustomSlidableAction(
                  onPressed: (_) => onSaveAsTemplate!(),
                  backgroundColor: Colors.transparent,
                  foregroundColor: AppColors.purple,
                  padding: EdgeInsets.zero,
                  child: const Icon(LucideIcons.bookmark, size: 22),
                ),
              ],
            ),
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.18,
        children: [
          CustomSlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: Colors.transparent,
            foregroundColor: AppColors.coral,
            padding: EdgeInsets.zero,
            child: const Icon(LucideIcons.trash2, size: 22),
          ),
        ],
      ),
      child: Builder(
        builder: (context) {
          final animation =
              Slidable.of(context)?.animation ??
              const AlwaysStoppedAnimation<double>(0);
          return AnimatedBuilder(
            animation: animation,
            builder: (context, _) => _TileBody(
              presentation: presentation,
              iconColor: iconColor,
              frosted: animation.value.abs() > 0.001,
              onTap: onTap,
              onLongPress: onLongPress,
            ),
          );
        },
      ),
    );
  }
}

class _TileBody extends StatelessWidget {
  const _TileBody({
    required this.presentation,
    required this.iconColor,
    required this.frosted,
    required this.onTap,
    this.onLongPress,
  });

  final _TransactionPresentation presentation;
  final Color iconColor;
  final bool frosted;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(presentation.icon, color: iconColor, size: 19),
              ),
              const SizedBox(width: 14),
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
    );

    if (!frosted) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surfaceLight.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(20),
        ),
        child: content,
      );
    }

    // Swiped-open: frost the row like the bottom nav pill so the revealed
    // action icon reads through a glassy panel.
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: AppDecorations.navFrost(),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.navBar.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            children: [
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(gradient: AppDecorations.navSheen),
                ),
              ),
              content,
            ],
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
