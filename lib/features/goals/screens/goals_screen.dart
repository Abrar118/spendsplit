import 'dart:math' as math;

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spendsplit/core/icons/lucide_icons.dart';

import '../../../core/constants/enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/goal_utils.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/large_title_page.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/shimmer_skeleton.dart';
import '../../../data/database/app_database.dart';
import '../../../providers/providers.dart';
import 'goal_detail_screen.dart';
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

    return goalsAsync.when(
      loading: () => const _GoalsSkeleton(),
      error: (error, stackTrace) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(
            "Goals couldn't load. Close and reopen the app to try again.",
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ),
      data: (goals) {
        final activeGoals = sortGoalsByPriority(
          goals.where((goal) => !goal.isCompleted),
        );
        final completedGoals = goals.where((goal) => goal.isCompleted).toList()
          ..sort((a, b) {
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

        return LargeTitlePage(
          title: 'Goals',
          trailing: TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: AppColors.accent),
            onPressed: () => showCreateGoalSheet(context),
            icon: const Icon(LucideIcons.plus, size: 18),
            label: const Text('New goal'),
          ),
          slivers: [
            PageBody(
              children: [
                TotalSavingsBanner(
                  totalSavings: totalSavingsReserved,
                  activeGoalCount: activeGoals.length,
                  monthDelta:
                      insightsAsync.valueOrNull?.monthOverMonthDelta ?? 0,
                ),
                const SizedBox(height: AppSpacing.section),
                const SectionHeader('Active'),
                if (activeGoals.isEmpty)
                  const EmptyState(
                    icon: LucideIcons.flag,
                    title: 'No goals yet',
                    message:
                        'Tap New goal to give your savings something to aim at.',
                  )
                else
                  for (var i = 0; i < activeGoals.length; i++) ...[
                    GoalCard(
                      goal: activeGoals[i],
                      onTap: () =>
                          context.push(goalDetailPath(activeGoals[i].id)),
                      onMenuSelected: (action) =>
                          _handleGoalAction(activeGoals[i], action),
                    ),
                    if (i != activeGoals.length - 1)
                      const SizedBox(height: AppSpacing.xs),
                  ],
                const SizedBox(height: AppSpacing.section),
                Builder(
                  builder: (context) {
                    final (body, late) = _buildPredictiveCopy(
                      activeGoals: activeGoals,
                      averageMonthlySavings:
                          insightsAsync.valueOrNull?.averageMonthlySavings ?? 0,
                    );
                    final single = activeGoals.length <= 1;
                    return OverallProgressCard(
                      progress: overallProgress,
                      title: late
                          ? 'Behind the deadline'
                          : single
                          ? 'Forecast'
                          : 'All active goals',
                      body: body,
                      showProgress: !single,
                      late: late,
                    );
                  },
                ),
                if (completedGoals.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.section),
                  InkWell(
                    onTap: () => setState(() {
                      _completedExpanded = !_completedExpanded;
                    }),
                    borderRadius: BorderRadius.zero,
                    child: Ink(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: AppDecorations.module(),
                      child: Row(
                        children: [
                          Text('Completed', style: theme.textTheme.titleMedium),
                          const SizedBox(width: 8),
                          Text(
                            '${completedGoals.length}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: AppColors.textSecondary,
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
                    const SizedBox(height: AppSpacing.xs),
                    for (var i = 0; i < completedGoals.length; i++) ...[
                      GoalCard(
                        goal: completedGoals[i],
                        completed: true,
                        onTap: () =>
                            context.push(goalDetailPath(completedGoals[i].id)),
                        onMenuSelected: (action) =>
                            _handleGoalAction(completedGoals[i], action),
                      ),
                      if (i != completedGoals.length - 1)
                        const SizedBox(height: AppSpacing.xs),
                    ],
                  ],
                ],
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleGoalAction(
    SavingsGoalsTableData goal,
    GoalMenuAction action,
  ) async {
    final repository = ref.read(savingsRepositoryProvider);

    switch (action) {
      case GoalMenuAction.contribute:
        await _addContribution(goal);
        break;
      case GoalMenuAction.edit:
        await showCreateGoalSheet(context, existingGoal: goal);
        break;
      case GoalMenuAction.complete:
        await repository.updateGoal(
          // The amount stays the sum of linked transactions; completing an
          // underfunded goal doesn't invent savings.
          goal.copyWith(isCompleted: true, completedAt: Value(DateTime.now())),
        );
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Goal marked complete')));
        }
        break;
      case GoalMenuAction.delete:
        // Captured: the Undo snackbar can outlive this screen.
        final messenger = ScaffoldMessenger.of(context);
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Delete goal?'),
              content: Text(
                'Remove "${goal.name}"? Its contributions stay in your '
                'history, unlinked.',
              ),
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

        final linked = await repository.deleteGoalById(goal.id);
        var undone = false;
        messenger.showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 4),
            content: Text('"${goal.name}" deleted'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () async {
                if (undone) return;
                undone = true;
                try {
                  await repository.restoreGoal(goal, linked);
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Undo failed: $e')),
                  );
                }
              },
            ),
          ),
        );
        break;
    }
  }

  Future<void> _addContribution(SavingsGoalsTableData goal) async {
    final controller = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);
    final amount = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        title: Text('Contribute to "${goal.name}"'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Amount (৳)',
            prefixText: '৳ ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final v = double.tryParse(
                controller.text.replaceAll(',', '').trim(),
              );
              if (v == null || !v.isFinite || v <= 0) return;
              Navigator.of(ctx).pop(v);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (amount == null) return;

    final db = ref.read(appDatabaseProvider);
    final repository = ref.read(savingsRepositoryProvider);
    final target = goal.targetAmount;

    try {
      await db.transaction(() async {
        await db.transactionDao.insertTransaction(
          TransactionsTableCompanion.insert(
            type: TransactionType.savingsDeposit.dbValue,
            amount: amount,
            date: DateTime.now(),
            savingsGoalId: Value(goal.id),
            note: const Value('Goal contribution'),
          ),
        );
        // The full amount, matching what delete and edit later reverse.
        final ok = await repository.adjustGoalAmountBy(goal.id, amount);
        if (!ok) throw StateError('Could not update the goal.');
      });
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
      return;
    }

    if (!mounted) return;
    final reachedTarget = goal.currentAmount + amount >= target - 1e-9;
    if (reachedTarget) {
      final complete = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surfaceLight,
          title: const Text('Goal reached'),
          content: Text('"${goal.name}" is fully funded. Mark it complete?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Not yet'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Mark complete'),
            ),
          ],
        ),
      );
      if (complete == true) {
        await repository.updateGoal(
          goal.copyWith(
            isCompleted: true,
            completedAt: Value(DateTime.now()),
            // `goal` predates the contribution; keep the amount just saved
            // rather than clamping it to the target.
            currentAmount: goal.currentAmount + amount,
          ),
        );
      }
    } else if (mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Added ${formatBdtAmount(amount, fractionDigits: 0)} to "${goal.name}"',
          ),
        ),
      );
    }
  }

  /// The forecast for the top goal, and whether it lands after that goal's
  /// deadline.
  (String, bool) _buildPredictiveCopy({
    required List<SavingsGoalsTableData> activeGoals,
    required double averageMonthlySavings,
  }) {
    if (activeGoals.isEmpty) {
      return (
        'Create a savings goal to get a forecast for your next milestone.',
        false,
      );
    }

    final targetGoal = activeGoals.first;
    if (averageMonthlySavings <= 0) {
      return (
        'Build a month of savings history to forecast when "${targetGoal.name}" will be fully funded.',
        false,
      );
    }

    final remaining = math.max(
      0,
      targetGoal.targetAmount - targetGoal.currentAmount,
    );
    if (remaining == 0) {
      return (
        '"${targetGoal.name}" is fully funded. Point your savings at the next goal.',
        false,
      );
    }
    final months = math.max(1, (remaining / averageMonthlySavings).ceil());
    final average = formatBdtAmount(averageMonthlySavings, fractionDigits: 0);
    final pace =
        'At your average of $average a month, "${targetGoal.name}" is funded '
        'in about $months month${months == 1 ? '' : 's'}';

    final deadline = targetGoal.deadline;
    if (deadline == null) return ('$pace.', false);
    final daysLeft = calendarDaysUntil(deadline);
    final monthsLeft = daysLeft / 30.44;
    if (months <= monthsLeft) return ('$pace, before its deadline.', false);
    final needed = monthsLeft < 1
        ? remaining.toDouble()
        : remaining / monthsLeft.floor().clamp(1, 1 << 30);
    return (
      '$pace, after its ${formatShortDate(deadline)} deadline. '
          'Saving ${formatBdtAmount(needed, fractionDigits: 0)} a month would make it.',
      true,
    );
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
              SkeletonCard(height: 64, radius: 6),
              SizedBox(height: 24),
              SkeletonCard(height: 142, radius: 6),
              SizedBox(height: 28),
              SkeletonCard(height: 128, radius: 6),
              SizedBox(height: 14),
              SkeletonCard(height: 128, radius: 6),
              SizedBox(height: 28),
              SkeletonCard(height: 84, radius: 6),
              SizedBox(height: 28),
              SkeletonCard(height: 248, radius: 6),
            ],
          ),
        ),
      ],
    );
  }
}
