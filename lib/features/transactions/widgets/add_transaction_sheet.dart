import 'dart:ui';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

import '../../../core/constants/enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/database/app_database.dart';
import '../../../providers/providers.dart';

Future<void> showAddTransactionSheet(
  BuildContext context, {
  TransactionsTableData? existingTransaction,
}) {
  return showMaterialModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    expand: false,
    bounce: true,
    builder: (context) =>
        AddTransactionSheet(existingTransaction: existingTransaction),
  );
}

enum _TransactionEntryType { expense, income, savings }

enum _SavingsFlowType { deposit, withdrawal }

class AddTransactionSheet extends ConsumerStatefulWidget {
  const AddTransactionSheet({super.key, this.existingTransaction});

  final TransactionsTableData? existingTransaction;

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
  String _selectedIncomeSource = IncomeSource.salary.dbValue;
  DateTime _selectedDate = DateTime.now();
  bool _saving = false;
  bool _didInitializeFromExisting = false;

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
      _selectedIncomeSource = transaction.source ?? IncomeSource.salary.dbValue;

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
    _TransactionEntryType.expense => AppColors.coral,
    _TransactionEntryType.income => AppColors.green,
    _TransactionEntryType.savings => AppColors.purple,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoriesAsync = ref.watch(categoriesProvider);
    final categories =
        categoriesAsync.valueOrNull ?? const <CategoriesTableData>[];

    _syncInitialCategory(categories);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: FractionallySizedBox(
        heightFactor: 0.86,
        alignment: Alignment.bottomCenter,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF232738).withValues(alpha: 0.92),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(40),
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x80000000),
                    blurRadius: 40,
                    offset: Offset(0, -12),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 14),
                  Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              _isEditing ? 'Edit Entry' : 'New Entry',
                              style: theme.textTheme.headlineMedium,
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: _saving
                                  ? null
                                  : () => Navigator.of(context).pop(),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.05,
                                ),
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.08),
                                ),
                              ),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _TypeSelector(
                          value: _entryType,
                          onChanged: _saving
                              ? null
                              : (value) {
                                  setState(() {
                                    _entryType = value;
                                  });
                                },
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Column(
                              children: [
                                Text(
                                  'ENTER AMOUNT',
                                  style: theme.textTheme.labelMedium,
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '৳',
                                      style: theme.textTheme.headlineLarge
                                          ?.copyWith(
                                            color: _accentColor,
                                            shadows: [
                                              Shadow(
                                                color: _accentColor.withValues(
                                                  alpha: 0.35,
                                                ),
                                                blurRadius: 18,
                                              ),
                                            ],
                                          ),
                                    ),
                                    const SizedBox(width: 8),
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 220,
                                      ),
                                      child: TextField(
                                        controller: _amountController,
                                        enabled: !_saving,
                                        textAlign: TextAlign.center,
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        style: theme.textTheme.displayLarge
                                            ?.copyWith(
                                              fontSize: 48,
                                              color: AppColors.textPrimary,
                                              shadows: [
                                                Shadow(
                                                  color: _accentColor
                                                      .withValues(alpha: 0.28),
                                                  blurRadius: 20,
                                                ),
                                              ],
                                            ),
                                        decoration: const InputDecoration(
                                          hintText: '0.00',
                                          border: InputBorder.none,
                                          isDense: true,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          categoriesAsync.when(
                            data: (items) => _AdaptiveSection(
                              entryType: _entryType,
                              categories: items,
                              selectedCategoryId: _selectedCategoryId,
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
                            ),
                            loading: () => const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: CircularProgressIndicator(
                                  color: AppColors.teal,
                                ),
                              ),
                            ),
                            error: (error, _) => Text(
                              'Could not load categories',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.coral,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          _InfoRow(
                            icon: Icons.calendar_today_rounded,
                            label: 'DATE',
                            value: formatSheetDate(_selectedDate),
                            onTap: _saving ? null : _pickDate,
                          ),
                          const SizedBox(height: 16),
                          _NoteField(
                            controller: _noteController,
                            enabled: !_saving,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: _accentColor,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _saving ? null : _saveTransaction,
                        child: Text(
                          _saving
                              ? 'Saving...'
                              : (_isEditing ? 'Update' : 'Save Transaction'),
                        ),
                      ),
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

  void _syncInitialCategory(List<CategoriesTableData> categories) {
    if (categories.isEmpty) return;

    if (_isEditing && _didInitializeFromExisting) {
      return;
    }

    if (_isEditing) {
      _didInitializeFromExisting = true;
      return;
    }

    if (_selectedCategoryId == null &&
        _entryType == _TransactionEntryType.expense) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _selectedCategoryId = categories.first.id;
        });
      });
    }
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
            ).colorScheme.copyWith(primary: AppColors.teal),
          ),
          child: child!,
        );
      },
    );

    if (selected == null) return;

    setState(() {
      _selectedDate = selected;
    });
  }

  Future<void> _createCustomCategory(BuildContext context) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceLight,
          title: const Text('New Category'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(hintText: 'Category name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(controller.text.trim());
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
    controller.dispose();

    if (!mounted || name == null || name.isEmpty) return;

    final categoryId = await ref
        .read(categoryRepositoryProvider)
        .createCategory(
          CategoriesTableCompanion.insert(
            name: name,
            icon: 'category',
            color: AppColors.catOther.toARGB32(),
            isPredefined: const Value(false),
            isDollarCategory: const Value(false),
          ),
        );

    if (!mounted) return;
    setState(() {
      _selectedCategoryId = categoryId;
    });
  }

  Future<void> _saveTransaction() async {
    final messenger = ScaffoldMessenger.of(context);
    final amount = double.tryParse(_amountController.text.replaceAll(',', ''));

    if (amount == null || amount <= 0) {
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

    setState(() {
      _saving = true;
    });

    try {
      final transactionType = switch (_entryType) {
        _TransactionEntryType.expense => TransactionType.expense,
        _TransactionEntryType.income => TransactionType.income,
        _TransactionEntryType.savings =>
          _savingsFlowType == _SavingsFlowType.deposit
              ? TransactionType.savingsDeposit
              : TransactionType.savingsWithdrawal,
      };

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
        note: Value(
          _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
        ),
        date: Value(_selectedDate),
      );

      final repository = ref.read(transactionRepositoryProvider);

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
          ),
        );
      } else {
        await repository.createTransaction(companion);
      }

      await HapticFeedback.mediumImpact();

      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _isEditing ? 'Transaction updated' : 'Transaction saved',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }
}

