import 'package:flutter/material.dart';

import '../../../core/widgets/dot_figure.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/flat_bar.dart';
import '../../../data/models/financial_summaries.dart';

/// The Dollar Tracker's hero: USD left this year as a blue dot-grid figure
/// over the construction grid, then the allowance bar and pace. Blue is the
/// tracker's own colour, so it never reads as part of the taka balance.
class DollarHeaderCard extends StatelessWidget {
  const DollarHeaderCard({required this.summary, super.key});

  final DollarTrackerSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final used = summary.annualLimit <= 0
        ? 0.0
        : summary.spentYtd / summary.annualLimit;
    final over = summary.remaining < 0;
    final figureColor = over ? AppColors.spend : AppColors.usd;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DotFigure(
          label: over ? 'Over this year’s allowance' : 'Left this year',
          value: summary.remaining.abs(),
          prefix: r'$',
          color: figureColor,
          maxSize: 72,
          semanticLabel: over
              ? '${formatUsdAmount(-summary.remaining)} over the allowance'
              : '${formatUsdAmount(summary.remaining)} left this year',
        ),
        FlatBar(value: used, color: figureColor, height: 8),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              '${formatUsdAmount(summary.spentYtd)} spent',
              style: theme.textTheme.labelMedium,
            ),
            const Spacer(),
            Text(
              'of ${formatUsdAmount(summary.annualLimit)}',
              style: theme.textTheme.labelMedium,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          _paceText(summary),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: summary.projectedOver ? AppColors.warning : null,
          ),
        ),
      ],
    );
  }
}

String _paceText(DollarTrackerSummary s) {
  if (s.spentYtd <= 0) return 'No USD spending yet this year.';
  if (!s.hasPace) {
    return 'Year-end pace shows after ${FinanceCalculators.minPaceDays} days.';
  }
  final projected = formatUsdAmount(s.projectedYearEnd, fractionDigits: 0);
  final diff = formatUsdAmount(s.projectedVsLimit.abs(), fractionDigits: 0);
  final verb = s.projectedVsLimit > 0 ? 'over' : 'under';
  return 'On pace for $projected by December, $diff $verb the allowance.';
}
