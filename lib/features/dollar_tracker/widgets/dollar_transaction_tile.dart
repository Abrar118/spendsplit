import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/categories.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../data/database/app_database.dart';

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
    final color = category == null
        ? AppColors.amber
        : Color(category!.color).withValues(alpha: 1);

    return Slidable(
      key: ValueKey(expense.id),
      startActionPane: onTap == null
          ? null
          : ActionPane(
              motion: const BehindMotion(),
              extentRatio: 0.22,
              children: [
                SlidableAction(
                  onPressed: (_) => onTap!(),
                  backgroundColor: AppColors.blue,
                  foregroundColor: Colors.white,
                  icon: LucideIcons.pencil,
                  label: 'Edit',
                  borderRadius: BorderRadius.circular(22),
                ),
              ],
            ),
      endActionPane: onDelete == null
          ? null
          : ActionPane(
              motion: const BehindMotion(),
              extentRatio: 0.24,
              children: [
                SlidableAction(
                  onPressed: (_) => onDelete!(),
                  backgroundColor: AppColors.coral,
                  foregroundColor: Colors.white,
                  icon: LucideIcons.trash2,
                  label: 'Delete',
                  borderRadius: BorderRadius.circular(22),
                ),
              ],
            ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: GlassCard(
            radius: 22,
            padding: const EdgeInsets.fromLTRB(0, 0, 16, 0),
            glowColor: color,
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      iconForCategoryKey(category?.icon ?? 'globe'),
                      color: color,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            expense.purpose,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${category?.name ?? 'Uncategorized'} • ${formatShortDate(expense.date)}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    formatUsdAmount(expense.amount, fractionDigits: 2),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
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
