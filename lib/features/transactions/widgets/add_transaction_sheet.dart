import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spendsplit/core/icons/lucide_icons.dart';

import '../../../core/constants/categories.dart';
import '../../../core/constants/enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/grid_paper.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/input_formatters.dart';
import '../../../data/database/app_database.dart';
import '../../../providers/providers.dart';
import 'template_picker_sheet.dart';

Future<void> showAddTransactionSheet(
  BuildContext context, {
  TransactionsTableData? existingTransaction,
  TransactionTemplatesTableData? fromTemplate,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    builder: (context) => AddTransactionSheet(
      existingTransaction: existingTransaction,
      fromTemplate: fromTemplate,
    ),
  );
}

enum _TransactionEntryType { expense, income, savings }

enum _SavingsFlowType { deposit, withdrawal }

class AddTransactionSheet extends ConsumerStatefulWidget {
  const AddTransactionSheet({
    super.key,
    this.existingTransaction,
    this.fromTemplate,
  });

  final TransactionsTableData? existingTransaction;
  final TransactionTemplatesTableData? fromTemplate;

  @override
  ConsumerState<AddTransactionSheet> createState() =>
      _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  _TransactionEntryType _entryType = _TransactionEntryType.expense;
  _SavingsFlowType _savingsFlowType = _SavingsFlowType.deposit;
  int? _selectedCategoryId;
  int? _selectedSavingsGoalId;
  String _selectedIncomeSource = IncomeSource.salary.dbValue;
  DateTime _selectedDate = DateTime.now();
  bool _saving = false;
  bool _didAutoSelectCategory = false;

  /// Template the form was filled from; its use count goes up on save, so
  /// opening and cancelling doesn't skew the quick-apply chips.
  int? _appliedTemplateId;

  static const _incomeSources = [
    IncomeSource.salary,
    IncomeSource.freelance,
    IncomeSource.other,
  ];

