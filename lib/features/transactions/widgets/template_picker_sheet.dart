import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/database/app_database.dart';

Future<TransactionTemplatesTableData?> showTemplatePickerSheet(
  BuildContext context, {
  required List<TransactionTemplatesTableData> templates,
  required Map<int, CategoriesTableData> categoriesById,
  required Future<void> Function(int id) onDelete,
}) {
  return showModalBottomSheet<TransactionTemplatesTableData>(
    context: context,
    backgroundColor: AppColors.surfaceLight,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => _TemplatePickerBody(
      templates: templates,
      categoriesById: categoriesById,
      onDelete: onDelete,
    ),
  );
}

class _TemplatePickerBody extends StatelessWidget {
  const _TemplatePickerBody({
    required this.templates,
    required this.categoriesById,
    required this.onDelete,
  });

  final List<TransactionTemplatesTableData> templates;
  final Map<int, CategoriesTableData> categoriesById;
  final Future<void> Function(int id) onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text('Templates', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 16),
            if (templates.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No templates yet. Save one from the add sheet.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.4,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: templates.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final t = templates[index];
                    final type = TransactionType.fromDbValue(t.type);
                    final color = _colorForType(type);
                    final catName = t.categoryId != null
                        ? categoriesById[t.categoryId]?.name
                        : null;

                    return InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => Navigator.of(context).pop(t),
                      onLongPress: () => _confirmDelete(context, t),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainer,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 44,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t.name,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    [
                                      _readableType(type),
                                      ?catName,
                                      if (t.amount case final a?)
                                        '৳${a.toStringAsFixed(0)}',
                                    ].join(' • '),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              LucideIcons.chevronRight,
                              size: 16,
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    TransactionTemplatesTableData template,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        title: const Text('Delete template?'),
        content: Text('Remove "${template.name}" permanently?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await onDelete(template.id);
    }
  }

  Color _colorForType(TransactionType type) => switch (type) {
    TransactionType.expense => AppColors.coral,
    TransactionType.income => AppColors.green,
    TransactionType.savingsDeposit => AppColors.purple,
    TransactionType.savingsWithdrawal => AppColors.amber,
  };

  String _readableType(TransactionType type) => switch (type) {
    TransactionType.expense => 'Expense',
    TransactionType.income => 'Income',
    TransactionType.savingsDeposit => 'Savings ↓',
    TransactionType.savingsWithdrawal => 'Savings ↑',
  };
}
