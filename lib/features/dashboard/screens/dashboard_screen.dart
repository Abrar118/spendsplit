import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/constants/enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../providers/providers.dart';
import '../widgets/active_goal_card.dart';
import '../widgets/balance_card.dart';
import '../widgets/dollar_summary_card.dart';
import '../widgets/monthly_snapshot_row.dart';
import '../widgets/spending_chart.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final balanceSummary = ref.watch(balanceSummaryProvider);
    final currentMonthSummary = ref.watch(currentMonthSummaryProvider);
    final transactions = ref.watch(transactionsProvider);
    final goals = ref.watch(savingsGoalsProvider);
    final dollarSummary = ref.watch(dollarTrackerSummaryProvider);

    final loading =
        balanceSummary.isLoading ||
        currentMonthSummary.isLoading ||
        transactions.isLoading ||
        goals.isLoading ||
        dollarSummary.isLoading;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: AppColors.teal,
        onRefresh: () async {
          ref.invalidate(transactionsProvider);
          ref.invalidate(balanceSummaryProvider);
          ref.invalidate(currentMonthSummaryProvider);
          ref.invalidate(savingsGoalsProvider);
          ref.invalidate(dollarTrackerSummaryProvider);
          ref.invalidate(dollarExpensesProvider);
          await Future.wait([
            ref.read(transactionsProvider.future),
            ref.read(savingsGoalsProvider.future),
            ref.read(dollarExpensesProvider.future),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            132,
          ),
          children: [
            // --- Top bar ---
            Row(
              children: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(LucideIcons.menu),
                ),
                const SizedBox(width: 4),
                Text(
                  'SpendSplit',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => context.push(AppRoute.settings.path),
                  icon: const Icon(LucideIcons.settings),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            if (loading)
              const _DashboardSkeleton()
            else ...[
              balanceSummary.when(
                data: (summary) => BalanceCard(summary: summary),
                error: (error, stackTrace) => const _SectionError(),
                loading: () => const _DashboardSkeleton(),
              ),
              const SizedBox(height: AppSpacing.section),
              currentMonthSummary.when(
                data: (summary) => MonthlySnapshotRow(summary: summary),
                error: (error, stackTrace) => const _SectionError(),
                loading: () => const _SnapshotSkeleton(),
              ),
              const SizedBox(height: AppSpacing.section),
              transactions.when(
                data: (entries) => SpendingChart(
                  transactions: entries,
                  onDetailsTap: () => context.go(AppRoute.monthly.path),
                ),
                error: (error, stackTrace) => const _SectionError(),
                loading: () => const _CardSkeleton(height: 280),
              ),
              const SizedBox(height: AppSpacing.section),
              goals.when(
                data: (goalsList) => ActiveGoalCard(goals: goalsList),
                error: (error, stackTrace) => const _SectionError(),
                loading: () => const _CardSkeleton(height: 126),
              ),
              const SizedBox(height: AppSpacing.section),
              dollarSummary.when(
                data: (summary) => DollarSummaryCard(
                  summary: summary,
                  onTap: () => context.push(AppRoute.dollarTracker.path),
                ),
                error: (error, stackTrace) => const _SectionError(),
                loading: () => const _CardSkeleton(height: 210),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceLight,
      highlightColor: AppColors.surfaceContainerHighest,
      child: const Column(
        children: [
          _CardSkeleton(height: 250),
          SizedBox(height: 28),
          _SnapshotSkeleton(),
          SizedBox(height: 28),
          _CardSkeleton(height: 280),
          SizedBox(height: 28),
          _CardSkeleton(height: 126),
          SizedBox(height: 28),
          _CardSkeleton(height: 210),
        ],
      ),
    );
  }
}

class _SnapshotSkeleton extends StatelessWidget {
  const _SnapshotSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 112,
      child: Row(
        children: [
          Expanded(child: _CardSkeleton(height: 112)),
          SizedBox(width: 14),
          Expanded(child: _CardSkeleton(height: 112)),
          SizedBox(width: 14),
          Expanded(child: _CardSkeleton(height: 112)),
        ],
      ),
    );
  }
}

class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: GlassCard(
        child: Container(color: Colors.white.withValues(alpha: 0.04)),
      ),
    );
  }
}

class _SectionError extends StatelessWidget {
  const _SectionError();

  @override
  Widget build(BuildContext context) {
    return const GlassCard(
      child: SizedBox(
        height: 120,
        child: Center(child: Text('Could not load this section')),
      ),
    );
  }
}
