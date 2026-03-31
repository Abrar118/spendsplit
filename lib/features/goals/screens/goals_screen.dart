import 'dart:math' as math;

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/goal_utils.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/shimmer_skeleton.dart';
import '../../../data/database/app_database.dart';
import '../../../providers/providers.dart';
import '../widgets/create_goal_sheet.dart';
import '../widgets/goal_card.dart';
import '../widgets/overall_progress_card.dart';
import '../widgets/total_savings_banner.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  bool _completedExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final goalsAsync = ref.watch(savingsGoalsProvider);
    final insightsAsync = ref.watch(savingsInsightsProvider);

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: AppColors.teal,
        onRefresh: _refreshGoals,
        child: goalsAsync.when(
          loading: () => const _GoalsSkeleton(),
          error: (error, stackTrace) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const SizedBox(height: 180),
              Center(
                child: Text(
                  'Could not load goals',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.coral,
                  ),
                ),
              ),
            ],
          ),
          data: (goals) {
            final activeGoals = sortGoalsByPriority(
              goals.where((goal) => !goal.isCompleted),
            );
            final completedGoals =
                goals.where((goal) => goal.isCompleted).toList()..sort((a, b) {
                  final aDate = a.completedAt ?? a.createdAt;
                  final bDate = b.completedAt ?? b.createdAt;
                  return bDate.compareTo(aDate);
                });

            final totalSavingsReserved = activeGoals.fold<double>(
              0,
              (sum, goal) => sum + goal.currentAmount,
            );
            final totalActiveTargets = activeGoals.fold<double>(
              0,
              (sum, goal) => sum + goal.targetAmount,
            );
            final overallProgress = totalActiveTargets <= 0
                ? 0.0
                : totalSavingsReserved / totalActiveTargets;

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    132,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      Row(
                        children: [
                          Text(
                            'Savings Goals',
                            style: theme.textTheme.titleLarge,
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () => showCreateGoalSheet(context),
                            icon: const Icon(LucideIcons.plus, size: 18),
                            label: const Text('New Goal'),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      TotalSavingsBanner(
                            totalSavings: totalSavingsReserved,
                            activeGoalCount: activeGoals.length,
                            monthDelta:
                                insightsAsync
                                    .valueOrNull
                                    ?.monthOverMonthDelta ??
                                0,
                          )
                          .animate()
                          .fadeIn(duration: 240.ms)
                          .slideY(begin: 0.06, end: 0, duration: 240.ms),
                      const SizedBox(height: AppSpacing.section),
                      Row(
                        children: [
                          Text(
                            'Active Ambitions',
                            style: theme.textTheme.titleLarge,
                          ),
                          const Spacer(),
                          Text(
                            'PRIORITY VIEW',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (activeGoals.isEmpty)
                        const EmptyState(
                          icon: LucideIcons.flag,
                          title: 'Set your first savings goal!',
                          message:
                              'Create a goal to start tracking progress here.',
                        )
                      else
                        for (var i = 0; i < activeGoals.length; i++) ...[
                          GoalCard(
                                goal: activeGoals[i],
                                onMenuSelected: (action) =>
                                    _handleGoalAction(activeGoals[i], action),
                              )
                              .animate()
                              .fadeIn(duration: 220.ms, delay: (40 * i).ms)
                              .slideY(
                                begin: 0.06,
                                end: 0,
                                duration: 220.ms,
                                delay: (40 * i).ms,
                              ),
                          if (i != activeGoals.length - 1)
                            const SizedBox(height: 14),
                        ],
                      const SizedBox(height: AppSpacing.section),
                      InkWell(
                        onTap: completedGoals.isEmpty
                            ? null
                            : () => setState(() {
                                _completedExpanded = !_completedExpanded;
                              }),
                        borderRadius: BorderRadius.circular(20),
                        child: Ink(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.06),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: AppColors.green.withValues(
                                    alpha: 0.14,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  LucideIcons.check,
                                  size: 16,
                                  color: AppColors.green,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Completed Goals',
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '${completedGoals.length}',
                                  style: theme.textTheme.labelSmall,
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                _completedExpanded
                                    ? LucideIcons.chevronDown
                                    : LucideIcons.chevronRight,
                                color: AppColors.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_completedExpanded) ...[
                        const SizedBox(height: 14),
                        for (var i = 0; i < completedGoals.length; i++) ...[
                          GoalCard(
                            goal: completedGoals[i],
                            completed: true,
                            onMenuSelected: (action) =>
                                _handleGoalAction(completedGoals[i], action),
                          ),
                          if (i != completedGoals.length - 1)
                            const SizedBox(height: 12),
                        ],
                      ],
                      const SizedBox(height: AppSpacing.section),
                      OverallProgressCard(
                            progress: overallProgress,
                            title: 'On track for your milestones',
                            body: _buildPredictiveCopy(
                              activeGoals: activeGoals,
                              averageMonthlySavings:
                                  insightsAsync
                                      .valueOrNull
                                      ?.averageMonthlySavings ??
                                  0,
                            ),
                          )
                          .animate()
                          .fadeIn(duration: 260.ms, delay: 120.ms)
                          .slideY(
                            begin: 0.06,
                            end: 0,
                            duration: 260.ms,
                            delay: 120.ms,
                          ),
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _handleGoalAction(
    SavingsGoalsTableData goal,
    GoalMenuAction action,
  ) async {
    final repository = ref.read(savingsRepositoryProvider);

    switch (action) {
      case GoalMenuAction.edit:
        await showCreateGoalSheet(context, existingGoal: goal);
        break;
      case GoalMenuAction.complete:
        await repository.updateGoal(
          goal.copyWith(
            isCompleted: true,
            completedAt: Value(DateTime.now()),
            currentAmount: goal.targetAmount,
          ),
        );
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Goal marked complete')));
        }
        break;
      case GoalMenuAction.delete:
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Delete goal?'),
              content: Text('Remove "${goal.name}" permanently?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        );

        if (confirmed != true) {
          return;
        }

        await repository.deleteGoalById(goal.id);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Goal deleted')));
        }
        break;
    }
  }

  String _buildPredictiveCopy({
    required List<SavingsGoalsTableData> activeGoals,
    required double averageMonthlySavings,
  }) {
    if (activeGoals.isEmpty) {
      return 'Create a savings goal to get a forecast for your next milestone.';
    }

    final targetGoal = activeGoals.first;
    if (averageMonthlySavings <= 0) {
      return 'Build a month of savings history to forecast when "${targetGoal.name}" will be fully funded.';
    }

    final remaining = math.max(
      0,
      targetGoal.targetAmount - targetGoal.currentAmount,
    );
    if (remaining == 0) {
      return '"${targetGoal.name}" is already fully funded. Shift your savings momentum into the next milestone.';
    }
    final months = remaining <= 0
        ? 0
        : math.max(1, (remaining / averageMonthlySavings).ceil());

    return 'Based on your average monthly savings of ${formatBdtAmount(averageMonthlySavings, fractionDigits: 0)}, you\'ll reach your "${targetGoal.name}" goal in approximately $months month${months == 1 ? '' : 's'}.';
  }

  Future<void> _refreshGoals() async {
    ref.invalidate(savingsGoalsProvider);
    ref.invalidate(transactionsProvider);
    await Future.wait([
      ref.refresh(savingsGoalsProvider.future),
      ref.refresh(transactionsProvider.future),
    ]);
  }
}

class _GoalsSkeleton extends StatelessWidget {
  const _GoalsSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        132,
      ),
      children: const [
        ShimmerSkeleton(
          child: Column(
            children: [
              SkeletonCard(height: 64, radius: 20),
              SizedBox(height: 24),
              SkeletonCard(height: 142, radius: 24),
              SizedBox(height: 28),
              SkeletonCard(height: 128, radius: 22),
              SizedBox(height: 14),
              SkeletonCard(height: 128, radius: 22),
              SizedBox(height: 28),
              SkeletonCard(height: 84, radius: 20),
              SizedBox(height: 28),
              SkeletonCard(height: 248, radius: 24),
            ],
          ),
        ),
      ],
    );
  }
}
