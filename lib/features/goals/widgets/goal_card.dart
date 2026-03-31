import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/goal_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/database/app_database.dart';

class GoalCard extends StatelessWidget {
  const GoalCard({
    required this.goal,
    super.key,
    this.completed = false,
    this.onMenuSelected,
  });

  final SavingsGoalsTableData goal;
  final bool completed;
  final ValueChanged<GoalMenuAction>? onMenuSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = GoalIcons.resolve(goal.icon);
    final progress = goal.targetAmount <= 0
        ? 0.0
        : (goal.currentAmount / goal.targetAmount).clamp(0.0, 1.0);
    final percentage = (progress * 100).round();
    final subtitle = _buildSubtitle(goal.deadline);
    final displayCurrent = completed ? goal.targetAmount : goal.currentAmount;

    return Opacity(
      opacity: completed ? 0.72 : 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 3,
                        height: 44,
                        decoration: BoxDecoration(
                          color: completed ? AppColors.green : icon.color,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              goal.name,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.white.withValues(alpha: 0.92),
                                decoration: completed
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 4),
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
                                Expanded(
                                  child: Text(
                                    subtitle,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (onMenuSelected != null)
                        PopupMenuButton<GoalMenuAction>(
                          onSelected: onMenuSelected,
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: GoalMenuAction.edit,
                              child: Text('Edit'),
                            ),
                            if (!completed)
                              const PopupMenuItem(
                                value: GoalMenuAction.complete,
                                child: Text('Mark Complete'),
                              ),
                            const PopupMenuItem(
                              value: GoalMenuAction.delete,
                              child: Text('Delete'),
                            ),
                          ],
                          icon: const Icon(LucideIcons.moreVertical),
                        ),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: completed ? AppColors.green : icon.color,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (completed ? AppColors.green : icon.color)
                                  .withValues(alpha: 0.28),
                              blurRadius: 18,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(icon.icon, color: Colors.white, size: 19),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                            children: [
                              TextSpan(
                                text: formatBdtAmount(
                                  displayCurrent,
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
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: completed ? 1 : progress),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) {
                        return SizedBox(
                          height: 8,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: ColoredBox(
                                  color: Colors.white.withValues(alpha: 0.06),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: value,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: completed
                                          ? const [
                                              AppColors.green,
                                              AppColors.teal,
                                            ]
                                          : const [
                                              AppColors.teal,
                                              AppColors.blue,
                                            ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            (completed
                                                    ? AppColors.green
                                                    : AppColors.teal)
                                                .withValues(alpha: 0.35),
                                        blurRadius: 12,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _buildSubtitle(DateTime? deadline) {
    if (completed && goal.completedAt != null) {
      return 'Completed ${goal.completedAt!.day}/${goal.completedAt!.month}/${goal.completedAt!.year}';
    }

    if (deadline == null) {
      return 'No deadline';
    }

    final now = DateTime.now();
    final difference = deadline.difference(now).inDays;
    if (difference <= 0) {
      return 'Due now';
    }
    return '${math.max(1, difference)} days remaining';
  }
}

enum GoalMenuAction { edit, complete, delete }
