import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/large_title_page.dart';
import '../../../providers/providers.dart';
import '../widgets/balance_trend_chart.dart';
import '../widgets/daily_spend_heatmap.dart';
import '../widgets/month_pace_chart.dart';
import '../widgets/spending_chart.dart';

/// Spending and balance over time: this month's pace, twelve months of
/// spending, thirteen weeks of days, and six months of balance.
class GraphsScreen extends ConsumerWidget {
  const GraphsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posted = ref.watch(postedTransactionsProvider);
    return LargeTitlePage(
      title: 'Graphs',
      slivers: [
        PageBody(
          children: [
            ...posted.maybeWhen(
              data: (entries) => [
                MonthPaceChart(transactions: entries),
                const SizedBox(height: AppSpacing.md),
                SpendingChart(transactions: entries),
                const SizedBox(height: AppSpacing.md),
                DailySpendHeatmap(transactions: entries),
                const SizedBox(height: AppSpacing.md),
              ],
              orElse: () => const <Widget>[],
            ),
            const BalanceTrendChart(),
          ],
        ),
      ],
    );
  }
}
