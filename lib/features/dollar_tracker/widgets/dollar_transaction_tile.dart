import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:spendsplit/core/icons/lucide_icons.dart';

import '../../../core/constants/categories.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/coupon.dart';
import '../../../data/database/app_database.dart';

/// A USD expense as a coupon, date on the stub. Swipe right to edit, left to
/// delete.
class DollarTransactionTile extends StatelessWidget {
  const DollarTransactionTile({
    required this.expense,
    required this.category,
    this.onTap,
    this.onDelete,
    super.key,
  });

  final DollarExpensesTableData expense;
  final CategoriesTableData? category;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryName = category?.name ?? 'Uncategorized';
    final amount = formatUsdAmount(expense.amount, fractionDigits: 2);

    return Slidable(
      key: ValueKey(expense.id),
      startActionPane: onTap == null
          ? null
          : ActionPane(
              motion: const BehindMotion(),
              extentRatio: 0.2,
              children: [
                CustomSlidableAction(
                  onPressed: (_) => onTap!(),
                  backgroundColor: Colors.transparent,
                  foregroundColor: AppColors.textPrimary,
                  padding: EdgeInsets.zero,
                  child: const Icon(
                    LucideIcons.pencil,
                    size: 22,
                    semanticLabel: 'Edit',
                  ),
                ),
              ],
            ),
      endActionPane: onDelete == null
          ? null
          : ActionPane(
              motion: const BehindMotion(),
              extentRatio: 0.2,
              children: [
                CustomSlidableAction(
                  onPressed: (_) => onDelete!(),
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
        onTap: onTap,
        semanticLabel: '${expense.purpose}, $categoryName, $amount',
        stub: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              DateFormat('d').format(expense.date),
              style: theme.textTheme.titleMedium,
            ),
            Text(
              DateFormat('MMM').format(expense.date),
              style: theme.textTheme.labelSmall,
            ),
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
                    expense.purpose,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (category != null) ...[
                        Container(
                          width: 8,
                          height: 8,
                          color: categoryColor(category!.color),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Flexible(
                        child: Text(
                          categoryName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(amount, style: theme.textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}
