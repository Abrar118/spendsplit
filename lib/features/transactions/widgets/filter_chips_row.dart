import 'package:flutter/material.dart';

import '../../../core/constants/enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/accent_chip.dart';

class FilterChipsRow extends StatelessWidget {
  const FilterChipsRow({
    required this.selectedFilter,
    required this.onSelected,
    super.key,
  });

  final TransactionQuickFilter selectedFilter;
  final ValueChanged<TransactionQuickFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          AccentChip(
            label: 'All',
            selected: selectedFilter == TransactionQuickFilter.all,
            onTap: () => onSelected(TransactionQuickFilter.all),
          ),
          const SizedBox(width: 10),
          AccentChip(
            label: 'Income',
            selected: selectedFilter == TransactionQuickFilter.income,
            color: AppColors.green,
            onTap: () => onSelected(TransactionQuickFilter.income),
          ),
          const SizedBox(width: 10),
          AccentChip(
            label: 'Expense',
            selected: selectedFilter == TransactionQuickFilter.expense,
            color: AppColors.coral,
            onTap: () => onSelected(TransactionQuickFilter.expense),
          ),
          const SizedBox(width: 10),
          AccentChip(
            label: 'Savings',
            selected: selectedFilter == TransactionQuickFilter.savings,
            color: AppColors.purple,
            onTap: () => onSelected(TransactionQuickFilter.savings),
          ),
        ],
      ),
    );
  }
}
