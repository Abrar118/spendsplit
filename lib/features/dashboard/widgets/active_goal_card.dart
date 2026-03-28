import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../data/database/app_database.dart';

class ActiveGoalCard extends StatelessWidget {
  const ActiveGoalCard({required this.goals, super.key});

  final List<SavingsGoalsTableData> goals;

  @override
  Widget build(BuildContext context) {
    // Find the first active (not completed) goal
    final activeGoals = goals.where((g) => !g.isCompleted).toList();

    if (activeGoals.isEmpty) {
      return _EmptyGoalCard();
    }

    final goal = activeGoals.first;
    return _ActiveGoalDisplay(goal: goal);
  }
}

class _EmptyGoalCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      glowColor: AppColors.purple,
      radius: 24,
      child: Row(
        children: [
          Container(
            width: 4,
            height: 96,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.teal, AppColors.purple],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Savings Goal',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Set your first savings goal to see progress here.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Icon(LucideIcons.flag, color: AppColors.purple),
        ],
      ),
    );
  }
}

class _ActiveGoalDisplay extends StatelessWidget {
  const _ActiveGoalDisplay({required this.goal});

  final SavingsGoalsTableData goal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final target = goal.targetAmount;
    // Goal progress is based on the current saved amount vs target.
    // Since savings are tracked via transactions (not directly on the goal),
    // we show the target and deadline here. Full progress tracking
    // is wired in Phase 7 when the goals screen links savings to goals.
    final daysRemaining = _daysRemaining(goal.deadline);

    return GlassCard(
      glowColor: AppColors.purple,
      radius: 24,
      child: Row(
        children: [
          // Left accent bar
          Container(
            width: 4,
            height: 96,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.teal, AppColors.purple],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  goal.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      LucideIcons.clock,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      daysRemaining != null
                          ? '$daysRemaining DAYS LEFT'
                          : 'No deadline',
                      style: theme.textTheme.labelMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Target: ${formatBdtAmount(target, fractionDigits: 0)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Icon(LucideIcons.flag, color: AppColors.purple),
        ],
      ),
    );
  }

  int? _daysRemaining(DateTime? deadline) {
    if (deadline == null) return null;
    final now = DateTime.now();
    final diff = deadline.difference(now).inDays;
    return diff < 0 ? 0 : diff;
  }
}