  @override
  void initState() {
    super.initState();
    final transaction = widget.existingTransaction;
    if (transaction != null) {
      _selectedDate = transaction.date;
      _amountController.text = transaction.amount.toStringAsFixed(2);
      _noteController.text = transaction.note ?? '';
      _selectedCategoryId = transaction.categoryId;
      _selectedSavingsGoalId = transaction.savingsGoalId;
      _selectedIncomeSource = transaction.source ?? IncomeSource.salary.dbValue;
      _didAutoSelectCategory = true; // don't override edited category

      final type = TransactionType.fromDbValue(transaction.type);
      switch (type) {
        case TransactionType.income:
          _entryType = _TransactionEntryType.income;
        case TransactionType.expense:
          _entryType = _TransactionEntryType.expense;
        case TransactionType.savingsDeposit:
          _entryType = _TransactionEntryType.savings;
          _savingsFlowType = _SavingsFlowType.deposit;
        case TransactionType.savingsWithdrawal:
          _entryType = _TransactionEntryType.savings;
          _savingsFlowType = _SavingsFlowType.withdrawal;
      }
    } else if (widget.fromTemplate != null) {
      final tpl = widget.fromTemplate!;
      if (tpl.amount != null) {
        _amountController.text = tpl.amount!.toStringAsFixed(2);
      }
      _noteController.text = tpl.note ?? '';
      _selectedCategoryId = tpl.categoryId;
      _didAutoSelectCategory = true;
      switch (TransactionType.fromDbValue(tpl.type)) {
        case TransactionType.income:
          _entryType = _TransactionEntryType.income;
          _selectedIncomeSource = tpl.source ?? IncomeSource.salary.dbValue;
        case TransactionType.expense:
          _entryType = _TransactionEntryType.expense;
        case TransactionType.savingsDeposit:
          _entryType = _TransactionEntryType.savings;
          _savingsFlowType = _SavingsFlowType.deposit;
        case TransactionType.savingsWithdrawal:
          _entryType = _TransactionEntryType.savings;
          _savingsFlowType = _SavingsFlowType.withdrawal;
      }
      _appliedTemplateId = tpl.id;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.existingTransaction != null;

  Color get _accentColor => switch (_entryType) {
    _TransactionEntryType.expense => AppColors.spend,
    _TransactionEntryType.income => AppColors.income,
    _TransactionEntryType.savings => AppColors.savings,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoriesAsync = ref.watch(categoriesProvider);
    final categories =
        categoriesAsync.valueOrNull ?? const <CategoriesTableData>[];
    final goalsAsync = ref.watch(savingsGoalsProvider);
    final openGoals =
        (goalsAsync.valueOrNull ?? const <SavingsGoalsTableData>[])
            .where(
              (goal) =>
                  !goal.isCompleted ||
                  goal.id == widget.existingTransaction?.savingsGoalId,
            )
            .toList();

    // Loading is not evidence that a goal was deleted. Preserve edited links,
    // including completed goals, until the stream has resolved.
    if (goalsAsync.hasValue &&
        _selectedSavingsGoalId != null &&
        !openGoals.any((g) => g.id == _selectedSavingsGoalId)) {
      _selectedSavingsGoalId = null;
    }

    _syncInitialCategory(categories);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.92,
          ),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 36,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.outlineVariant,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 4, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _isEditing ? 'Edit entry' : 'New entry',
                            style: theme.textTheme.titleLarge,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close',
                          onPressed: _saving
                              ? null
                              : () => Navigator.of(context).pop(),
                          icon: const Icon(LucideIcons.x),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    child: _TypeSelector(
                      value: _entryType,
                      onChanged: _saving
                          ? null
                          : (value) {
                              setState(() {
                                _entryType = value;
                              });
                            },
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- Amount: the sheet's one hero figure ---
                          Text('Amount', style: theme.textTheme.titleSmall),
                          const SizedBox(height: 4),
                          CustomPaint(
                            painter: const GridPaperPainter(cell: 5.6),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 11.2,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    '৳',
                                    style: theme.textTheme.displayMedium
                                        ?.copyWith(
                                          color: _accentColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: _amountController,
                                      enabled: !_saving,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      inputFormatters: [
                                        DecimalTextInputFormatter(
                                          maxDecimalPlaces: 2,
                                        ),
                                      ],
                                      style: AppTypography.figure(56),
                                      decoration: InputDecoration(
                                        hintText: '0',
                                        hintStyle: AppTypography.figure(
                                          56,
                                          color: AppColors.textTertiary,
                                        ),
                                        filled: false,
                                        border: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        isDense: true,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // --- From template + most-used chips ---
                          if (!_isEditing)
                            Builder(
                              builder: (context) {
                                final chips = ref.watch(
                                  mostUsedTemplatesProvider,
                                );
                                return Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      for (final tpl in chips)
                                        _SquareChip(
                                          label: tpl.name,
                                          selected: false,
                                          onTap: _saving
                                              ? null
                                              : () => _useTemplate(tpl),
                                        ),
                                      TextButton.icon(
                                        onPressed: _saving
                                            ? null
                                            : () =>
                                                  _openTemplatePicker(context),
                                        icon: const Icon(
                                          LucideIcons.layoutTemplate,
                                          size: 16,
                                        ),
                                        label: const Text('From template'),
                                        style: TextButton.styleFrom(
                                          foregroundColor:
                                              AppColors.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          const SizedBox(height: 24),
                          categoriesAsync.when(
                            data: (items) => _AdaptiveSection(
                              entryType: _entryType,
                              categories: items,
                              selectedCategoryId: _selectedCategoryId,
                              openGoals: openGoals,
                              selectedSavingsGoalId: _selectedSavingsGoalId,
                              selectedIncomeSource: _selectedIncomeSource,
                              savingsFlowType: _savingsFlowType,
                              onCategorySelected: (value) {
                                setState(() {
                                  _selectedCategoryId = value;
                                });
                              },
                              onAddCustomCategory: _saving
                                  ? null
                                  : () => _createCustomCategory(context),
                              onIncomeSourceSelected: (value) {
                                setState(() {
                                  _selectedIncomeSource = value;
                                });
                              },
                              onSavingsFlowSelected: (value) {
                                setState(() {
                                  _savingsFlowType = value;
                                });
                              },
                              onSavingsGoalSelected: (value) {
                                setState(() {
                                  _selectedSavingsGoalId = value;
                                });
                              },
                            ),
                            loading: () => const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            error: (error, _) => Text(
                              "Categories couldn't load. Close the sheet and try again.",
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _InfoRow(
                            icon: LucideIcons.calendar,
                            label: 'Date',
                            value: formatSheetDate(_selectedDate),
                            onTap: _saving ? null : _pickDate,
                          ),
                          const SizedBox(height: 8),
                          _NoteField(
                            controller: _noteController,
                            enabled: !_saving,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: FilledButton(
                      onPressed: _saving ? null : _saveTransaction,
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.onPrimary,
                              ),
                            )
                          : Text(_isEditing ? 'Update' : 'Save'),
                    ),
                  ),
                  if (!_isEditing)
                    TextButton.icon(
                      onPressed: _saving
                          ? null
                          : () => _saveAsTemplate(context),
                      icon: const Icon(LucideIcons.bookmark, size: 15),
                      label: const Text('Save as template'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.onSurfaceVariant,
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

  /// Auto-select the first category for new expense entries once categories
  /// have loaded. Runs once and sets a synchronous guard to avoid repeat
  /// scheduling from subsequent builds.
  void _syncInitialCategory(List<CategoriesTableData> categories) {
    if (_didAutoSelectCategory) return;
    if (categories.isEmpty) return;
    if (_entryType != _TransactionEntryType.expense) return;

    _didAutoSelectCategory = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _selectedCategoryId = categories.first.id;
      });
    });
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: AppColors.accent),
          ),
          child: child!,
        );
      },
    );

    if (selected == null) return;

    setState(() {
      _selectedDate = onDayKeepingTime(selected, _selectedDate);
    });
  }

  Future<void> _createCustomCategory(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const _CategoryNameDialog(hintText: 'Category name'),
    );

    if (!mounted || name == null || name.isEmpty) return;

    // Pick a color from the palette based on existing custom category count
    final existingCategories =
        ref.read(categoriesProvider).valueOrNull ?? const [];
    final customCount = existingCategories.where((c) => !c.isPredefined).length;
    final color =
        CategoryColors.swatches[customCount % CategoryColors.swatches.length];

    try {
      final categoryId = await ref
          .read(categoryRepositoryProvider)
          .createCategory(
            CategoriesTableCompanion.insert(
              name: name,
              icon: 'category',
              color: color,
              isPredefined: const Value(false),
              isDollarCategory: const Value(false),
            ),
          );

      if (!mounted) return;
      setState(() {
        _selectedCategoryId = categoryId;
      });
    } on Exception {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Category already exists or could not be created'),
        ),
      );
    }
  }

