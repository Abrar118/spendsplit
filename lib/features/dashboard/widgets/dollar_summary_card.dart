import 'package:flutter/material.dart';
import 'package:spendsplit/core/icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/flat_bar.dart';
import '../../../data/models/financial_summaries.dart';

/// The USD allowance as one row, in the Dollar Tracker's own blue so it never
/// reads as part of the taka balance.
class DollarSummaryCard extends StatelessWidget {
  const DollarSummaryCard({
    required this.summary,
    required this.onTap,
    super.key,
  });

  final DollarTrackerSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final used = summary.annualLimit <= 0
        ? 0.0
        : summary.spentYtd / summary.annualLimit;
    final over = summary.remaining < 0;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppDecorations.radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDecorations.radius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'USD allowance',
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                  Text(
                    over
                        ? '${formatUsdAmount(-summary.remaining)} over'
                        : '${formatUsdAmount(summary.remaining)} left',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: over ? AppColors.spend : AppColors.usd,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    LucideIcons.chevronRight,
                    color: AppColors.textTertiary,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              FlatBar(value: used, color: AppColors.usd),
              const SizedBox(height: 8),
              Text(
                summary.spentYtd > 0
                    ? _paceText(summary)
                    : '${formatUsdAmount(summary.spentYtd)} of '
                          '${formatUsdAmount(summary.annualLimit)} used this year',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: summary.projectedOver ? AppColors.warning : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _paceText(DollarTrackerSummary s) {
  final used =
      '${formatUsdAmount(s.spentYtd)} of ${formatUsdAmount(s.annualLimit)} used';
  if (!s.hasPace) return used;
  final projected = formatUsdAmount(s.projectedYearEnd, fractionDigits: 0);
  final diff = formatUsdAmount(s.projectedVsLimit.abs(), fractionDigits: 0);
  final verb = s.projectedVsLimit > 0 ? 'over' : 'under';
  return '$used · on pace for $projected, $diff $verb';
}
