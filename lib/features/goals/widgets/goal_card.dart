import 'package:flutter/material.dart';
import 'package:spendsplit/core/icons/lucide_icons.dart';

import '../../../core/constants/goal_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/flat_bar.dart';
import '../../../data/database/app_database.dart';

/// One goal as a module: name and deadline, amount against target, and a
/// bone progress bar (green once completed).
class GoalCard extends StatelessWidget {
  const GoalCard({
    required this.goal,
    super.key,
    this.completed = false,
    this.onMenuSelected,
    this.onTap,
  });

  final SavingsGoalsTableData goal;
  final bool completed;
  final ValueChanged<GoalMenuAction>? onMenuSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = GoalIcons.resolve(goal.icon);
    final progress = goal.targetAmount <= 0
        ? 0.0
        : (goal.currentAmount / goal.targetAmount).clamp(0.0, 1.0);
    final percentage = (progress * 100).round();
    final color = completed ? AppColors.income : AppColors.savings;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppDecorations.radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDecorations.radius),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 4, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon.icon, color: AppColors.textSecondary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          goal.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            decoration: completed
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        Text(_subtitle(), style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  if (onMenuSelected != null)
                    PopupMenuButton<GoalMenuAction>(
                      tooltip: 'Goal actions',
                      onSelected: onMenuSelected,
                      itemBuilder: (context) => [
                        if (!completed)
                          const PopupMenuItem(
                            value: GoalMenuAction.contribute,
                            child: Text('Add contribution'),
                          ),
                        const PopupMenuItem(
                          value: GoalMenuAction.edit,
                          child: Text('Edit'),
                        ),
                        if (!completed)
                          const PopupMenuItem(
                            value: GoalMenuAction.complete,
                            child: Text('Mark complete'),
                          ),
                        const PopupMenuItem(
                          value: GoalMenuAction.delete,
                          child: Text('Delete'),
                        ),
                      ],
                      icon: const Icon(LucideIcons.moreHorizontal),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          formatBdtAmount(goal.currentAmount),
                          style: theme.textTheme.titleMedium,
                        ),
                        Text(
                          '  of ${formatBdtAmount(goal.targetAmount)}',
                          style: theme.textTheme.bodySmall,
                        ),
                        const Spacer(),
                        Text(
                          '$percentage%',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    FlatBar(value: progress, color: color),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _subtitle() {
    final completedAt = goal.completedAt;
    if (completed && completedAt != null) {
      return 'Completed ${formatShortDate(completedAt)}';
    }
    final deadline = goal.deadline;
    if (deadline == null) return 'No deadline';
    final days = calendarDaysUntil(deadline);
    if (days < 0) return 'Deadline passed ${formatShortDate(deadline)}';
    if (days == 0) return 'Due today';
    return '$days day${days == 1 ? '' : 's'} left · ${formatShortDate(deadline)}';
  }
}

enum GoalMenuAction { contribute, edit, complete, delete }