  Future<void> _saveTransaction() async {
    if (_saving) return;
    final messenger = ScaffoldMessenger.of(context);
    final amount = double.tryParse(_amountController.text.replaceAll(',', ''));

    if (amount == null || !amount.isFinite || amount <= 0) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }

    if (_entryType == _TransactionEntryType.expense &&
        _selectedCategoryId == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Select a category')),
      );
      return;
    }

    final transactionType = switch (_entryType) {
      _TransactionEntryType.expense => TransactionType.expense,
      _TransactionEntryType.income => TransactionType.income,
      _TransactionEntryType.savings =>
        _savingsFlowType == _SavingsFlowType.deposit
            ? TransactionType.savingsDeposit
            : TransactionType.savingsWithdrawal,
    };

    final nextSavingsGoalId = _entryType == _TransactionEntryType.savings
        ? _selectedSavingsGoalId
        : null;
    final goalAdjustments = _goalAdjustmentsForSave(
      existingTransaction: widget.existingTransaction,
      nextGoalId: nextSavingsGoalId,
      nextType: transactionType,
      nextAmount: amount,
    );

    setState(() {
      _saving = true;
    });

    try {
      final companion = TransactionsTableCompanion(
        type: Value(transactionType.dbValue),
        amount: Value(amount),
        categoryId: Value(
          _entryType == _TransactionEntryType.expense
              ? _selectedCategoryId
              : null,
        ),
        source: Value(
          _entryType == _TransactionEntryType.income
              ? _selectedIncomeSource
              : null,
        ),
        savingsGoalId: Value(nextSavingsGoalId),
        note: Value(
          _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
        ),
        date: Value(_selectedDate),
      );

      final repository = ref.read(transactionRepositoryProvider);
      final savingsRepository = ref.read(savingsRepositoryProvider);
      final templateRepository = ref.read(
        transactionTemplateRepositoryProvider,
      );
      final appliedTemplateId = _isEditing ? null : _appliedTemplateId;
      await ref.read(appDatabaseProvider).transaction(() async {
        if (_isEditing) {
          final existing = widget.existingTransaction!;
          await repository.updateTransaction(
            existing.copyWith(
              type: transactionType.dbValue,
              amount: amount,
              categoryId: Value(
                _entryType == _TransactionEntryType.expense
                    ? _selectedCategoryId
                    : null,
              ),
              savingsGoalId: Value(nextSavingsGoalId),
              source: Value(
                _entryType == _TransactionEntryType.income
                    ? _selectedIncomeSource
                    : null,
              ),
              note: Value(
                _noteController.text.trim().isEmpty
                    ? null
                    : _noteController.text.trim(),
              ),
              date: _selectedDate,
              // Saving counts as reviewed, even with no changes.
              needsReview: false,
            ),
          );
        } else {
          await repository.createTransaction(companion);
        }

        for (final entry in goalAdjustments.entries) {
          if (entry.value.abs() < 1e-9) continue;
          final updated = await savingsRepository.adjustGoalAmountBy(
            entry.key,
            entry.value,
          );
          if (!updated) {
            throw StateError(
              'The goal changed or has insufficient savings. Please review and try again.',
            );
          }
        }
        if (appliedTemplateId != null) {
          await templateRepository.markUsed(appliedTemplateId);
        }
      });

      HapticFeedback.mediumImpact();
      if (!mounted) return;

      // Reset saving state before pop to avoid setState-after-dispose
      setState(() {
        _saving = false;
      });

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _isEditing ? 'Transaction updated' : 'Transaction saved',
          ),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to save: ${e.toString()}')),
      );
      setState(() {
        _saving = false;
      });
    }
  }

  Future<void> _openTemplatePicker(BuildContext context) async {
    final templates =
        ref.read(transactionTemplatesProvider).valueOrNull ?? const [];
    if (templates.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No templates saved yet.')));
      return;
    }

    final categories =
        ref.read(categoriesProvider).valueOrNull ??
        const <CategoriesTableData>[];
    final catMap = {for (final c in categories) c.id: c};

    final selected = await showTemplatePickerSheet(
      context,
      templates: templates,
      categoriesById: catMap,
      onDelete: (id) => ref
          .read(transactionTemplateRepositoryProvider)
          .deleteTemplateById(id),
    );

    if (selected == null || !mounted) return;
    _useTemplate(selected);
  }

  void _useTemplate(TransactionTemplatesTableData template) {
    _appliedTemplateId = template.id;
    _applyTemplate(template);
  }

  void _applyTemplate(TransactionTemplatesTableData template) {
    setState(() {
      if (template.amount != null) {
        _amountController.text = template.amount!.toStringAsFixed(2);
      }
      _noteController.text = template.note ?? '';
      _selectedCategoryId = template.categoryId;
      _selectedSavingsGoalId = null;
      _didAutoSelectCategory = true;
      final type = TransactionType.fromDbValue(template.type);
      switch (type) {
        case TransactionType.income:
          _entryType = _TransactionEntryType.income;
          _selectedIncomeSource =
              template.source ?? IncomeSource.salary.dbValue;
        case TransactionType.expense:
          _entryType = _TransactionEntryType.expense;
        case TransactionType.savingsDeposit:
          _entryType = _TransactionEntryType.savings;
          _savingsFlowType = _SavingsFlowType.deposit;
        case TransactionType.savingsWithdrawal:
          _entryType = _TransactionEntryType.savings;
          _savingsFlowType = _SavingsFlowType.withdrawal;
      }
    });
  }

  Future<void> _saveAsTemplate(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final nameController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        title: const Text('Save Template'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Template name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final name = nameController.text.trim();
    if (name.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Give the template a name')),
      );
      return;
    }

    final type = switch (_entryType) {
      _TransactionEntryType.expense => TransactionType.expense,
      _TransactionEntryType.income => TransactionType.income,
      _TransactionEntryType.savings =>
        _savingsFlowType == _SavingsFlowType.deposit
            ? TransactionType.savingsDeposit
            : TransactionType.savingsWithdrawal,
    };
    final amount = double.tryParse(_amountController.text);

    await ref
        .read(transactionTemplateRepositoryProvider)
        .createTemplate(
          TransactionTemplatesTableCompanion.insert(
            name: name,
            type: type.dbValue,
            amount: Value(amount),
            categoryId: Value(
              _entryType == _TransactionEntryType.expense
                  ? _selectedCategoryId
                  : null,
            ),
            source: Value(
              _entryType == _TransactionEntryType.income
                  ? _selectedIncomeSource
                  : null,
            ),
            note: Value(
              _noteController.text.trim().isNotEmpty
                  ? _noteController.text.trim()
                  : null,
            ),
          ),
        );

    if (!mounted) return;
    messenger.showSnackBar(const SnackBar(content: Text('Template saved')));
  }

  Map<int, double> _goalAdjustmentsForSave({
    required TransactionsTableData? existingTransaction,
    required int? nextGoalId,
    required TransactionType nextType,
    required double nextAmount,
  }) {
    final adjustments = <int, double>{};

    void apply(int? goalId, double delta) {
      if (goalId == null || delta.abs() < 1e-9) return;
      adjustments.update(
        goalId,
        (value) => value + delta,
        ifAbsent: () => delta,
      );
    }

    if (existingTransaction != null) {
      apply(
        existingTransaction.savingsGoalId,
        -_goalLinkedDelta(
          goalId: existingTransaction.savingsGoalId,
          type: TransactionType.fromDbValue(existingTransaction.type),
          amount: existingTransaction.amount,
        ),
      );
    }

    apply(
      nextGoalId,
      _goalLinkedDelta(goalId: nextGoalId, type: nextType, amount: nextAmount),
    );

    adjustments.removeWhere((key, value) => value.abs() < 1e-9);
    return adjustments;
  }

  double _goalLinkedDelta({
    required int? goalId,
    required TransactionType type,
    required double amount,
  }) {
    if (goalId == null) return 0;

    return switch (type) {
      TransactionType.savingsDeposit => amount,
      TransactionType.savingsWithdrawal => -amount,
      _ => 0,
    };
  }
}

