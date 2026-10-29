import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spendsplit/core/icons/lucide_icons.dart';

import '../../../core/widgets/large_title_page.dart';
import '../../../core/constants/enums.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/panel.dart';
import '../../../core/widgets/shimmer_skeleton.dart';
import '../../../providers/providers.dart';
import '../../sms_import/providers/sms_providers.dart';
import '../widgets/active_goal_card.dart';
import '../widgets/available_hero.dart';
import '../widgets/bank_reconcile_card.dart';
import '../widgets/dollar_summary_card.dart';
import '../widgets/expected_this_month_card.dart';
import '../widgets/month_recap_card.dart';
import '../widgets/monthly_snapshot_row.dart';
import '../widgets/sms_review_card.dart';

/// Home answers one question first, "what can I spend?", then shows what
/// needs attention and how the month is going.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(clockTickProvider);
    final balanceSummary = ref.watch(balanceSummaryProvider);
    final currentMonthSummary = ref.watch(currentMonthSummaryProvider);
    final goals = ref.watch(savingsGoalsProvider);
    final dollarSummary = ref.watch(dollarTrackerSummaryProvider);

    final loading =
        balanceSummary.isLoading ||
        currentMonthSummary.isLoading ||
        goals.isLoading ||
        dollarSummary.isLoading;

    return LargeTitlePage(
      title: 'Home',
      trailing: BarIconButton(
        icon: LucideIcons.settings,
        tooltip: 'Settings',
        onPressed: () => context.push(AppRoute.settings.path),
      ),
      slivers: [
        PageBody(
          children: [
            if (loading)
              const _DashboardSkeleton()
            else ...[
              balanceSummary.when(
                data: (summary) => AvailableHero(summary: summary),
                error: (_, _) => const _SectionError(),
                loading: () => const SizedBox.shrink(),
              ),
              const _AttentionSlot(),
              _gap,
              currentMonthSummary.when(
                data: (summary) => MonthlySnapshotRow(
                  summary: summary,
                  onOpen: () => context.go(AppRoute.monthly.path),
                ),
                error: (_, _) => const _SectionError(),
                loading: () => const SizedBox.shrink(),
              ),
              const _ExpectedThisMonthSlot(),
              _gap,
              goals.when(
                data: (goalsList) => ActiveGoalCard(goals: goalsList),
                error: (_, _) => const _SectionError(),
                loading: () => const SizedBox.shrink(),
              ),
              const SizedBox(height: AppSpacing.xs),
              dollarSummary.when(
                data: (summary) => DollarSummaryCard(
                  summary: summary,
                  onTap: () => context.push(AppRoute.dollarTracker.path),
                ),
                error: (_, _) => const _SectionError(),
                loading: () => const SizedBox.shrink(),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

const _gap = SizedBox(height: AppSpacing.section);

/// Everything that asks for the user's attention, stacked tightly: SMS
/// entries to review, a bank balance mismatch, and the month recap (days 1–5).
class _AttentionSlot extends ConsumerWidget {
  const _AttentionSlot();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = [
      if (ref.watch(needsReviewCountProvider) > 0) const SmsReviewCard(),
      if (ref.watch(bankReconciliationProvider) != null)
        const BankReconcileCard(),
      if (ref.watch(monthRecapVisibleProvider)) const MonthRecapCard(),
    ];
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.sm),
            items[i],
          ],
        ],
      ),
    );
  }
}

class _ExpectedThisMonthSlot extends ConsumerWidget {
  const _ExpectedThisMonthSlot();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(expectedThisMonthProvider).isEmpty) {
      return const SizedBox.shrink();
    }
    return const Padding(
      padding: EdgeInsets.only(top: AppSpacing.section),
      child: ExpectedThisMonthCard(),
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const ShimmerSkeleton(
      child: Column(
        children: [
          SkeletonCard(height: 150, radius: 6),
          SizedBox(height: AppSpacing.section),
          SkeletonCard(height: 150, radius: 6),
          SizedBox(height: AppSpacing.section),
          SkeletonCard(height: 90, radius: 6),
        ],
      ),
    );
  }
}

class _SectionError extends StatelessWidget {
  const _SectionError();

  @override
  Widget build(BuildContext context) {
    return Panel(
      child: Text(
        "This section couldn't load. Close and reopen the app to try again.",
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
