import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spendsplit/core/icons/lucide_icons.dart';

import '../../../core/constants/enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/goal_utils.dart';
import '../../../core/widgets/flat_bar.dart';
import '../../../data/database/app_database.dart';
import '../../goals/screens/goal_detail_screen.dart';

/// The top-priority active goal as one row with a bone progress bar; an
/// invitation to set one when there is none.
class ActiveGoalCard extends StatelessWidget {
  const ActiveGoalCard({required this.goals, super.key});

  final List<SavingsGoalsTableData> goals;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeGoals = sortGoalsByPriority(
      goals.where((goal) => !goal.isCompleted),
    );

    if (activeGoals.isEmpty) {
      return _Row(
        onTap: () => context.go(AppRoute.goals.path),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Set a savings goal', style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 2),
                  Text(
                    'Give your savings something to aim at.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const Icon(
              LucideIcons.chevronRight,
              color: AppColors.textTertiary,
              size: 20,
            ),
          ],
        ),
      );
    }

    final goal = activeGoals.first;
    final progress = goal.targetAmount <= 0
        ? 0.0
        : (goal.currentAmount / goal.targetAmount).clamp(0.0, 1.0);
    final percentage = (progress * 100).round();
    final deadline = goal.deadline;
    final daysLeft = deadline == null ? null : calendarDaysUntil(deadline);
    final when = switch (daysLeft) {
      null => 'No deadline',
      < 0 => 'Past deadline',
      0 => 'Due today',
      1 => '1 day left',
      _ => '$daysLeft days left',
    };

    return _Row(
      onTap: () => context.push(goalDetailPath(goal.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  goal.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge,
                ),
              ),
              Text(
                '$percentage%',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.savings,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FlatBar(value: progress, color: AppColors.savings),
          const SizedBox(height: 8),
          Text(
            '${formatBdtAmount(goal.currentAmount)} of '
            '${formatBdtAmount(goal.targetAmount)} · $when',
            style: theme.textTheme.bodySmall?.copyWith(
              color: daysLeft != null && daysLeft < 0
                  ? AppColors.warning
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// A tappable module row.
class _Row extends StatelessWidget {
  const _Row({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppDecorations.radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDecorations.radius),
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    );
  }
}
