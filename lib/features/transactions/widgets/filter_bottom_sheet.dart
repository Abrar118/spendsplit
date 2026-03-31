import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/database/app_database.dart';

class TransactionAdvancedFilters {
  const TransactionAdvancedFilters({
    this.transactionTypes = const {},
    this.categoryIds = const {},
    this.startDate,
    this.endDate,
  });

  final Set<TransactionType> transactionTypes;
  final Set<int> categoryIds;
  final DateTime? startDate;
  final DateTime? endDate;

  bool get hasActiveFilters =>
      transactionTypes.isNotEmpty ||
      categoryIds.isNotEmpty ||
      startDate != null ||
      endDate != null;

  TransactionAdvancedFilters copyWith({
    Set<TransactionType>? transactionTypes,
    Set<int>? categoryIds,
    DateTime? startDate,
    DateTime? endDate,
    bool clearStartDate = false,
    bool clearEndDate = false,
  }) {
    return TransactionAdvancedFilters(
      transactionTypes: transactionTypes ?? this.transactionTypes,
      categoryIds: categoryIds ?? this.categoryIds,
      startDate: clearStartDate ? null : startDate ?? this.startDate,
      endDate: clearEndDate ? null : endDate ?? this.endDate,
    );
  }
}

Future<TransactionAdvancedFilters?> showTransactionFilterBottomSheet(
  BuildContext context, {
  required TransactionAdvancedFilters initialFilters,
  required List<CategoriesTableData> categories,
}) {
  return showModalBottomSheet<TransactionAdvancedFilters>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    enableDrag: true,
    builder: (context) => _FilterBottomSheet(
      initialFilters: initialFilters,
      categories: categories,
    ),
  );
}

class _FilterBottomSheet extends StatefulWidget {
  const _FilterBottomSheet({
    required this.initialFilters,
    required this.categories,
  });

  final TransactionAdvancedFilters initialFilters;
  final List<CategoriesTableData> categories;

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late Set<TransactionType> _selectedTypes;
  late Set<int> _selectedCategoryIds;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _selectedTypes = {...widget.initialFilters.transactionTypes};
    _selectedCategoryIds = {...widget.initialFilters.categoryIds};
    _startDate = widget.initialFilters.startDate;
    _endDate = widget.initialFilters.endDate;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text('Filters', style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 24),
                  Text('TYPE', style: theme.textTheme.labelMedium),
                  const SizedBox(height: 12),
                  _FilterCheck(
                    label: 'Income',
                    value: _selectedTypes.contains(TransactionType.income),
                    onChanged: () => _toggleType(TransactionType.income),
                  ),
                  _FilterCheck(
                    label: 'Expense',
                    value: _selectedTypes.contains(TransactionType.expense),
                    onChanged: () => _toggleType(TransactionType.expense),
                  ),
                  _FilterCheck(
                    label: 'Savings',
                    value:
                        _selectedTypes.contains(
                          TransactionType.savingsDeposit,
                        ) ||
                        _selectedTypes.contains(
                          TransactionType.savingsWithdrawal,
                        ),
                    onChanged: _toggleSavings,
                  ),
                  const SizedBox(height: 24),
                  Text('CATEGORY', style: theme.textTheme.labelMedium),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final category in widget.categories)
                        FilterChip(
                          selected: _selectedCategoryIds.contains(category.id),
                          label: Text(category.name),
                          selectedColor: AppColors.teal.withValues(alpha: 0.18),
                          checkmarkColor: AppColors.teal,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                          onSelected: (_) => _toggleCategory(category.id),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('DATE RANGE', style: theme.textTheme.labelMedium),
                  const SizedBox(height: 12),
                  _DateFilterRow(
                    label: 'From',
                    value: _startDate,
                    onTap: () async {
                      final picked = await _pickDate(_startDate);
                      if (picked != null) {
                        setState(() {
                          _startDate = picked;
                        });
                      }
                    },
                    onClear: _startDate == null
                        ? null
                        : () => setState(() {
                            _startDate = null;
                          }),
                  ),
                  const SizedBox(height: 10),
                  _DateFilterRow(
                    label: 'To',
                    value: _endDate,
                    onTap: () async {
                      final picked = await _pickDate(_endDate);
                      if (picked != null) {
                        setState(() {
                          _endDate = picked;
                        });
                      }
                    },
                    onClear: _endDate == null
                        ? null
                        : () => setState(() {
                            _endDate = null;
                          }),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(context).pop(
                          TransactionAdvancedFilters(
                            transactionTypes: _selectedTypes,
                            categoryIds: _selectedCategoryIds,
                            startDate: _startDate,
                            endDate: _endDate,
                          ),
                        );
                      },
                      child: const Text('Apply'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(
                          context,
                        ).pop(const TransactionAdvancedFilters());
                      },
                      child: const Text('Reset'),
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

  void _toggleType(TransactionType type) {
    setState(() {
      if (_selectedTypes.contains(type)) {
        _selectedTypes.remove(type);
      } else {
        _selectedTypes.add(type);
      }
    });
  }

  void _toggleSavings() {
    setState(() {
      // Match the display condition: "either present" means checked.
      // Tapping when checked removes both; tapping when unchecked adds both.
      final hasAny =
          _selectedTypes.contains(TransactionType.savingsDeposit) ||
          _selectedTypes.contains(TransactionType.savingsWithdrawal);

      if (hasAny) {
        _selectedTypes.remove(TransactionType.savingsDeposit);
        _selectedTypes.remove(TransactionType.savingsWithdrawal);
      } else {
        _selectedTypes.add(TransactionType.savingsDeposit);
        _selectedTypes.add(TransactionType.savingsWithdrawal);
      }
    });
  }

  void _toggleCategory(int categoryId) {
    setState(() {
      if (_selectedCategoryIds.contains(categoryId)) {
        _selectedCategoryIds.remove(categoryId);
      } else {
        _selectedCategoryIds.add(categoryId);
      }
    });
  }

  Future<DateTime?> _pickDate(DateTime? initialDate) {
    return showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
  }
}

class _FilterCheck extends StatelessWidget {
  const _FilterCheck({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      value: value,
      activeColor: AppColors.teal,
      checkColor: AppColors.onPrimary,
      title: Text(label),
      controlAffinity: ListTileControlAffinity.leading,
      onChanged: (_) => onChanged(),
    );
  }
}

class _DateFilterRow extends StatelessWidget {
  const _DateFilterRow({
    required this.label,
    required this.value,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            const Spacer(),
            Text(
              value == null
                  ? 'Select'
                  : DateFormat('dd/MM/yyyy').format(value!),
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
            ),
            if (onClear != null) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onClear,
                child: const Icon(LucideIcons.x, size: 16),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
