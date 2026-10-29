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
    final mainCategories =
        ref.watch(categoriesProvider).valueOrNull ?? const [];
    final dollarCategories =
        ref.watch(dollarCategoriesProvider).valueOrNull ?? const [];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            32,
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
                  icon: const Icon(
                    LucideIcons.plus,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Expense categories',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            for (final cat in mainCategories)
              _CategoryTile(
                category: cat,
                onTap: cat.isPredefined
                    ? null
                    : () =>
                          _openEditor(context, existing: cat, isDollar: false),
                onDelete: cat.isPredefined
                    ? null
                    : () => _confirmDelete(context, ref, cat, mainCategories),
              ),
            const SizedBox(height: 24),
            Row(
              children: [
                Text(
                  'Dollar categories',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _openEditor(context, isDollar: true),
                  icon: const Icon(
                    LucideIcons.plus,
                    color: AppColors.textPrimary,
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
                      : () =>
                            _confirmDelete(context, ref, cat, dollarCategories),
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
    List<CategoriesTableData> sameTracker,
  ) async {
    final db = ref.read(appDatabaseProvider);
    final inUse = await db.categoryDao.usageCount(category.id);
    if (!context.mounted) return;
    final targets = sameTracker.where((c) => c.id != category.id).toList();

    // `(true, id)`: delete, moving its rows to `id` (null = uncategorized).
    final choice = await showDialog<(bool, int?)>(
      context: context,
      builder: (ctx) => _DeleteCategoryDialog(
        category: category,
        inUse: inUse,
        targets: targets,
      ),
    );

    if (choice == null || !choice.$1) return;

    await db.categoryDao.deleteCategory(category.id, moveTo: choice.$2);

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('"${category.name}" deleted')));
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
    final color = categoryColor(category.color);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.zero,
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight.withValues(alpha: 0.6),
              borderRadius: BorderRadius.zero,
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
                    color: AppColors.spend,
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
            'Icon',
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.textTertiary,
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
            'Colour',
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.textTertiary,
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

class _DeleteCategoryDialog extends StatefulWidget {
  const _DeleteCategoryDialog({
    required this.category,
    required this.inUse,
    required this.targets,
  });

  final CategoriesTableData category;
  final int inUse;
  final List<CategoriesTableData> targets;

  @override
  State<_DeleteCategoryDialog> createState() => _DeleteCategoryDialogState();
}

class _DeleteCategoryDialogState extends State<_DeleteCategoryDialog> {
  int? _moveTo;

  @override
  Widget build(BuildContext context) {
    final n = widget.inUse;
    return AlertDialog(
      backgroundColor: AppColors.surfaceLight,
      title: const Text('Delete category?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            n == 0
                ? 'Remove "${widget.category.name}"? Nothing uses it.'
                : 'Remove "${widget.category.name}"? $n '
                      'entr${n == 1 ? 'y uses' : 'ies use'} it.',
          ),
          if (n > 0 && widget.targets.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<int?>(
              initialValue: _moveTo,
              isExpanded: true,
              dropdownColor: AppColors.surfaceLight,
              decoration: const InputDecoration(labelText: 'Move them to'),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Leave uncategorized'),
                ),
                for (final target in widget.targets)
                  DropdownMenuItem(value: target.id, child: Text(target.name)),
              ],
              onChanged: (value) => setState(() => _moveTo = value),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop((true, _moveTo)),
          style: FilledButton.styleFrom(backgroundColor: AppColors.spend),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