class _CategoryNameDialog extends StatefulWidget {
  const _CategoryNameDialog({required this.hintText});

  final String hintText;

  @override
  State<_CategoryNameDialog> createState() => _CategoryNameDialogState();
}

class _CategoryNameDialogState extends State<_CategoryNameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceLight,
      title: const Text('New Category'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(hintText: widget.hintText),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Create'),
        ),
      ],
    );
  }
}

/// Expense / Income / Savings as a segmented control. Neutral like every
/// control; the type's legend colour shows on the ৳ sign instead.
class _TypeSelector extends StatelessWidget {
  const _TypeSelector({required this.value, required this.onChanged});

  final _TransactionEntryType value;
  final ValueChanged<_TransactionEntryType>? onChanged;

  @override
  Widget build(BuildContext context) {
    return _Segmented<_TransactionEntryType>(
      values: _TransactionEntryType.values,
      selected: value,
      onSelected: onChanged,
      label: (t) => switch (t) {
        _TransactionEntryType.expense => 'Expense',
        _TransactionEntryType.income => 'Income',
        _TransactionEntryType.savings => 'Savings',
      },
    );
  }
}

/// A square segmented control: one module, the selected segment inverted
/// to ink.
class _Segmented<T> extends StatelessWidget {
  const _Segmented({
    required this.values,
    required this.selected,
    required this.onSelected,
    required this.label,
  });

