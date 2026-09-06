import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spendsplit/core/icons/lucide_icons.dart';

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
                  onPressed: () => _openEditor(context, isDollar: false),
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
                onTap: cat.isPredefined
                    ? null
                    : () => _openEditor(context, existing: cat, isDollar: false),
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
                  onPressed: () => _openEditor(context, isDollar: true),
                  icon: const Icon(
                    LucideIcons.plus,
                    color: AppColors.teal,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (dollarCategories.isNotEmpty) ...[
              for (final cat in dollarCategories)
                _CategoryTile(
                  category: cat,
                  onTap: cat.isPredefined
                      ? null
                      : () =>
                            _openEditor(context, existing: cat, isDollar: true),
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

  Future<void> _openEditor(
    BuildContext context, {
    CategoriesTableData? existing,
    required bool isDollar,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (_) =>
          _CategoryEditorSheet(existing: existing, isDollar: isDollar),
    );
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

    final db = ref.read(appDatabaseProvider);
    await db.categoryDao.deleteCategory(category.id);
    await db.categoryBudgetDao.clearBudget(category.id);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${category.name}" deleted')),
      );
    }
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, this.onTap, this.onDelete});

  final CategoriesTableData category;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = Color(category.color);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
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
        ),
      ),
    );
  }
}

class _CategoryEditorSheet extends ConsumerStatefulWidget {
  const _CategoryEditorSheet({this.existing, required this.isDollar});

  /// Null = create mode.
  final CategoriesTableData? existing;
  final bool isDollar;

  @override
  ConsumerState<_CategoryEditorSheet> createState() =>
      _CategoryEditorSheetState();
}

class _CategoryEditorSheetState extends ConsumerState<_CategoryEditorSheet> {
  late final TextEditingController _name = TextEditingController(
    text: widget.existing?.name ?? '',
  );
  late String _iconKey = widget.existing?.icon ?? CategoryIcons.all.first.key;
  late int _color = widget.existing?.color ?? CategoryColors.swatches.first;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Enter a name.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final dao = ref.read(appDatabaseProvider).categoryDao;
    try {
      if (widget.existing == null) {
        await dao.insertCategory(
          CategoriesTableCompanion.insert(
            name: name,
            icon: _iconKey,
            color: _color,
            isPredefined: const Value(false),
            isDollarCategory: Value(widget.isDollar),
          ),
        );
      } else {
        await dao.updateCategory(
          id: widget.existing!.id,
          name: name,
          icon: _iconKey,
          color: _color,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } on Exception {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'A category with that name already exists.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.existing == null ? 'New category' : 'Edit category',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            autofocus: widget.existing == null,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(labelText: 'Name', errorText: _error),
          ),
          const SizedBox(height: 20),
          Text(
            'ICON',
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.textTertiary,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final option in CategoryIcons.all)
                GestureDetector(
                  onTap: () => setState(() => _iconKey = option.key),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _iconKey == option.key
                          ? Color(_color).withValues(alpha: 0.22)
                          : AppColors.surfaceLight,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      option.icon,
                      size: 20,
                      color: _iconKey == option.key
                          ? Color(_color)
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'COLOUR',
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.textTertiary,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final swatch in CategoryColors.swatches)
                GestureDetector(
                  onTap: () => setState(() => _color = swatch),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Color(swatch),
                      shape: BoxShape.circle,
                      border: _color == swatch
                          ? Border.all(color: Colors.white, width: 2)
                          : null,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving…' : 'Save'),
            ),
          ),
        ],
      ),
    );
  }
}
