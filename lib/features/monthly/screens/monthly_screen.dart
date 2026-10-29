import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:spendsplit/core/icons/lucide_icons.dart';

import '../../../core/widgets/large_title_page.dart';
import '../../../core/constants/categories.dart';
import '../../../core/constants/enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/budget_progress_bar.dart';
import '../../../core/widgets/panel.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/shimmer_skeleton.dart';
import '../../../data/models/financial_summaries.dart';
import '../../../providers/providers.dart';
import '../widgets/monthly_budget_card.dart';

class MonthlyScreen extends ConsumerStatefulWidget {
  const MonthlyScreen({super.key});

  @override
  ConsumerState<MonthlyScreen> createState() => _MonthlyScreenState();
}

class _MonthlyScreenState extends ConsumerState<MonthlyScreen> {
  late DateTime _visibleMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final analyticsAsync = ref.watch(monthlyAnalyticsProvider(_visibleMonth));

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity.abs() < 220) return;
        // Block swipe-forward on current month
        if (velocity < 0 && _isCurrentMonth) return;
        _changeMonth(velocity < 0 ? 1 : -1);
      },
      child: analyticsAsync.when(
        loading: () => const _MonthlySkeleton(),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text(
              "This month couldn't load. Close and reopen the app to try again.",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ),
        data: (analytics) {
          final monthQuery = _formatMonthQuery(_visibleMonth);
          return LargeTitlePage(
            title: 'Monthly',
            trailing: BarIconButton(
              icon: LucideIcons.settings,
              tooltip: 'Settings',
              onPressed: () => context.push(AppRoute.settings.path),
            ),
            slivers: [
              PageBody(
                children: [
                  _MonthNavigator(
                    month: _visibleMonth,
                    onPrevious: () => _changeMonth(-1),
                    onNext: _isCurrentMonth ? null : () => _changeMonth(1),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (analytics.transactionCount == 0) ...[
                    const EmptyState(
                      icon: LucideIcons.calendarDays,
                      title: 'Nothing recorded this month',
                      message:
                          'Swipe sideways or use the arrows to see another month.',
                    ),
                    const SizedBox(height: AppSpacing.section),
                    MonthlyBudgetCard(
                      spent: analytics.summary.expenses,
                      month: _visibleMonth,
                    ),
                  ] else ...[
                    _FiguresTable(
                      analytics: analytics,
                      previousMonth: DateTime(
                        _visibleMonth.year,
                        _visibleMonth.month - 1,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    MonthlyBudgetCard(
                      spent: analytics.summary.expenses,
                      month: _visibleMonth,
                    ),
                    const SizedBox(height: AppSpacing.section),
                    SectionHeader(
                      'Where it went',
                      action: 'All entries',
                      onAction: () => context.go(
                        '${AppRoute.transactions.path}?month=$monthQuery',
                      ),
                    ),
                    if (analytics.categories.isEmpty)
                      Panel(
                        color: AppColors.surfaceRaised,
                        child: Text(
                          'No spending recorded this month.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      )
                    else ...[
                      _CategoryShareBar(categories: analytics.categories),
                      const SizedBox(height: AppSpacing.sm),
                      Panel(
                        color: AppColors.surfaceRaised,
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            for (
                              var i = 0;
                              i < analytics.categories.length;
                              i++
                            ) ...[
                              if (i > 0)
                                Container(
                                  height: 0.5,
                                  margin: const EdgeInsets.only(left: 36),
                                  color: AppColors.outlineVariant,
                                ),
                              _CategoryRow(
                                item: analytics.categories[i],
                                pace: monthPaceFraction(_visibleMonth),
                                onTap:
                                    analytics.categories[i].categoryId == null
                                    ? null
                                    : () => _editCategoryBudget(
                                        analytics.categories[i],
                                      ),
                                onLongPress: () {
                                  final id = analytics.categories[i].categoryId;
                                  context.go(
                                    '${AppRoute.transactions.path}?month=$monthQuery'
                                    '${id == null ? '' : '&categoryId=$id'}',
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Tap a category to set its monthly budget. '
                        'Press and hold to see its entries.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ],
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _visibleMonth.year == now.year && _visibleMonth.month == now.month;
  }

  void _changeMonth(int monthOffset) {
    setState(() {
      _visibleMonth = DateTime(
        _visibleMonth.year,
        _visibleMonth.month + monthOffset,
      );
    });
  }

  String _formatMonthQuery(DateTime month) {
    return '${month.year}-${month.month.toString().padLeft(2, '0')}';
  }

  Future<void> _editCategoryBudget(MonthlyCategoryBreakdown item) async {
    final id = item.categoryId;
    if (id == null) return;
    final controller = TextEditingController(
      text: item.monthlyLimit == null
          ? ''
          : item.monthlyLimit!.toStringAsFixed(0),
    );
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        title: Text('${item.name} budget'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Monthly limit (৳)',
            helperText: 'Leave empty to remove the budget.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final raw = controller.text.replaceAll(',', '').trim();
              if (raw.isEmpty) {
                Navigator.of(ctx).pop(-1.0); // sentinel: clear
                return;
              }
              final value = double.tryParse(raw);
              if (value == null || !value.isFinite || value < 0) return;
              Navigator.of(ctx).pop(value);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result == null) return;
    final dao = ref.read(appDatabaseProvider).categoryBudgetDao;
    if (result < 0) {
      await dao.clearBudget(id);
    } else {
      await dao.setBudget(id, result);
    }
  }
}

class _MonthlySkeleton extends StatelessWidget {
  const _MonthlySkeleton();

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
              SkeletonCard(height: 76, radius: 20),
              SizedBox(height: 28),
              SkeletonCard(height: 108, radius: 16),
              SizedBox(height: 14),
              SkeletonCard(height: 108, radius: 16),
              SizedBox(height: 14),
              SkeletonCard(height: 108, radius: 16),
              SizedBox(height: 28),
              SkeletonCard(height: 280, radius: 24),
              SizedBox(height: 28),
              SkeletonCard(height: 94, radius: 20),
              SizedBox(height: 12),
              SkeletonCard(height: 94, radius: 20),
            ],
          ),
        ),
      ],
    );
  }
}

class _MonthNavigator extends StatelessWidget {
  const _MonthNavigator({
    required this.month,
    required this.onPrevious,
    this.onNext,
  });

  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Panel(
      color: AppColors.surfaceRaised,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Previous month',
            onPressed: onPrevious,
            icon: const Icon(LucideIcons.chevronLeft),
          ),
          Expanded(
            child: Text(
              formatMonthYear(month),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
          ),
          IconButton(
            tooltip: 'Next month',
            onPressed: onNext,
            icon: const Icon(LucideIcons.chevronRight),
          ),
        ],
      ),
    );
  }
}

/// Income, spending and savings for the month, each with how it moved
/// against the month before.
class _FiguresTable extends StatelessWidget {
  const _FiguresTable({required this.analytics, required this.previousMonth});

  final MonthlyAnalytics analytics;
  final DateTime previousMonth;

  @override
  Widget build(BuildContext context) {
    final summary = analytics.summary;
    final prev = DateFormat('MMMM').format(previousMonth);
    final rate = analytics.savingsRate;
    return Panel(
      color: AppColors.surfaceRaised,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _FigureRow(
            label: 'Income',
            value: '+${formatBdtAmount(summary.income)}',
            color: AppColors.income,
            caption: _delta(analytics.incomeDelta, prev),
          ),
          const _Hairline(),
          _FigureRow(
            label: 'Spent',
            value: '−${formatBdtAmount(summary.expenses)}',
            color: AppColors.spend,
            caption: _delta(analytics.expenseDelta, prev),
          ),
          const _Hairline(),
          _FigureRow(
            label: 'Saved',
            value: formatBdtAmount(summary.saved),
            color: AppColors.savings,
            caption: rate < 0
                ? 'More taken out of savings than put in'
                : '${(rate * 100).round()}% of income',
          ),
        ],
      ),
    );
  }

  static String _delta(double value, String previous) {
    if (value == 0) return 'Same as $previous';
    final pct = (value.abs().clamp(0.0, 9.99) * 100).round();
    final over = value.abs() > 9.99 ? 'over ' : '';
    return '$over$pct% ${value > 0 ? 'more' : 'less'} than $previous';
  }
}

class _FigureRow extends StatelessWidget {
  const _FigureRow({
    required this.label,
    required this.value,
    required this.color,
    required this.caption,
  });

  final String label;
  final String value;
  final Color color;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodyLarge),
                Text(caption, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _Hairline extends StatelessWidget {
  const _Hairline();

  @override
  Widget build(BuildContext context) => Container(
    height: 0.5,
    margin: const EdgeInsets.only(left: 16),
    color: AppColors.outlineVariant,
  );
}

/// The month's spending as one stacked bar, a segment per category.
class _CategoryShareBar extends StatelessWidget {
  const _CategoryShareBar({required this.categories});

  final List<MonthlyCategoryBreakdown> categories;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        height: 14,
        child: Row(
          children: [
            for (var i = 0; i < categories.length; i++) ...[
              if (i > 0) const SizedBox(width: 2),
              Expanded(
                flex: (categories[i].share * 1000).round().clamp(1, 1000),
                child: ColoredBox(
                  color: categoryColor(categories[i].colorValue),
                  child: const SizedBox.expand(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.item,
    this.pace,
    this.onTap,
    this.onLongPress,
  });

  final MonthlyCategoryBreakdown item;

  /// Share of the month gone (current month only), for the pace tick.
  final double? pace;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final limit = item.monthlyLimit;
    final hasLimit = limit != null && limit > 0;
    final overBudget = hasLimit && item.amount > limit;
    final pace = this.pace;
    final aheadOfPace = hasLimit && pace != null && item.amount > limit * pace;
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  color: categoryColor(item.colorValue),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
                Text(
                  formatBdtAmount(item.amount),
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 2),
              child: Text(
                hasLimit
                    ? overBudget
                          ? '${formatBdtAmount(item.amount - limit)} over a ${formatBdtAmount(limit)} budget'
                          : '${formatBdtAmount(limit - item.amount)} left of ${formatBdtAmount(limit)}'
                    : '${(item.share * 100).round()}% of spending',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: overBudget ? AppColors.spend : null,
                ),
              ),
            ),
            if (hasLimit) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 20),
                child: BudgetProgressBar(
                  used: item.amount / limit,
                  pace: pace,
                  height: 4,
                  backgroundColor: AppColors.background,
                  color: overBudget
                      ? AppColors.spend
                      : aheadOfPace
                      ? AppColors.warning
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
