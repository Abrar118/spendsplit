import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/categories.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/database/app_database.dart';
import '../../../providers/providers.dart';

class ManageCategoriesScreen extends ConsumerWidget {
  const ManageCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final mainCategories = ref.watch(categoriesProvider).valueOrNull ?? const [];
    final dollarCategories =
        ref.watch(dollarCategoriesProvider).valueOrNull ?? const [];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: ListView(
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
                Text('Manage Categories', style: theme.textTheme.titleLarge),
                const Spacer(),
                IconButton(
                  onPressed: () => _addCategory(context, ref, isDollar: false),
                  icon: const Icon(LucideIcons.plus, color: AppColors.teal),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'EXPENSE CATEGORIES',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 12),
            for (final cat in mainCategories)
              _CategoryTile(
                category: cat,
                onDelete: cat.isPredefined
                    ? null
                    : () => _confirmDelete(context, ref, cat),
              ),
            const SizedBox(height: 24),
            Row(
              children: [
                Text(
                  'DOLLAR CATEGORIES',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _addCategory(context, ref, isDollar: true),
                  icon: const Icon(LucideIcons.plus, color: AppColors.teal, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (dollarCategories.isNotEmpty) ...[
              for (final cat in dollarCategories)
                _CategoryTile(
                  category: cat,
                  onDelete: cat.isPredefined
                      ? null
                      : () => _confirmDelete(context, ref, cat),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _addCategory(
    BuildContext context,
    WidgetRef ref, {
    required bool isDollar,
  }) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        title: Text('New ${isDollar ? 'Dollar' : 'Expense'} Category'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Category name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    final enteredName = name;

    try {
      await ref.read(appDatabaseProvider).categoryDao.insertCategory(
        CategoriesTableCompanion.insert(
          name: enteredName,
          icon: 'category',
          color: isDollar ? AppColors.teal.toARGB32() : AppColors.blue.toARGB32(),
          isPredefined: const Value(false),
          isDollarCategory: Value(isDollar),
        ),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"$enteredName" created')),
        );
      }
    } on Exception {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category already exists')),
        );
      }
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    CategoriesTableData category,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        title: const Text('Delete category?'),
        content: Text(
          'Remove "${category.name}"? Transactions using it will show as "Uncategorized".',
        ),
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
        .read(appDatabaseProvider)
        .categoryDao
        .deleteCategory(category.id);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${category.name}" deleted')),
      );
    }
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, this.onDelete});

  final CategoriesTableData category;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = Color(category.color);
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
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(
                iconForCategoryKey(category.icon),
                color: color,
                size: 18,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(category.name, style: theme.textTheme.titleSmall),
                  if (category.isPredefined)
                    Text(
                      'Built-in',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                ],
              ),
            ),
            if (onDelete != null)
              IconButton(
                onPressed: onDelete,
                icon: const Icon(LucideIcons.trash2, size: 18),
                color: AppColors.coral,
              )
            else
              Icon(
                LucideIcons.lock,
                size: 16,
                color: Colors.white.withValues(alpha: 0.2),
              ),
          ],
        ),
      ),
    );
  }
}
