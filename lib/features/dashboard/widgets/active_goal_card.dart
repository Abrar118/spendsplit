import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/goal_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/goal_utils.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../data/database/app_database.dart';

class ActiveGoalCard extends StatelessWidget {
  const ActiveGoalCard({required this.goals, super.key});

  final List<SavingsGoalsTableData> goals;

  @override
  Widget build(BuildContext context) {
    final activeGoals = sortGoalsByPriority(
      goals.where((goal) => !goal.isCompleted),
    );

    if (activeGoals.isEmpty) {
      return _EmptyGoalCard();
    }

    return _ActiveGoalDisplay(goal: activeGoals.first);
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
                  style: Theme.of(context).textTheme.titleLarge,
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
    final resolvedIcon = GoalIcons.resolve(goal.icon);
    final progress = goal.targetAmount <= 0
        ? 0.0
        : (goal.currentAmount / goal.targetAmount).clamp(0.0, 1.0);
    final percentage = (progress * 100).round();
    final daysRemaining = _daysRemaining(goal.deadline);

    return GlassCard(
      glowColor: AppColors.purple,
      radius: 24,
      child: Row(
        children: [
          Container(
            width: 4,
            height: 110,
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        goal.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: resolvedIcon.color.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        resolvedIcon.icon,
                        color: resolvedIcon.color,
                        size: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      goal.deadline == null
                          ? LucideIcons.calendarDays
                          : LucideIcons.clock3,
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
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                          children: [
                            TextSpan(
                              text: formatBdtAmount(
                                goal.currentAmount,
                                fractionDigits: 0,
                              ),
                            ),
                            TextSpan(
                              text:
                                  ' / ${formatBdtAmount(goal.targetAmount, fractionDigits: 0)}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Text(
                      '$percentage%',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.teal,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  builder: (context, animatedValue, _) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: SizedBox(
                        height: 8,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: ColoredBox(
                                color: Colors.white.withValues(alpha: 0.06),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: animatedValue,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [AppColors.teal, AppColors.blue],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.teal.withValues(
                                        alpha: 0.32,
                                      ),
                                      blurRadius: 12,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
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