  final List<T> values;
  final T selected;
  final ValueChanged<T>? onSelected;
  final String Function(T value) label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: AppDecorations.module(color: AppColors.surface),
      child: Row(
        children: [
          for (final v in values)
            Expanded(
              child: Semantics(
                selected: v == selected,
                button: true,
                child: Material(
                  color: v == selected
                      ? AppColors.textPrimary
                      : Colors.transparent,
                  borderRadius: BorderRadius.zero,
                  child: InkWell(
                    borderRadius: BorderRadius.zero,
                    onTap: onSelected == null ? null : () => onSelected!(v),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 38),
                      child: Center(
                        child: Text(
                          label(v),
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: v == selected
                                ? AppColors.background
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AdaptiveSection extends StatelessWidget {
  const _AdaptiveSection({
    required this.entryType,
    required this.categories,
    required this.selectedCategoryId,
    required this.openGoals,
    required this.selectedSavingsGoalId,
    required this.selectedIncomeSource,
    required this.savingsFlowType,
    required this.onCategorySelected,
    required this.onAddCustomCategory,
    required this.onIncomeSourceSelected,
    required this.onSavingsFlowSelected,
    required this.onSavingsGoalSelected,
  });

  final _TransactionEntryType entryType;
  final List<CategoriesTableData> categories;
  final int? selectedCategoryId;
  final List<SavingsGoalsTableData> openGoals;
  final int? selectedSavingsGoalId;
  final String selectedIncomeSource;
  final _SavingsFlowType savingsFlowType;
  final ValueChanged<int> onCategorySelected;
  final VoidCallback? onAddCustomCategory;
  final ValueChanged<String> onIncomeSourceSelected;
  final ValueChanged<_SavingsFlowType> onSavingsFlowSelected;
  final ValueChanged<int?> onSavingsGoalSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (entryType == _TransactionEntryType.expense) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Category', style: theme.textTheme.titleSmall),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final category in categories) ...[
                  _CategoryChip(
                    label: category.name,
                    icon: _iconForCategory(category.icon),
                    color: categoryColor(category.color),
                    selected: selectedCategoryId == category.id,
                    onTap: () => onCategorySelected(category.id),
                  ),
                  const SizedBox(width: 8),
                ],
                _CustomCategoryChip(onTap: onAddCustomCategory),
              ],
            ),
          ),
        ],
      );
    }

    if (entryType == _TransactionEntryType.income) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Source', style: theme.textTheme.titleSmall),
          const SizedBox(height: 10),
          _Segmented<IncomeSource>(
            values: _AddTransactionSheetState._incomeSources,
            selected: _incomeSourcesByDbValue(selectedIncomeSource),
            onSelected: (value) => onIncomeSourceSelected(value.dbValue),
            label: (value) => switch (value) {
              IncomeSource.salary => 'Salary',
              IncomeSource.freelance => 'Freelance',
              IncomeSource.other => 'Other',
            },
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Direction', style: theme.textTheme.titleSmall),
        const SizedBox(height: 10),
        _Segmented<_SavingsFlowType>(
          values: const [_SavingsFlowType.deposit, _SavingsFlowType.withdrawal],
          selected: savingsFlowType,
          onSelected: onSavingsFlowSelected,
          label: (value) => value == _SavingsFlowType.deposit
              ? 'Into savings'
              : 'Out of savings',
        ),
        const SizedBox(height: 24),
        Text('Goal', style: theme.textTheme.titleSmall),
        const SizedBox(height: 10),
        if (openGoals.isEmpty)
          Text(
            'No open goals. Create one on the Goals tab to link savings to it.',
            style: theme.textTheme.bodyMedium,
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SquareChip(
                label: 'None',
                selected: selectedSavingsGoalId == null,
                onTap: () => onSavingsGoalSelected(null),
              ),
              for (final goal in openGoals)
                _SquareChip(
                  label: goal.name,
                  selected: selectedSavingsGoalId == goal.id,
                  onTap: () => onSavingsGoalSelected(goal.id),
                ),
            ],
          ),
      ],
    );
  }

  IncomeSource _incomeSourcesByDbValue(String value) {
    return IncomeSource.values.firstWhere(
      (source) => source.dbValue == value,
      orElse: () => IncomeSource.salary,
    );
  }
}

