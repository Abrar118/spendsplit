import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:spendsplit/core/icons/lucide_icons.dart';

import '../../../core/constants/enums.dart';
import '../../../core/constants/goal_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/glass_card.dart';
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
            ? const Center(child: Text('Goal not found'))
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
    final icon = GoalIcons.resolve(goal.icon);
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
              onPressed: () => context.pop(),
              icon: const Icon(LucideIcons.chevronLeft),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                goal.name,
                style: theme.textTheme.titleLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Center(
          child: SizedBox(
            width: 168,
            height: 168,
            child: CustomPaint(
              painter: _RingPainter(progress: progress, color: icon.color),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(progress * 100).round()}%',
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      formatBdtAmount(goal.currentAmount, fractionDigits: 0),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      'of ${formatBdtAmount(goal.targetAmount, fractionDigits: 0)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.section),
        _ProjectionCard(goal: goal, projection: projection),
        const SizedBox(height: AppSpacing.section),
        Text(
          'CONTRIBUTIONS',
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppColors.textTertiary,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        if (linked.isEmpty)
          Text(
            'No contributions logged against this goal yet. Use "Add Contribution" from the goal menu.',
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

    if (projection.estimatedCompletion != null) {
      lines.add(
        'At ${formatBdtAmount(projection.weeklyRate, fractionDigits: 0)}/week, '
        'done ~${DateFormat('MMM yyyy').format(projection.estimatedCompletion!)}.',
      );
    } else {
      lines.add('Log a few contributions to project a completion date.');
    }

    final required = projection.requiredWeeklyForDeadline;
    if (required != null && required > 0) {
      lines.add(
        'Put aside ${formatBdtAmount(required, fractionDigits: 0)}/week to hit '
        'your ${DateFormat('MMM d').format(goal.deadline!)} deadline.',
      );
    }

    return GlassCard(
      glowColor: AppColors.purple,
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.trendingUp,
                size: 18,
                color: AppColors.purple,
              ),
              const SizedBox(width: 8),
              Text('Projection', style: theme.textTheme.titleMedium),
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
    final color = isWithdrawal ? AppColors.amber : AppColors.purple;
    final sign = isWithdrawal ? '-' : '+';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
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

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 12.0;
    final radius = (size.width - stroke) / 2;
    final center = size.center(Offset.zero);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.06);
    canvas.drawCircle(center, radius, track);

    if (progress <= 0) return;

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: (math.pi * 2) - (math.pi / 2),
        colors: [color, AppColors.teal],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      (math.pi * 2) * progress.clamp(0.0, 1.0),
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

/// Helper for callers that need the detail route path.
String goalDetailPath(int id) => '${AppRoute.goalDetail.path}/$id';
