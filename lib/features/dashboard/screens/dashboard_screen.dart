import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/constants/enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../providers/providers.dart';
import '../../widget/widget_data_service.dart';
import '../widgets/active_goal_card.dart';
import '../widgets/balance_card.dart';
import '../widgets/dollar_summary_card.dart';
import '../widgets/monthly_snapshot_row.dart';
import '../widgets/spending_chart.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final balanceSummary = ref.watch(balanceSummaryProvider);
    final currentMonthSummary = ref.watch(currentMonthSummaryProvider);
    final transactions = ref.watch(transactionsProvider);
    final goals = ref.watch(savingsGoalsProvider);
    final dollarSummary = ref.watch(dollarTrackerSummaryProvider);
    final settings = ref.watch(appSettingsProvider);

    final loading =
        balanceSummary.isLoading ||
        currentMonthSummary.isLoading ||
        transactions.isLoading ||
        goals.isLoading ||
        dollarSummary.isLoading;

    // Push balance data to home screen widget
    final insightsAsync = ref.watch(savingsInsightsProvider);
    if (balanceSummary.hasValue) {
      final savingsPercent =
          insightsAsync.valueOrNull?.monthOverMonthDelta ?? 0;
      WidgetDataService.updateBalance(
        availableBalance: balanceSummary.value!.availableBalance,
        savingsPercent: savingsPercent * 100,
      );
    }

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: AppColors.teal,
        onRefresh: () async {
          ref.invalidate(transactionsProvider);
          ref.invalidate(balanceSummaryProvider);
          ref.invalidate(currentMonthSummaryProvider);
          ref.invalidate(savingsGoalsProvider);
          ref.invalidate(dollarTrackerSummaryProvider);
          ref.invalidate(dollarExpensesProvider);
          await Future.wait([
            ref.read(transactionsProvider.future),
            ref.read(savingsGoalsProvider.future),
            ref.read(dollarExpensesProvider.future),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            132,
          ),
          children: [
            // --- Top bar ---
            Row(
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
                  onPressed: () => context.push(AppRoute.settings.path),
                  icon: const Icon(LucideIcons.settings),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            if (loading)
              const _DashboardSkeleton()
            else ...[
              balanceSummary.when(
                data: (summary) => BalanceCard(
                  summary: summary,
                  cardNumber: settings.cardNumber,
                  onEditCardNumber: () =>
                      _showCardNumberEditor(context: context, ref: ref),
                ),
                error: (error, stackTrace) => const _SectionError(),
                loading: () => const _DashboardSkeleton(),
              ),
              const SizedBox(height: AppSpacing.section),
              currentMonthSummary.when(
                data: (summary) => MonthlySnapshotRow(summary: summary),
                error: (error, stackTrace) => const _SectionError(),
                loading: () => const _SnapshotSkeleton(),
              ),
              const SizedBox(height: AppSpacing.section),
              transactions.when(
                data: (entries) => SpendingChart(
                  transactions: entries,
                  onDetailsTap: () => context.go(AppRoute.monthly.path),
                ),
                error: (error, stackTrace) => const _SectionError(),
                loading: () => const _CardSkeleton(height: 280),
              ),
              const SizedBox(height: AppSpacing.section),
              goals.when(
                data: (goalsList) => ActiveGoalCard(goals: goalsList),
                error: (error, stackTrace) => const _SectionError(),
                loading: () => const _CardSkeleton(height: 126),
              ),
              const SizedBox(height: AppSpacing.section),
              dollarSummary.when(
                data: (summary) => DollarSummaryCard(
                  summary: summary,
                  onTap: () => context.push(AppRoute.dollarTracker.path),
                ),
                error: (error, stackTrace) => const _SectionError(),
                loading: () => const _CardSkeleton(height: 210),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showCardNumberEditor({
    required BuildContext context,
    required WidgetRef ref,
  }) async {
    final currentCardNumber = ref.read(appSettingsProvider).cardNumber;
    final didSave = await showDialog<bool>(
      context: context,
      builder: (_) => _CardNumberEditorDialog(
        initialDigits: currentCardNumber.replaceAll(RegExp(r'\D'), ''),
        onSave: (value) =>
            ref.read(appSettingsProvider.notifier).setCardNumber(value),
      ),
    );

    if (didSave != true || !context.mounted) return;

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Card number updated')));
    }
  }
}

class _CardNumberEditorDialog extends StatefulWidget {
  const _CardNumberEditorDialog({
    required this.initialDigits,
    required this.onSave,
  });

  final String initialDigits;
  final Future<void> Function(String value) onSave;

  @override
  State<_CardNumberEditorDialog> createState() =>
      _CardNumberEditorDialogState();
}

class _CardNumberEditorDialogState extends State<_CardNumberEditorDialog> {
  late final TextEditingController _controller;
  String? _errorText;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialDigits);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceLight,
      title: const Text('Edit Card Number'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Enter 12–19 digits. Only the first and last four will be visible.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            maxLength: 19,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              hintText: '4532756028418291',
              counterText: '',
              errorText: _errorText,
            ),
            onChanged: (_) {
              if (_errorText != null) {
                setState(() => _errorText = null);
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final value = _controller.text.trim();
    if (value.length < 12) {
      setState(() => _errorText = 'Enter at least 12 digits.');
      return;
    }

    setState(() => _saving = true);
    try {
      await widget.onSave(value);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _saving = false;
        _errorText = 'Failed to update card number';
      });
    }
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceLight,
      highlightColor: AppColors.surfaceContainerHighest,
      child: const Column(
        children: [
          _CardSkeleton(height: 250),
          SizedBox(height: 28),
          _SnapshotSkeleton(),
          SizedBox(height: 28),
          _CardSkeleton(height: 280),
          SizedBox(height: 28),
          _CardSkeleton(height: 126),
          SizedBox(height: 28),
          _CardSkeleton(height: 210),
        ],
      ),
    );
  }
}

class _SnapshotSkeleton extends StatelessWidget {
  const _SnapshotSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 112,
      child: Row(
        children: [
          Expanded(child: _CardSkeleton(height: 112)),
          SizedBox(width: 14),
          Expanded(child: _CardSkeleton(height: 112)),
          SizedBox(width: 14),
          Expanded(child: _CardSkeleton(height: 112)),
        ],
      ),
    );
  }
}

class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: GlassCard(
        child: Container(color: Colors.white.withValues(alpha: 0.04)),
      ),
    );
  }
}

class _SectionError extends StatelessWidget {
  const _SectionError();

  @override
  Widget build(BuildContext context) {
    return const GlassCard(
      child: SizedBox(
        height: 120,
        child: Center(child: Text('Could not load this section')),
      ),
    );
  }
}