class _TypeSelector extends StatelessWidget {
  const _TypeSelector({required this.value, required this.onChanged});

  final _TransactionEntryType value;
  final ValueChanged<_TransactionEntryType>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TypePill(
              label: 'EXPENSE',
              selected: value == _TransactionEntryType.expense,
              color: AppColors.coral,
              onTap: onChanged == null
                  ? null
                  : () => onChanged!(_TransactionEntryType.expense),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _TypePill(
              label: 'INCOME',
              selected: value == _TransactionEntryType.income,
              color: AppColors.green,
              onTap: onChanged == null
                  ? null
                  : () => onChanged!(_TransactionEntryType.income),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _TypePill(
              label: 'SAVINGS',
              selected: value == _TransactionEntryType.savings,
              color: AppColors.purple,
              onTap: onChanged == null
                  ? null
                  : () => onChanged!(_TransactionEntryType.savings),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypePill extends StatelessWidget {
  const _TypePill({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? color : Colors.white.withValues(alpha: 0.08),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.28),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ]
              : const [],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelLarge?.copyWith(
            color: Colors.white.withValues(alpha: selected ? 1 : 0.55),
          ),
        ),
      ),
    );
  }
}

class _AdaptiveSection extends StatelessWidget {
  const _AdaptiveSection({
    required this.entryType,
    required this.categories,
    required this.selectedCategoryId,
    required this.selectedIncomeSource,
    required this.savingsFlowType,
    required this.onCategorySelected,
    required this.onAddCustomCategory,
    required this.onIncomeSourceSelected,
    required this.onSavingsFlowSelected,
  });

