import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/dot_figure.dart';

/// Goals' hero: what is set aside toward active goals, as a bone dot-grid
/// figure over the construction grid.
class TotalSavingsBanner extends StatelessWidget {
  const TotalSavingsBanner({
    required this.totalSavings,
    required this.activeGoalCount,
    required this.monthDelta,
    super.key,
  });

  final double totalSavings;
  final int activeGoalCount;
  final double monthDelta;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final goals =
        '$activeGoalCount active goal${activeGoalCount == 1 ? '' : 's'}';
    final pct = (monthDelta.abs() * 100).round();
    final change = monthDelta == 0
        ? ''
        : ' · $pct% ${monthDelta > 0 ? 'more' : 'less'} saved than last month';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DotFigure(
          label: 'Saved toward goals',
          value: totalSavings,
          prefix: '৳',
          color: AppColors.savings,
          maxSize: 72,
          semanticLabel: 'Saved toward goals ${formatBdtAmount(totalSavings)}',
        ),
        const SizedBox(height: 4),
        Text('Across $goals$change', style: theme.textTheme.bodyMedium),
      ],
    );
  }
}