/// A square chip, inverted to ink when selected.
class _SquareChip extends StatelessWidget {
  const _SquareChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? AppColors.textPrimary : AppColors.surface,
        borderRadius: BorderRadius.circular(AppDecorations.radius),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDecorations.radius),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: selected
                      ? AppColors.background
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDecorations.radius),
        child: SizedBox(
          width: 72,
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: selected ? AppColors.surfaceRaised : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDecorations.radius),
                  border: Border.all(
                    color: selected ? color : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Icon(
                  icon,
                  color: selected ? color : AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: selected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomCategoryChip extends StatelessWidget {
  const _CustomCategoryChip({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'New category',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDecorations.radius),
        child: SizedBox(
          width: 72,
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: AppDecorations.module(),
                child: const Icon(
                  LucideIcons.plus,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Text('New', style: Theme.of(context).textTheme.labelMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppDecorations.radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDecorations.radius),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.textSecondary),
              const SizedBox(width: 12),
              Text(label, style: theme.textTheme.bodyLarge),
              const Spacer(),
              Text(value, style: theme.textTheme.bodyMedium),
              const SizedBox(width: 4),
              const Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoteField extends StatelessWidget {
  const _NoteField({required this.controller, required this.enabled});

  final TextEditingController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      maxLines: 1,
      textCapitalization: TextCapitalization.sentences,
      decoration: const InputDecoration(
        hintText: 'Note (optional): what was this for?',
        fillColor: AppColors.surface,
        prefixIcon: Icon(LucideIcons.pencil, size: 18),
      ),
    );
  }
}

IconData _iconForCategory(String iconName) {
  switch (iconName) {
    case 'restaurant':
      return LucideIcons.utensils;
    case 'directions_car':
      return LucideIcons.car;
    case 'bolt':
      return LucideIcons.zap;
    case 'local_hospital':
      return LucideIcons.heartPulse;
    case 'shopping_bag':
      return LucideIcons.shoppingBag;
    case 'more_horiz':
      return LucideIcons.moreHorizontal;
    default:
      return LucideIcons.tag;
  }
}