  final _TransactionEntryType entryType;
  final List<CategoriesTableData> categories;
  final int? selectedCategoryId;
  final String selectedIncomeSource;
  final _SavingsFlowType savingsFlowType;
  final ValueChanged<int> onCategorySelected;
  final VoidCallback? onAddCustomCategory;
  final ValueChanged<String> onIncomeSourceSelected;
  final ValueChanged<_SavingsFlowType> onSavingsFlowSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (entryType == _TransactionEntryType.expense) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('SELECT CATEGORY', style: theme.textTheme.labelMedium),
              const Spacer(),
              Text(
                'VIEW ALL',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppColors.teal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final category in categories) ...[
                  _CategoryChip(
                    label: category.name,
                    icon: _iconForCategory(category.icon),
                    color: Color(category.color),
                    selected: selectedCategoryId == category.id,
                    onTap: () => onCategorySelected(category.id),
                  ),
                  const SizedBox(width: 14),
                ],
                _CustomCategoryChip(onTap: onAddCustomCategory),
              ],
            ),
          ),
        ],
      );
    }

    if (entryType == _TransactionEntryType.income) {
      return _SegmentSection<IncomeSource>(
        label: 'SOURCE',
        values: _AddTransactionSheetState._incomeSources,
        selectedValue: _incomeSourcesByDbValue(selectedIncomeSource),
        onSelected: (value) => onIncomeSourceSelected(value.dbValue),
        displayText: (value) => switch (value) {
          IncomeSource.salary => 'Salary',
          IncomeSource.freelance => 'Freelance',
          IncomeSource.other => 'Other',
        },
      );
    }

    return _SegmentSection<_SavingsFlowType>(
      label: 'SAVINGS TYPE',
      values: const [_SavingsFlowType.deposit, _SavingsFlowType.withdrawal],
      selectedValue: savingsFlowType,
      onSelected: onSavingsFlowSelected,
      displayText: (value) =>
          value == _SavingsFlowType.deposit ? 'Deposit' : 'Withdrawal',
    );
  }

  IncomeSource _incomeSourcesByDbValue(String value) {
    return IncomeSource.values.firstWhere(
      (source) => source.dbValue == value,
      orElse: () => IncomeSource.salary,
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
    final foreground = selected ? color : Colors.white.withValues(alpha: 0.42);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: selected
                  ? color.withValues(alpha: 0.16)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected
                    ? color.withValues(alpha: 0.32)
                    : Colors.white.withValues(alpha: 0.08),
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.18),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : const [],
            ),
            child: Icon(icon, color: foreground),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: selected
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.42),
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomCategoryChip extends StatelessWidget {
  const _CustomCategoryChip({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: const Icon(Icons.add_rounded, color: AppColors.teal),
          ),
          const SizedBox(height: 10),
          Text(
            'Custom',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentSection<T> extends StatelessWidget {
  const _SegmentSection({
    required this.label,
    required this.values,
    required this.selectedValue,
    required this.onSelected,
    this.displayText,
  });

  final String label;
  final List<T> values;
  final T selectedValue;
  final ValueChanged<T> onSelected;
  final String Function(T value)? displayText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelMedium),
        const SizedBox(height: 16),
        Row(
          children: [
            for (final value in values) ...[
              Expanded(
                child: GestureDetector(
                  onTap: () => onSelected(value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: selectedValue == value
                          ? AppColors.surfaceContainerHighest
                          : Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selectedValue == value
                            ? AppColors.teal.withValues(alpha: 0.22)
                            : Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Text(
                      displayText?.call(value) ?? value.toString(),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: selectedValue == value
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.58),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              if (value != values.last) const SizedBox(width: 12),
            ],
          ],
        ),
      ],
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                size: 20,
                color: Colors.white.withValues(alpha: 0.56),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: theme.textTheme.labelMedium),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withValues(alpha: 0.24),
            ),
          ],
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
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.edit_note_rounded,
              size: 20,
              color: Colors.white.withValues(alpha: 0.56),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('NOTE', style: theme.textTheme.labelMedium),
                const SizedBox(height: 6),
                TextField(
                  controller: controller,
                  enabled: enabled,
                  maxLines: 1,
                  decoration: const InputDecoration(
                    hintText: 'Add a note...',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

IconData _iconForCategory(String iconName) {
  switch (iconName) {
    case 'restaurant':
      return Icons.restaurant_rounded;
    case 'directions_car':
      return Icons.directions_car_rounded;
    case 'bolt':
      return Icons.bolt_rounded;
    case 'local_hospital':
      return Icons.local_hospital_rounded;
    case 'shopping_bag':
      return Icons.shopping_bag_rounded;
    case 'more_horiz':
      return Icons.more_horiz_rounded;
    default:
      return Icons.category_rounded;
  }
}
