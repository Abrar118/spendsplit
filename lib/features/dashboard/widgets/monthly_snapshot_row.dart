import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/stat_strip.dart';
import '../../../data/models/financial_summaries.dart';

/// "This month": income, spending and money moved to savings as one stat
/// strip.
class MonthlySnapshotRow extends StatelessWidget {
  const MonthlySnapshotRow({required this.summary, this.onOpen, super.key});

  final MonthlyFinanceSummary summary;

  /// Opens the Monthly tab.
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          'This month',
          action: onOpen == null ? null : 'Details',
          onAction: onOpen,
        ),
        StatStrip(
          cells: [
            StatCell(
              label: 'Income',
              value: '+${formatBdtAmount(summary.income)}',
              color: AppColors.income,
            ),
            StatCell(
              label: 'Spent',
              value: '−${formatBdtAmount(summary.expenses)}',
              color: AppColors.spend,
            ),
            StatCell(
              label: 'To savings',
              value: formatBdtAmount(summary.saved),
              color: AppColors.savings,
            ),
          ],
        ),
      ],
    );
  }
}
