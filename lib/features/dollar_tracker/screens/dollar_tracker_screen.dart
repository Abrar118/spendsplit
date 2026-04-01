import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/shimmer_skeleton.dart';
import '../../../data/database/app_database.dart';
import '../../../data/models/app_settings.dart';
import '../../../providers/providers.dart';
import '../widgets/add_dollar_expense_sheet.dart';
import '../widgets/dollar_header_card.dart';
import '../widgets/dollar_transaction_tile.dart';

class DollarTrackerScreen extends ConsumerStatefulWidget {
  const DollarTrackerScreen({super.key});

  @override
  ConsumerState<DollarTrackerScreen> createState() =>
      _DollarTrackerScreenState();
}

class _DollarTrackerScreenState extends ConsumerState<DollarTrackerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final settings = ref.read(appSettingsProvider);
      if (settings.needsDollarLimitRefresh) {
        _showYearRolloverDialog(settings);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final summaryAsync = ref.watch(
      dollarTrackerSummaryForYearProvider(settings.dollarLimitYear),
    );
    final expensesAsync = ref.watch(
      dollarExpensesForYearProvider(settings.dollarLimitYear),
    );
    final categories = {
      for (final category
          in ref.watch(dollarCategoriesProvider).valueOrNull ??
              const <CategoriesTableData>[])
        category.id: category,
    };

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.teal,
          onRefresh: () async {
            ref.invalidate(
              dollarExpensesForYearProvider(settings.dollarLimitYear),
            );
            final _ = await ref.refresh(
              dollarExpensesForYearProvider(settings.dollarLimitYear).future,
            );
          },
          child: ListView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              120,
            ),
            children: [
              _TopBar(year: settings.dollarLimitYear),
              const SizedBox(height: AppSpacing.xl),
              summaryAsync.when(
                loading: () => const _SummarySkeleton(),
                error: (error, _) => _ErrorCard(
                  title: 'Unable to load dollar summary',
                  onRetry: () => ref.invalidate(
                    dollarExpensesForYearProvider(settings.dollarLimitYear),
                  ),
                ),
                data: (summary) => DollarHeaderCard(summary: summary),
              ),
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton.icon(
                onPressed: () async {
                  await showAddDollarExpenseSheet(context);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.teal,
                  side: const BorderSide(color: AppColors.teal),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                icon: const Icon(LucideIcons.plus, size: 18),
                label: const Text('+ ADD EXPENSE'),
              ),
              const SizedBox(height: AppSpacing.section),
              Row(
                children: [
                  Text(
                    'Recent Expenses',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  summaryAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (summary) => _YearPill(
                      spentYtd: summary.spentYtd,
                      year: summary.year,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              expensesAsync.when(
                loading: () => const _ExpenseListSkeleton(),
                error: (error, _) => _ErrorCard(
                  title: 'Unable to load dollar expenses',
                  onRetry: () => ref.invalidate(
                    dollarExpensesForYearProvider(settings.dollarLimitYear),
                  ),
                ),
                data: (expenses) {
                  if (expenses.isEmpty) {
                    return const _EmptyDollarExpensesState()
                        .animate()
                        .fadeIn(duration: 280.ms)
                        .slideY(
                          begin: 0.08,
                          end: 0,
                          duration: 280.ms,
                          curve: Curves.easeOutCubic,
                        );
                  }

                  return Column(
                    children: [
                      for (final expense in expenses) ...[
                        DollarTransactionTile(
                          expense: expense,
                          category: categories[expense.categoryId],
                          onTap: () => showAddDollarExpenseSheet(
                            context,
                            existingExpense: expense,
                          ),
                          onDelete: () => _deleteExpense(expense),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteExpense(DollarExpensesTableData expense) async {
    final repository = ref.read(dollarTrackerRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);

    await repository.deleteExpenseById(expense.id);

    var undoFired = false;
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 3),
        content: const Text('Deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            if (undoFired) return;
            undoFired = true;
            await repository.createExpenseWithId(expense);
          },
        ),
      ),
    );
  }

  Future<void> _showYearRolloverDialog(AppSettings settings) async {
    final currentYear = DateTime.now().year;

    final action = await showDialog<_YearRolloverAction>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _YearRolloverDialog(
        currentYear: currentYear,
        previousYear: settings.dollarLimitYear,
        initialLimit: settings.dollarAnnualLimit,
      ),
    );

    if (!mounted || action == null) {
      return;
    }

    final settingsController = ref.read(appSettingsProvider.notifier);
    switch (action) {
      case _KeepExistingLimit():
        await settingsController.setDollarLimitYear(currentYear);
      case _UpdateDollarLimit(limit: final limit):
        await settingsController.setDollarAnnualLimit(limit);
        await settingsController.setDollarLimitYear(currentYear);
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Dollar allowance is now set for $currentYear.')),
    );
  }
}

class _YearRolloverDialog extends StatefulWidget {
  const _YearRolloverDialog({
    required this.currentYear,
    required this.previousYear,
    required this.initialLimit,
  });

  final int currentYear;
  final int previousYear;
  final double initialLimit;

  @override
  State<_YearRolloverDialog> createState() => _YearRolloverDialogState();
}

class _YearRolloverDialogState extends State<_YearRolloverDialog> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialLimit == 0
          ? ''
          : widget.initialLimit.toStringAsFixed(
              widget.initialLimit % 1 == 0 ? 0 : 2,
            ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      backgroundColor: AppColors.surfaceLight,
      title: const Text('New Dollar Tracking Year'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your USD allowance is still assigned to ${widget.previousYear}. Confirm the carry-over limit or update it for ${widget.currentYear}.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              prefixText: r'$ ',
              hintText: '0',
              labelText: 'Annual limit for ${widget.currentYear}',
              errorText: _errorText,
            ),
            onChanged: (_) {
              if (_errorText != null) {
                setState(() {
                  _errorText = null;
                });
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(_YearRolloverAction.keepExisting),
          child: const Text('Keep Existing'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save New Limit')),
      ],
    );
  }

  void _submit() {
    final value = double.tryParse(_controller.text.trim());
    if (value == null || value < 0) {
      setState(() {
        _errorText = 'Enter a valid limit.';
      });
      return;
    }

    Navigator.of(context).pop(_YearRolloverAction.updateLimit(value));
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.year});

  final int year;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(LucideIcons.chevronLeft),
            ),
          ),
          Text('Dollar Tracker', style: theme.textTheme.titleLarge),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Text(
                year.toString(),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _YearPill extends StatelessWidget {
  const _YearPill({required this.spentYtd, required this.year});

  final double spentYtd;
  final int year;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.blue.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.blue.withValues(alpha: 0.25)),
      ),
      child: Text(
        '${formatUsdAmount(spentYtd, fractionDigits: 0)} in $year',
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(color: AppColors.blue),
      ),
    );
  }
}

class _EmptyDollarExpensesState extends StatelessWidget {
  const _EmptyDollarExpensesState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      glowColor: AppColors.blue,
      radius: 24,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.blue.withValues(alpha: 0.12),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: const [
                  Icon(LucideIcons.globe2, color: AppColors.blue, size: 36),
                  Positioned(
                    right: 18,
                    bottom: 22,
                    child: Icon(
                      LucideIcons.badgeDollarSign,
                      color: AppColors.amber,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No foreign expenses tracked yet.',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Add your first USD expense to keep tuition, software, and travel spending isolated from your BDT totals.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummarySkeleton extends StatelessWidget {
  const _SummarySkeleton();

  @override
  Widget build(BuildContext context) {
    return const ShimmerSkeleton(child: SkeletonCard(height: 172, radius: 30));
  }
}

class _ExpenseListSkeleton extends StatelessWidget {
  const _ExpenseListSkeleton();

  @override
  Widget build(BuildContext context) {
    return const ShimmerSkeleton(
      child: Column(
        children: [
          SkeletonCard(height: 82, radius: 22),
          SizedBox(height: AppSpacing.sm),
          SkeletonCard(height: 82, radius: 22),
          SizedBox(height: AppSpacing.sm),
          SkeletonCard(height: 82, radius: 22),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.title, required this.onRetry});

  final String title;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      glowColor: AppColors.coral,
      radius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Pull to refresh or try again now.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.coral,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

sealed class _YearRolloverAction {
  const _YearRolloverAction();

  factory _YearRolloverAction.keepExisting() = _KeepExistingLimit;
  factory _YearRolloverAction.updateLimit(double limit) = _UpdateDollarLimit;
}

class _KeepExistingLimit extends _YearRolloverAction {
  const _KeepExistingLimit();
}

class _UpdateDollarLimit extends _YearRolloverAction {
  const _UpdateDollarLimit(this.limit);

  final double limit;
}
