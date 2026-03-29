import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:vibration/vibration.dart';

import '../../../core/constants/categories.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/database/app_database.dart';
import '../../../providers/providers.dart';

Future<void> showAddDollarExpenseSheet(
  BuildContext context, {
  DollarExpensesTableData? existingExpense,
}) {
  return showMaterialModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    bounce: true,
    builder: (context) =>
        AddDollarExpenseSheet(existingExpense: existingExpense),
  );
}

class AddDollarExpenseSheet extends ConsumerStatefulWidget {
  const AddDollarExpenseSheet({super.key, this.existingExpense});

  final DollarExpensesTableData? existingExpense;

  @override
  ConsumerState<AddDollarExpenseSheet> createState() =>
      _AddDollarExpenseSheetState();
}

class _AddDollarExpenseSheetState extends ConsumerState<AddDollarExpenseSheet> {
  late final TextEditingController _amountController;
  late final TextEditingController _purposeController;
  DateTime _selectedDate = DateTime.now();
  int? _selectedCategoryId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _purposeController = TextEditingController();

    final expense = widget.existingExpense;
    if (expense != null) {
      _amountController.text = expense.amount.toStringAsFixed(2);
      _purposeController.text = expense.purpose;
      _selectedDate = expense.date;
      _selectedCategoryId = expense.categoryId;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.existingExpense != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoriesAsync = ref.watch(dollarCategoriesProvider);

    return categoriesAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: AppColors.teal)),
      error: (error, stackTrace) => const SizedBox.shrink(),
      data: (categories) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                child: SingleChildScrollView(
                  child: Column(
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
                      Row(
                        children: [
                          Text(
                            _isEditing ? 'Edit Expense' : 'Add Expense',
                            style: theme.textTheme.headlineMedium,
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: _saving
                                ? null
                                : () => Navigator.of(context).pop(),
                            icon: const Icon(LucideIcons.x),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _FieldLabel(label: 'AMOUNT'),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*'),
                          ),
                        ],
                        decoration: const InputDecoration(
                          prefixText: r'$ ',
                          hintText: '184.50',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _FieldLabel(label: 'PURPOSE'),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _purposeController,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Figma subscription',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const _FieldLabel(label: 'CATEGORY'),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _NewCategoryChip(
                            onTap: _saving
                                ? null
                                : () => _createCategory(categories),
                          ),
                          for (final category in categories)
                            _CategoryChip(
                              category: category,
                              selected: _selectedCategoryId == category.id,
                              onTap: _saving
                                  ? null
                                  : () => setState(() {
                                      _selectedCategoryId = category.id;
                                    }),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _FieldLabel(label: 'DATE'),
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: _saving ? null : _pickDate,
                        borderRadius: BorderRadius.circular(16),
                        child: Ink(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                formatShortDate(_selectedDate),
                                style: theme.textTheme.bodyMedium,
                              ),
                              const Spacer(),
                              const Icon(LucideIcons.calendarDays, size: 18),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _saving ? null : _saveExpense,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.teal,
                            foregroundColor: AppColors.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(_isEditing ? 'Update' : 'Save'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked == null) return;
    setState(() {
      _selectedDate = picked;
    });
  }

  Future<void> _createCategory(List<CategoriesTableData> existing) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New Category'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(hintText: 'Software'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (!mounted || name == null || name.isEmpty) return;
    if (existing.any(
      (category) => category.name.toLowerCase() == name.toLowerCase(),
    )) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Category already exists')));
      return;
    }

    final appearance = _guessDollarCategoryAppearance(name);
    final categoryId = await ref
        .read(categoryRepositoryProvider)
        .createCategory(
          CategoriesTableCompanion.insert(
            name: name,
            icon: appearance.iconKey,
            color: appearance.colorValue,
            isPredefined: const drift.Value(false),
            isDollarCategory: const drift.Value(true),
          ),
        );

    if (!mounted) return;
    setState(() {
      _selectedCategoryId = categoryId;
    });
  }

  Future<void> _saveExpense() async {
    final amount = double.tryParse(_amountController.text.trim());
    final purpose = _purposeController.text.trim();

    if (amount == null ||
        amount <= 0 ||
        purpose.isEmpty ||
        _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter amount, purpose, and category.')),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    final messenger = ScaffoldMessenger.of(context);

    try {
      final repository = ref.read(dollarTrackerRepositoryProvider);
      if (_isEditing) {
        final existing = widget.existingExpense!;
        await repository.updateExpense(
          existing.copyWith(
            amount: amount,
            purpose: purpose,
            categoryId: _selectedCategoryId!,
            date: _selectedDate,
          ),
        );
      } else {
        await repository.createExpense(
          DollarExpensesTableCompanion.insert(
            amount: amount,
            purpose: purpose,
            categoryId: _selectedCategoryId!,
            date: _selectedDate,
          ),
        );
      }

      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        Vibration.vibrate(duration: 30);
      } else {
        HapticFeedback.mediumImpact();
      }

      if (!mounted) return;
      setState(() {
        _saving = false;
      });
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _isEditing ? 'Dollar expense updated' : 'Dollar expense saved',
          ),
        ),
      );
      Navigator.of(context).pop();
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
      });
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to save: ${e.toString()}')),
      );
    }
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label, style: Theme.of(context).textTheme.labelMedium);
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.category,
    required this.selected,
    this.onTap,
  });

  final CategoriesTableData category;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = Color(category.color);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? color : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(iconForCategoryKey(category.icon), size: 14, color: color),
            const SizedBox(width: 8),
            Text(category.name),
          ],
        ),
      ),
    );
  }
}

class _NewCategoryChip extends StatelessWidget {
  const _NewCategoryChip({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.teal.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.teal.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.plus, size: 14, color: AppColors.teal),
            const SizedBox(width: 8),
            Text(
              'New Category',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.teal,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DollarCategoryAppearance {
  const _DollarCategoryAppearance({
    required this.iconKey,
    required this.colorValue,
  });

  final String iconKey;
  final int colorValue;
}

_DollarCategoryAppearance _guessDollarCategoryAppearance(String name) {
  final key = name.toLowerCase();
  if (key.contains('tuition') || key.contains('school')) {
    return const _DollarCategoryAppearance(
      iconKey: 'school',
      colorValue: 0xFFFBBF24,
    );
  }
  if (key.contains('software') ||
      key.contains('saas') ||
      key.contains('figma')) {
    return const _DollarCategoryAppearance(
      iconKey: 'monitor',
      colorValue: 0xFF60A5FA,
    );
  }
  if (key.contains('course') || key.contains('book')) {
    return const _DollarCategoryAppearance(
      iconKey: 'book',
      colorValue: 0xFF34D399,
    );
  }
  if (key.contains('hardware') || key.contains('device')) {
    return const _DollarCategoryAppearance(
      iconKey: 'cpu',
      colorValue: 0xFFFF6B6B,
    );
  }
  if (key.contains('travel')) {
    return const _DollarCategoryAppearance(
      iconKey: 'globe',
      colorValue: 0xFF9C7CFF,
    );
  }
  return const _DollarCategoryAppearance(
    iconKey: 'briefcase',
    colorValue: 0xFF00E5BF,
  );
}
