import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/shimmer_skeleton.dart';
import '../../../data/models/financial_summaries.dart';
import '../../../providers/providers.dart';

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
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.teal,
          onRefresh: _refreshMonthlyAnalytics,
          child: analyticsAsync.when(
            loading: () => const _MonthlySkeleton(),
            error: (error, stackTrace) => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 180),
                Center(
                  child: Text(
                    'Could not load monthly analytics',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.coral,
                    ),
                  ),
                ),
              ],
            ),
            data: (analytics) {
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
                        _TopBar(
                          onSettingsTap: () =>
                              context.push(AppRoute.settings.path),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        _MonthNavigator(
                          month: _visibleMonth,
                          onPrevious: () => _changeMonth(-1),
                          onNext: _isCurrentMonth
                              ? null
                              : () => _changeMonth(1),
                        ),
                        const SizedBox(height: AppSpacing.section),
                        if (analytics.transactionCount == 0)
                          const SizedBox.shrink()
                        else ...[
                          _MonthlyMetricCard(
                                title: 'TOTAL INCOME',
                                amount: analytics.summary.income,
                                gradient: AppColors.incomeCardGradient,
                                accentColor: AppColors.teal,
                                borderColor: AppColors.teal.withValues(
                                  alpha: 0.2,
                                ),
                                chipLabel: _formatDeltaLabel(
                                  analytics.incomeDelta,
                                ),
                                chipIcon: analytics.incomeDelta >= 0
                                    ? LucideIcons.trendingUp
                                    : LucideIcons.trendingDown,
                              )
                              .animate()
                              .fadeIn(duration: 240.ms)
                              .slideY(
                                begin: 0.08,
                                end: 0,
                                duration: 240.ms,
                                curve: Curves.easeOutCubic,
                              ),
                          const SizedBox(height: 14),
                          _MonthlyMetricCard(
                                title: 'TOTAL EXPENSES',
                                amount: analytics.summary.expenses,
                                gradient: AppColors.expenseCardGradient,
                                accentColor: Colors.white,
                                borderColor: Colors.white.withValues(
                                  alpha: 0.2,
                                ),
                                chipLabel: _formatDeltaLabel(
                                  analytics.expenseDelta,
                                ),
                                chipIcon: analytics.expenseDelta >= 0
                                    ? LucideIcons.trendingUp
                                    : LucideIcons.trendingDown,
                              )
                              .animate()
                              .fadeIn(duration: 240.ms, delay: 60.ms)
                              .slideY(
                                begin: 0.08,
                                end: 0,
                                duration: 240.ms,
                                delay: 60.ms,
                                curve: Curves.easeOutCubic,
                              ),
                          const SizedBox(height: 14),
                          _MonthlyMetricCard(
                                title: 'AMOUNT SAVED',
                                amount: analytics.summary.saved,
                                gradient: AppColors.savingsCardGradient,
                                accentColor: AppColors.softPurple,
                                borderColor: AppColors.softPurple.withValues(
                                  alpha: 0.2,
                                ),
                                chipLabel: _formatSavingsRateLabel(
                                  analytics.savingsRate,
                                ),
                                chipIcon: analytics.savingsRate < 0
                                    ? LucideIcons.trendingDown
                                    : LucideIcons.shield,
                                chipColor: analytics.savingsRate < 0
                                    ? AppColors.coral
                                    : Colors.white,
                              )
                              .animate()
                              .fadeIn(duration: 240.ms, delay: 120.ms)
                              .slideY(
                                begin: 0.08,
                                end: 0,
                                duration: 240.ms,
                                delay: 120.ms,
                                curve: Curves.easeOutCubic,
                              ),
                          const SizedBox(height: AppSpacing.section),
                          _SectionTitle(
                            title: 'Where your money went',
                            trailing: null,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _CategoryDonutCard(
                                analytics: analytics,
                                onViewAll: () => context.go(
                                  '${AppRoute.transactions.path}?month=${_formatMonthQuery(_visibleMonth)}',
                                ),
                                onCategoryTap: (item) {
                                  final monthParam = _formatMonthQuery(_visibleMonth);
                                  final catParam = item.categoryId != null
                                      ? '&categoryId=${item.categoryId}'
                                      : '';
                                  context.go(
                                    '${AppRoute.transactions.path}?month=$monthParam$catParam',
                                  );
                                },
                              )
                              .animate()
                              .fadeIn(duration: 260.ms, delay: 180.ms)
                              .slideY(
                                begin: 0.08,
                                end: 0,
                                duration: 260.ms,
                                delay: 180.ms,
                                curve: Curves.easeOutCubic,
                              ),
                          const SizedBox(height: AppSpacing.section),
                          _SectionTitle(
                            title: 'Category Details',
                            trailing: 'SORTED BY VOLUME',
                          ),
                          const SizedBox(height: AppSpacing.md),
                          if (analytics.categories.isEmpty)
                            const GlassCard(
                              radius: 20,
                              child: Text(
                                'No expense categories in this month.',
                              ),
                            )
                          else
                            for (
                              var i = 0;
                              i < analytics.categories.length;
                              i++
                            ) ...[
                              _CategoryDetailTile(
                                    item: analytics.categories[i],
                                    highlightAsTop: i == 0,
                                  )
                                  .animate()
                                  .fadeIn(
                                    duration: 220.ms,
                                    delay: (220 + (i * 40)).ms,
                                  )
                                  .slideX(
                                    begin: 0.04,
                                    end: 0,
                                    duration: 220.ms,
                                    delay: (220 + (i * 40)).ms,
                                    curve: Curves.easeOutCubic,
                                  ),
                              if (i != analytics.categories.length - 1)
                                const SizedBox(height: 12),
                            ],
                        ],
                      ]),
                    ),
                  ),
                  if (analytics.transactionCount == 0)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          0,
                          AppSpacing.md,
                          132,
                        ),
                        child: Center(
                          child: EmptyState(
                            icon: LucideIcons.calendarDays,
                            title: 'No data for this month.',
                            message:
                                'Swipe or tap the arrows to explore another month.',
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
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

  String _formatDeltaLabel(double value) {
    final sign = value > 0
        ? '+'
        : value < 0
        ? '-'
        : '';
    final capped = value.abs().clamp(0.0, 9.99);
    final percent = (capped * 100).toStringAsFixed(0);
    final overflow = value.abs() > 9.99 ? '>' : '';
    return '$sign$overflow$percent% FROM LAST MONTH';
  }

  String _formatSavingsRateLabel(double value) {
    final percent = (value.abs() * 100).toStringAsFixed(0);
    if (value < 0) {
      return '$percent% NET WITHDRAWAL';
    }

    return '$percent% SAVINGS RATE';
  }

  String _formatMonthQuery(DateTime month) {
    return '${month.year}-${month.month.toString().padLeft(2, '0')}';
  }

  Future<void> _refreshMonthlyAnalytics() async {
    ref.invalidate(transactionsProvider);
    ref.invalidate(categoriesProvider);
    await Future.wait([
      ref.refresh(transactionsProvider.future),
      ref.refresh(categoriesProvider.future),
    ]);
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
              SkeletonCard(height: 64, radius: 20),
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

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onSettingsTap});

  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        const SizedBox(width: 8),
        RichText(
          text: TextSpan(
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
            children: const [
              TextSpan(
                text: 'Spend',
                style: TextStyle(color: AppColors.purple),
              ),
              TextSpan(
                text: 'Split',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: onSettingsTap,
          icon: const Icon(LucideIcons.settings),
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
    return Column(
      children: [
        Text(
          'FISCAL PERIOD',
          style: theme.textTheme.labelMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: onPrevious,
              icon: const Icon(LucideIcons.chevronLeft, color: AppColors.teal),
            ),
            const SizedBox(width: 8),
            Text(
              formatMonthYear(month).toUpperCase(),
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: onNext,
              icon: const Icon(LucideIcons.chevronRight, color: AppColors.teal),
            ),
          ],
        ),
      ],
    );
  }
}

class _MonthlyMetricCard extends StatelessWidget {
  const _MonthlyMetricCard({
    required this.title,
    required this.amount,
    required this.gradient,
    required this.accentColor,
    required this.borderColor,
    required this.chipLabel,
    required this.chipIcon,
    this.chipColor = Colors.white,
  });

  final String title;
  final double amount;
  final Gradient gradient;
  final Color accentColor;
  final Color borderColor;
  final String chipLabel;
  final IconData chipIcon;
  final Color chipColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.labelMedium?.copyWith(
                color: accentColor.withValues(alpha: 0.72),
              ),
            ),
            const SizedBox(height: 10),
            AnimatedAmountText(
              value: amount,
              formatter: (value) => formatBdtAmount(value, fractionDigits: 0),
              textStyle: theme.textTheme.displaySmall?.copyWith(
                color: accentColor,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(chipIcon, size: 14, color: chipColor),
                const SizedBox(width: 8),
                Text(
                  chipLabel,
                  style: theme.textTheme.labelSmall?.copyWith(color: chipColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.teal,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 10),
        Text(title, style: theme.textTheme.titleMedium),
        const Spacer(),
        if (trailing != null)
          Text(
            trailing!,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
      ],
    );
  }
}

class _CategoryDonutCard extends StatelessWidget {
  const _CategoryDonutCard({
    required this.analytics,
    required this.onViewAll,
    this.onCategoryTap,
  });

  final MonthlyAnalytics analytics;
  final VoidCallback onViewAll;
  final void Function(MonthlyCategoryBreakdown)? onCategoryTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (analytics.categories.isEmpty) {
      return GlassCard(
        radius: 24,
        glowColor: AppColors.blue,
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text('No expense data yet', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Add expense transactions to see the category breakdown.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 18),
            InkWell(
              onTap: onViewAll,
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Text(
                  'View all →',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.teal,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            boxShadow: [
              BoxShadow(
                color: AppColors.background.withValues(alpha: 0.42),
                blurRadius: 26,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
            child: SizedBox(
              height: 300,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 0,
                      centerSpaceRadius: 96,
                      startDegreeOffset: -90,
                      pieTouchData: PieTouchData(
                        touchCallback: (event, response) {
                          if (event is FlTapUpEvent &&
                              response?.touchedSection != null &&
                              onCategoryTap != null) {
                            final idx = response!
                                .touchedSection!.touchedSectionIndex;
                            if (idx >= 0 &&
                                idx < analytics.categories.length) {
                              onCategoryTap!(analytics.categories[idx]);
                            }
                          }
                        },
                      ),
                      sections: [
                        for (var i = 0; i < analytics.categories.length; i++)
                          PieChartSectionData(
                            value: analytics.categories[i].amount,
                            color: i == 0
                                ? AppColors.teal
                                : Color(analytics.categories[i].colorValue),
                            radius: 30,
                            showTitle: false,
                          ),
                      ],
                    ),
                    swapAnimationDuration: const Duration(milliseconds: 700),
                    swapAnimationCurve: Curves.easeOutCubic,
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'TOP CATEGORY',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondary,
                          letterSpacing: 4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        analytics.topCategoryName ?? 'None',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceDim,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${analytics.transactionCount} transactions this month',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'LAST SYNCED: LOCAL ONLY',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondary.withValues(alpha: 0.7),
                          letterSpacing: 3,
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: onViewAll,
                  borderRadius: BorderRadius.circular(999),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View all',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: AppColors.blue,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          LucideIcons.arrowRight,
                          size: 22,
                          color: AppColors.blue,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryDetailTile extends StatelessWidget {
  const _CategoryDetailTile({required this.item, required this.highlightAsTop});

  final MonthlyCategoryBreakdown item;
  final bool highlightAsTop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = highlightAsTop ? AppColors.teal : Color(item.colorValue);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDim,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: AppColors.background.withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 22, 14),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [color, color.withValues(alpha: 0.42)],
                ),
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.18),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _categoryClassification(item.name),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatBdtAmount(item.amount, fractionDigits: 0),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${(item.share * 100).toStringAsFixed(1)}% OF TOTAL',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _categoryClassification(String name) {
  final normalized = name.toLowerCase();
  if (normalized.contains('housing') || normalized.contains('utilit')) {
    return 'RECURRING';
  }
  if (normalized.contains('life') ||
      normalized.contains('food') ||
      normalized.contains('dining') ||
      normalized.contains('shopping')) {
    return 'FLEXIBLE';
  }
  if (normalized.contains('transport') ||
      normalized.contains('fuel') ||
      normalized.contains('travel')) {
    return 'VARIABLE';
  }
  return 'ONE-TIME';
}
