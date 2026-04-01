import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/database/app_database.dart';
import '../../../providers/providers.dart';

class ManageTemplatesScreen extends ConsumerWidget {
  const ManageTemplatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final templatesAsync = ref.watch(transactionTemplatesProvider);
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const [];
    final catMap = {for (final c in categories) c.id: c};

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: templatesAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.teal),
          ),
          error: (_, _) => const Center(child: Text('Could not load templates')),
          data: (templates) => ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.md, AppSpacing.md, 32,
            ),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(LucideIcons.chevronLeft),
                  ),
                  const SizedBox(width: 4),
                  Text('Manage Templates', style: theme.textTheme.titleLarge),
                  const Spacer(),
                  IconButton(
                    onPressed: () => _createTemplate(context, ref, categories),
                    icon: const Icon(LucideIcons.plus, color: AppColors.teal),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (templates.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          LucideIcons.bookmark,
                          size: 40,
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No templates yet',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Save one from the add transaction sheet or swipe a transaction.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textTertiary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                for (final t in templates)
                  _TemplateTile(
                    template: t,
                    categoryName: t.categoryId != null
                        ? catMap[t.categoryId]?.name
                        : null,
                    onDelete: () => _confirmDelete(context, ref, t),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createTemplate(
    BuildContext context,
    WidgetRef ref,
    List<CategoriesTableData> categories,
  ) async {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    String selectedType = TransactionType.expense.dbValue;
    int? selectedCategoryId;
    String? selectedSource;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            final type = TransactionType.fromDbValue(selectedType);
            final isExpense = type == TransactionType.expense;
            final isIncome = type == TransactionType.income;

            return AlertDialog(
              backgroundColor: AppColors.surfaceLight,
              title: const Text('New Template'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Template name',
                        hintText: 'Morning Coffee',
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: const InputDecoration(labelText: 'Type'),
                      dropdownColor: AppColors.surfaceLight,
                      items: TransactionType.values
                          .map(
                            (t) => DropdownMenuItem(
                              value: t.dbValue,
                              child: Text(_readableType(t)),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => selectedType = v);
                      },
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Amount (optional)',
                        prefixText: '৳ ',
                      ),
                    ),
                    if (isExpense && categories.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      DropdownButtonFormField<int>(
                        value: selectedCategoryId,
                        decoration: const InputDecoration(
                          labelText: 'Category (optional)',
                        ),
                        dropdownColor: AppColors.surfaceLight,
                        items: categories
                            .map(
                              (c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(c.name),
                              ),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => selectedCategoryId = v),
                      ),
                    ],
                    if (isIncome) ...[
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: selectedSource,
                        decoration: const InputDecoration(
                          labelText: 'Source (optional)',
                        ),
                        dropdownColor: AppColors.surfaceLight,
                        items: const [
                          DropdownMenuItem(
                            value: 'salary',
                            child: Text('Salary'),
                          ),
                          DropdownMenuItem(
                            value: 'freelance',
                            child: Text('Freelance'),
                          ),
                          DropdownMenuItem(
                            value: 'other',
                            child: Text('Other'),
                          ),
                        ],
                        onChanged: (v) =>
                            setState(() => selectedSource = v),
                      ),
                    ],
                    const SizedBox(height: 14),
                    TextField(
                      controller: noteController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Note (optional)',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true) return;

    final name = nameController.text.trim();
    final amountText = amountController.text.trim();
    final note = noteController.text.trim();

    if (name.isEmpty) return;

    final amount = double.tryParse(amountText);

    await ref.read(transactionTemplateRepositoryProvider).createTemplate(
      TransactionTemplatesTableCompanion.insert(
        name: name,
        type: selectedType,
        amount: Value(amount),
        categoryId: Value(selectedCategoryId),
        source: Value(selectedSource),
        note: Value(note.isNotEmpty ? note : null),
      ),
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"$name" created')),
      );
    }
  }

  String _readableType(TransactionType type) => switch (type) {
    TransactionType.expense => 'Expense',
    TransactionType.income => 'Income',
    TransactionType.savingsDeposit => 'Savings Deposit',
    TransactionType.savingsWithdrawal => 'Savings Withdrawal',
  };

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
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
            style: FilledButton.styleFrom(backgroundColor: AppColors.coral),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await ref
        .read(transactionTemplateRepositoryProvider)
        .deleteTemplateById(template.id);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${template.name}" deleted')),
      );
    }
  }
}

class _TemplateTile extends StatelessWidget {
  const _TemplateTile({
    required this.template,
    required this.categoryName,
    required this.onDelete,
  });

  final TransactionTemplatesTableData template;
  final String? categoryName;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final type = TransactionType.fromDbValue(template.type);
    final color = _colorForType(type);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
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
                    template.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      _readableType(type),
                      if (categoryName != null) categoryName,
                      if (template.amount != null)
                        '৳${template.amount!.toStringAsFixed(0)}',
                    ].join(' • '),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(LucideIcons.trash2, size: 18),
              color: AppColors.coral,
            ),
          ],
        ),
      ),
    );
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
