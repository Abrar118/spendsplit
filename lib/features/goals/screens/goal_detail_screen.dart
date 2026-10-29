import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:spendsplit/core/icons/lucide_icons.dart';

import '../../../core/widgets/dot_figure.dart';
import '../../../core/constants/enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/flat_bar.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/panel.dart';
import '../../../data/database/app_database.dart';
import '../../../data/models/financial_summaries.dart';
import '../../../providers/providers.dart';

class GoalDetailScreen extends ConsumerWidget {
  const GoalDetailScreen({required this.goalId, super.key});

  final int goalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final goalsAsync = ref.watch(savingsGoalsProvider);
    final transactionsAsync = ref.watch(transactionsProvider);

    SavingsGoalsTableData? goal;
    for (final g in goalsAsync.valueOrNull ?? const <SavingsGoalsTableData>[]) {
      if (g.id == goalId) {
        goal = g;
        break;
      }
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: goal == null
            ? Center(
                child: goalsAsync.hasError
                    ? Text("Couldn't load goals: ${goalsAsync.error}")
                    : goalsAsync.hasValue
                    ? const Text('Goal not found')
                    : const CircularProgressIndicator(color: AppColors.savings),
              )
            : _Body(
                goal: goal,
                linked:
                    (transactionsAsync.valueOrNull ?? const [])
                        .where((t) => t.savingsGoalId == goalId)
                        .toList()
                      ..sort((a, b) => b.date.compareTo(a.date)),
                theme: theme,
              ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.goal, required this.linked, required this.theme});

  final SavingsGoalsTableData goal;
  final List<TransactionsTableData> linked;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final progress = goal.targetAmount <= 0
        ? 0.0
        : (goal.currentAmount / goal.targetAmount).clamp(0.0, 1.0);
    final projection = FinanceCalculators.goalProjection(
      goal: goal,
      linkedTransactions: linked,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.navClearance,
      ),
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Back',
              onPressed: () => context.pop(),
              icon: const Icon(LucideIcons.chevronLeft),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                goal.name,
                style: theme.textTheme.headlineMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        DotFigure(
          label: 'Funded',
          value: progress * 100,
          suffix: '%',
          color: AppColors.savings,
          semanticLabel: '${(progress * 100).round()} percent funded',
        ),
        FlatBar(value: progress, color: AppColors.savings, height: 8),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              formatBdtAmount(goal.currentAmount),
              style: theme.textTheme.titleMedium,
            ),
            const Spacer(),
            Text(
              'of ${formatBdtAmount(goal.targetAmount)}',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.section),
        _ProjectionCard(goal: goal, projection: projection),
        const SizedBox(height: AppSpacing.section),
        const SectionHeader('Contributions'),
        if (linked.isEmpty)
          Text(
            'No contributions logged against this goal yet. Use Add contribution from the goal menu.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          )
        else
          for (final t in linked) ...[
            _ContributionRow(transaction: t),
            const SizedBox(height: 8),
          ],
      ],
    );
  }
}

class _ProjectionCard extends StatelessWidget {
  const _ProjectionCard({required this.goal, required this.projection});

  final SavingsGoalsTableData goal;
  final GoalProjection projection;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lines = <String>[];

    final funded = goal.currentAmount >= goal.targetAmount - 1e-9;
    final deadline = goal.deadline;
    final completion = projection.estimatedCompletion;
    // Behind: the deadline has passed, or the current pace lands after it.
    final behind =
        !funded &&
        deadline != null &&
        (projection.requiredWeeklyForDeadline == null ||
            (completion != null && completion.isAfter(deadline)));

    if (funded) {
      lines.add('Fully funded.');
    } else if (projection.estimatedCompletion != null) {
      lines.add(
        'At ${formatBdtAmount(projection.weeklyRate, fractionDigits: 0)}/week, '
        'done ~${DateFormat('MMM yyyy').format(projection.estimatedCompletion!)}'
        '${behind ? ', after the deadline' : ''}.',
      );
    } else {
      lines.add('Log a few contributions to project a completion date.');
    }

    final required = projection.requiredWeeklyForDeadline;
    if (!funded && deadline != null) {
      if (required == null) {
        lines.add(
          'The ${DateFormat('MMM d').format(deadline)} deadline has passed.',
        );
      } else if (required > 0) {
        lines.add(
          'Put aside ${formatBdtAmount(required, fractionDigits: 0)}/week to hit '
          'your ${DateFormat('MMM d').format(deadline)} deadline.',
        );
      }
    }

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.trendingUp,
                size: 18,
                color: behind ? AppColors.warning : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                behind ? 'Behind the deadline' : 'Projection',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: behind ? AppColors.warning : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final line in lines) ...[
            Text(
              line,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }
}

class _ContributionRow extends StatelessWidget {
  const _ContributionRow({required this.transaction});

  final TransactionsTableData transaction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWithdrawal = transaction.type == 'savings_withdrawal';
    final color = isWithdrawal ? AppColors.warning : AppColors.savings;
    final sign = isWithdrawal ? '-' : '+';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.6),
        borderRadius: BorderRadius.zero,
      ),
      child: Row(
        children: [
          Icon(
            isWithdrawal
                ? LucideIcons.arrowUpFromLine
                : LucideIcons.arrowDownToLine,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.note?.isNotEmpty == true
                      ? transaction.note!
                      : (isWithdrawal ? 'Withdrawal' : 'Contribution'),
                  style: theme.textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  formatShortDate(transaction.date),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$sign${formatBdtAmount(transaction.amount, fractionDigits: 0)}',
            style: theme.textTheme.titleSmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

/// Helper for callers that need the detail route path.
String goalDetailPath(int id) => '${AppRoute.goalDetail.path}/$id';
