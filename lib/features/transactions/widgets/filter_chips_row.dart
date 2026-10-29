import 'package:flutter/material.dart';

import '../../../core/constants/enums.dart';
import '../../../core/widgets/accent_chip.dart';

class FilterChipsRow extends StatelessWidget {
  const FilterChipsRow({
    required this.selectedFilter,
    required this.onSelected,
    this.showReview = false,
    super.key,
  });

  final TransactionQuickFilter selectedFilter;
  final ValueChanged<TransactionQuickFilter> onSelected;
  final bool showReview;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          AccentChip(
            label: 'All',
            selected: selectedFilter == TransactionQuickFilter.all,
            onTap: () => onSelected(TransactionQuickFilter.all),
          ),
          const SizedBox(width: 8),
          AccentChip(
            label: 'Income',
            selected: selectedFilter == TransactionQuickFilter.income,
            onTap: () => onSelected(TransactionQuickFilter.income),
          ),
          const SizedBox(width: 8),
          AccentChip(
            label: 'Expense',
            selected: selectedFilter == TransactionQuickFilter.expense,
            onTap: () => onSelected(TransactionQuickFilter.expense),
          ),
          const SizedBox(width: 8),
          AccentChip(
            label: 'Savings',
            selected: selectedFilter == TransactionQuickFilter.savings,
            onTap: () => onSelected(TransactionQuickFilter.savings),
          ),
          if (showReview) ...[
            const SizedBox(width: 8),
            AccentChip(
              label: 'Review',
              selected: selectedFilter == TransactionQuickFilter.review,
              onTap: () => onSelected(TransactionQuickFilter.review),
            ),
          ],
        ],
      ),
    );
  }
}
