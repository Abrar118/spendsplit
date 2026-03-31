import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/shimmer_skeleton.dart';
import '../../../data/database/app_database.dart';
import '../../../providers/providers.dart';
import '../widgets/add_transaction_sheet.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../widgets/filter_chips_row.dart';
import '../widgets/transaction_tile.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key, this.initialMonth});

  final DateTime? initialMonth;

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  TransactionQuickFilter _quickFilter = TransactionQuickFilter.all;
  TransactionAdvancedFilters _advancedFilters =
      const TransactionAdvancedFilters();

  @override
  void initState() {
    super.initState();
    _advancedFilters = _filtersForMonth(widget.initialMonth);
  }

  @override
  void didUpdateWidget(covariant TransactionsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldMonth = oldWidget.initialMonth;
    final newMonth = widget.initialMonth;
    final hasChanged =
        oldMonth?.year != newMonth?.year || oldMonth?.month != newMonth?.month;

    if (hasChanged) {
      _advancedFilters = _filtersForMonth(newMonth);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final transactionsAsync = ref.watch(transactionsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 132),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Top bar: hamburger, centered title, filter icon ---
            Row(
              children: [
                const Icon(LucideIcons.menu),
                const Spacer(),
                Text('Transactions', style: theme.textTheme.titleLarge),
                const Spacer(),
                IconButton(
                  onPressed: categoriesAsync.hasValue
                      ? () => _openFilters(categoriesAsync.value!)
                      : null,
                  icon: Icon(
                    LucideIcons.listFilter,
                    color: _advancedFilters.hasActiveFilters
                        ? AppColors.teal
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            FilterChipsRow(
              selectedFilter: _quickFilter,
              onSelected: (value) {
                setState(() {
                  _quickFilter = value;
                });
              },
            ),
            const SizedBox(height: 20),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.teal,
                onRefresh: _refreshTransactions,
                child: transactionsAsync.when(
                  data: (transactions) {
                    final categoriesById = {
                      for (final category
                          in categoriesAsync.valueOrNull ??
                              const <CategoriesTableData>[])
                        category.id: category,
                    };
                    final filtered = _applyFilters(transactions);

                    if (filtered.isEmpty) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 120),
                          EmptyState(
                            icon: LucideIcons.wallet,
                            title: 'No transactions yet.',
                            message: 'Tap + to add your first one.',
                          ),
                        ],
                      );
                    }

                    final sections = _groupTransactions(filtered);

                    return CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        for (final section in sections) ...[
                          SliverPersistentHeader(
                            key: ValueKey('header_${section.dateKey}'),
                            pinned: true,
                            delegate: _DateHeaderDelegate(section.header),
                          ),
                          SliverList(
                            key: ValueKey('list_${section.dateKey}'),
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final transaction = section.transactions[index];
                              return Padding(
                                key: ValueKey(transaction.id),
                                padding: const EdgeInsets.only(bottom: 12),
                                child:
                                    TransactionTile(
                                          transaction: transaction,
                                          category:
                                              categoriesById[transaction
                                                  .categoryId],
                                          onTap: () => showAddTransactionSheet(
                                            context,
                                            existingTransaction: transaction,
                                          ),
                                          onDelete: () =>
                                              _deleteTransaction(transaction),
                                        )
                                        .animate()
                                        .fadeIn(
                                          duration: 200.ms,
                                          delay: (50 * index).ms,
                                        )
                                        .slideX(
                                          begin: 0.03,
                                          end: 0,
                                          duration: 200.ms,
                                          delay: (50 * index).ms,
                                          curve: Curves.easeOutCubic,
                                        ),
                              );
                            }, childCount: section.transactions.length),
                          ),
                        ],
                      ],
                    );
                  },
                  loading: () => const _TransactionsSkeleton(),
                  error: (error, _) => ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 180),
                      Center(
                        child: Text(
                          'Could not load transactions',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.coral,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<TransactionsTableData> _applyFilters(
    List<TransactionsTableData> transactions,
  ) {
    return transactions.where((transaction) {
      final type = TransactionType.fromDbValue(transaction.type);

      final matchesQuickFilter = switch (_quickFilter) {
        TransactionQuickFilter.all => true,
        TransactionQuickFilter.income => type == TransactionType.income,
        TransactionQuickFilter.expense => type == TransactionType.expense,
        TransactionQuickFilter.savings =>
          type == TransactionType.savingsDeposit ||
              type == TransactionType.savingsWithdrawal,
      };

      if (!matchesQuickFilter) return false;

      if (_advancedFilters.transactionTypes.isNotEmpty &&
          !_advancedFilters.transactionTypes.contains(type)) {
        return false;
      }

      if (_advancedFilters.categoryIds.isNotEmpty &&
          !_advancedFilters.categoryIds.contains(transaction.categoryId)) {
        return false;
      }

      if (_advancedFilters.startDate != null &&
          transaction.date.isBefore(_advancedFilters.startDate!)) {
        return false;
      }

      if (_advancedFilters.endDate != null) {
        final inclusiveEnd = DateTime(
          _advancedFilters.endDate!.year,
          _advancedFilters.endDate!.month,
          _advancedFilters.endDate!.day,
          23,
          59,
          59,
        );
        if (transaction.date.isAfter(inclusiveEnd)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  TransactionAdvancedFilters _filtersForMonth(DateTime? month) {
    if (month == null) {
      return const TransactionAdvancedFilters();
    }

    final startDate = DateTime(month.year, month.month);
    final endDate = DateTime(month.year, month.month + 1, 0);
    return TransactionAdvancedFilters(startDate: startDate, endDate: endDate);
  }

  /// Groups transactions by date (normalized to midnight), sorted descending.
  /// Uses a single `DateTime.now()` call to avoid midnight-crossing splits.
  List<_TransactionSection> _groupTransactions(
    List<TransactionsTableData> transactions,
  ) {
    final now = DateTime.now();
    final grouped = <DateTime, List<TransactionsTableData>>{};

    for (final transaction in transactions) {
      final dateKey = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );
      grouped.putIfAbsent(dateKey, () => []).add(transaction);
    }

    // Sort sections by date descending
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return sortedKeys
        .map(
          (dateKey) => _TransactionSection(
            dateKey: dateKey,
            header: formatTransactionHeader(dateKey, reference: now),
            transactions: grouped[dateKey]!,
          ),
        )
        .toList();
  }

  Future<void> _openFilters(List<CategoriesTableData> categories) async {
    final result = await showTransactionFilterBottomSheet(
      context,
      initialFilters: _advancedFilters,
      categories: categories,
    );

    if (result == null || !mounted) return;

    setState(() {
      _advancedFilters = result;
    });
  }

  Future<void> _deleteTransaction(TransactionsTableData transaction) async {
    final repository = ref.read(transactionRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);

    await repository.deleteTransactionById(transaction.id);

    var undoFired = false;

    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 3),
        content: const Text('Deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            if (undoFired) return;
            undoFired = true;
            // Re-insert with the original ID to preserve identity
            repository.createTransactionWithId(transaction);
          },
        ),
      ),
    );
  }

  Future<void> _refreshTransactions() async {
    ref.invalidate(transactionsProvider);
    ref.invalidate(categoriesProvider);
    await Future.wait([
      ref.refresh(transactionsProvider.future),
      ref.refresh(categoriesProvider.future),
    ]);
  }
}

class _TransactionsSkeleton extends StatelessWidget {
  const _TransactionsSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        ShimmerSkeleton(
          child: Column(
            children: [
              SkeletonCard(height: 86, radius: 20),
              SizedBox(height: 12),
              SkeletonCard(height: 86, radius: 20),
              SizedBox(height: 12),
              SkeletonCard(height: 86, radius: 20),
              SizedBox(height: 12),
              SkeletonCard(height: 86, radius: 20),
            ],
          ),
        ),
      ],
    );
  }
}

class _TransactionSection {
  const _TransactionSection({
    required this.dateKey,
    required this.header,
    required this.transactions,
  });

  final DateTime dateKey;
  final String header;
  final List<TransactionsTableData> transactions;
}

class _DateHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _DateHeaderDelegate(this.label);

  final String label;

  @override
  double get minExtent => 34;

  @override
  double get maxExtent => 34;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          alignment: Alignment.centerLeft,
          color: AppColors.background.withValues(alpha: 0.85),
          padding: const EdgeInsets.only(bottom: 8, top: 6),
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _DateHeaderDelegate oldDelegate) {
    return oldDelegate.label != label;
  }
}
