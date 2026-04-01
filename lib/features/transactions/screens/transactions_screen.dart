import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  const TransactionsScreen({super.key, this.initialMonth, this.initialCategoryId});

  final DateTime? initialMonth;
  final int? initialCategoryId;

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  TransactionQuickFilter _quickFilter = TransactionQuickFilter.all;
  TransactionAdvancedFilters _advancedFilters =
      const TransactionAdvancedFilters();
  int _visibleCount = 40;
  bool _showSearch = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _advancedFilters = _filtersForMonth(
      widget.initialMonth,
      categoryId: widget.initialCategoryId,
    );
    _searchController.addListener(() {
      setState(() {
        _visibleCount = 40;
      });
    });
  }

  @override
  void didUpdateWidget(covariant TransactionsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldMonth = oldWidget.initialMonth;
    final newMonth = widget.initialMonth;
    final hasChanged =
        oldMonth?.year != newMonth?.year ||
        oldMonth?.month != newMonth?.month ||
        oldWidget.initialCategoryId != widget.initialCategoryId;

    if (hasChanged) {
      _advancedFilters = _filtersForMonth(
        newMonth,
        categoryId: widget.initialCategoryId,
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
            Row(
              children: [
                Text('Transactions', style: theme.textTheme.titleLarge),
                const Spacer(),
                IconButton(
                  onPressed: () => setState(() {
                    _showSearch = !_showSearch;
                    if (!_showSearch) _searchController.clear();
                  }),
                  icon: Icon(
                    _showSearch ? LucideIcons.x : LucideIcons.search,
                    color: _showSearch ? AppColors.teal : null,
                  ),
                ),
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
                  _visibleCount = 40;
                });
              },
            ),
            if (_showSearch) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search amount, note, category...',
                  prefixIcon: const Icon(LucideIcons.search, size: 18),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(LucideIcons.x, size: 16),
                          onPressed: _searchController.clear,
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surfaceLight.withValues(alpha: 0.6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ],
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
                    final filtered = _applyFilters(transactions, categoriesById);

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

                    // Paginate: show only _visibleCount items
                    final paginated = filtered.length > _visibleCount
                        ? filtered.sublist(0, _visibleCount)
                        : filtered;
                    final hasMore = filtered.length > _visibleCount;
                    final sections = _groupTransactions(paginated);

                    // Flatten sections into a list of items
                    final items = <_ListItem>[];
                    for (final section in sections) {
                      items.add(_ListItem.header(section.header));
                      for (final t in section.transactions) {
                        items.add(_ListItem.transaction(t));
                      }
                    }
                    if (hasMore) {
                      items.add(const _ListItem.loadMore());
                    }

                    return ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];

                        if (item.isHeader) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8, top: 6),
                            child: Text(
                              item.headerText!,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          );
                        }

                        if (item.isLoadMore) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: TextButton(
                                onPressed: () => setState(
                                  () => _visibleCount += 40,
                                ),
                                child: Text(
                                  'Load more (${filtered.length - _visibleCount} remaining)',
                                  style: TextStyle(color: AppColors.teal),
                                ),
                              ),
                            ),
                          );
                        }

                        final transaction = item.transaction!;
                        return Padding(
                          key: ValueKey(transaction.id),
                          padding: const EdgeInsets.only(bottom: 12),
                          child: TransactionTile(
                            transaction: transaction,
                            category:
                                categoriesById[transaction.categoryId],
                            onTap: () => showAddTransactionSheet(
                              context,
                              existingTransaction: transaction,
                            ),
                            onLongPress: () => _copyAmount(transaction),
                            onSaveAsTemplate: () =>
                                _saveTransactionAsTemplate(transaction),
                            onDelete: () =>
                                _deleteTransaction(transaction),
                          ),
                        );
                      },
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
    Map<int, CategoriesTableData> categoriesById,
  ) {
    final query = _searchController.text.trim().toLowerCase();

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

      // Fuzzy search
      if (query.isNotEmpty) {
        final amountStr = transaction.amount.toStringAsFixed(2);
        final note = transaction.note?.toLowerCase() ?? '';
        final catName =
            categoriesById[transaction.categoryId]?.name.toLowerCase() ?? '';
        if (!amountStr.contains(query) &&
            !note.contains(query) &&
            !catName.contains(query)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  Future<void> _copyAmount(TransactionsTableData transaction) async {
    final amountStr = transaction.amount.toStringAsFixed(2);
    await Clipboard.setData(ClipboardData(text: amountStr));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied ৳$amountStr'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _saveTransactionAsTemplate(
    TransactionsTableData transaction,
  ) async {
    final nameController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        title: const Text('Save as Template'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: transaction.note?.isNotEmpty == true
                ? transaction.note
                : 'Template name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final name = nameController.text.trim();
    if (name.isEmpty) return;

    await ref.read(transactionTemplateRepositoryProvider).createTemplate(
      TransactionTemplatesTableCompanion.insert(
        name: name,
        type: transaction.type,
        amount: Value(transaction.amount),
        categoryId: Value(transaction.categoryId),
        source: Value(transaction.source),
        note: Value(transaction.note),
      ),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Template saved')),
    );
  }

  TransactionAdvancedFilters _filtersForMonth(DateTime? month, {int? categoryId}) {
    if (month == null && categoryId == null) {
      return const TransactionAdvancedFilters();
    }

    DateTime? startDate;
    DateTime? endDate;
    if (month != null) {
      startDate = DateTime(month.year, month.month);
      endDate = DateTime(month.year, month.month + 1, 0);
    }

    return TransactionAdvancedFilters(
      startDate: startDate,
      endDate: endDate,
      categoryIds: categoryId != null ? {categoryId} : const {},
    );
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
    final savingsRepository = ref.read(savingsRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final goalDelta = _goalLinkedDelta(transaction);
    final linkedGoalId = transaction.savingsGoalId;

    if (linkedGoalId != null && goalDelta.abs() > 1e-9) {
      final goal = await savingsRepository.getGoalById(linkedGoalId);
      if (goal != null) {
        final projected = goal.currentAmount - goalDelta;
        if (projected < -1e-9) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                'Cannot delete this transaction because it would make "${goal.name}" go below zero.',
              ),
            ),
          );
          return;
        }
      }
    }

    await ref.read(appDatabaseProvider).transaction(() async {
      await repository.deleteTransactionById(transaction.id);
      if (linkedGoalId != null && goalDelta.abs() > 1e-9) {
        final updated = await savingsRepository.adjustGoalAmountBy(
          linkedGoalId,
          -goalDelta,
        );
        if (!updated) {
          throw StateError('Failed to update linked savings goal.');
        }
      }
    });

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
            await ref.read(appDatabaseProvider).transaction(() async {
              await repository.createTransactionWithId(transaction);
              // Only re-apply goal delta if the goal still exists
              if (linkedGoalId != null && goalDelta.abs() > 1e-9) {
                final goal = await savingsRepository.getGoalById(linkedGoalId);
                if (goal != null && !goal.isCompleted) {
                  final updated = await savingsRepository.adjustGoalAmountBy(
                    linkedGoalId,
                    goalDelta,
                  );
                  if (!updated) {
                    throw StateError('Failed to restore linked savings goal.');
                  }
                }
              }
            });
          },
        ),
      ),
    );
  }

  double _goalLinkedDelta(TransactionsTableData transaction) {
    if (transaction.savingsGoalId == null) return 0;

    return switch (TransactionType.fromDbValue(transaction.type)) {
      TransactionType.savingsDeposit => transaction.amount,
      TransactionType.savingsWithdrawal => -transaction.amount,
      _ => 0,
    };
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

class _ListItem {
  const _ListItem.header(this.headerText)
      : transaction = null,
        isHeader = true,
        isLoadMore = false;
  const _ListItem.transaction(this.transaction)
      : headerText = null,
        isHeader = false,
        isLoadMore = false;
  const _ListItem.loadMore()
      : headerText = null,
        transaction = null,
        isHeader = false,
        isLoadMore = true;

  final String? headerText;
  final TransactionsTableData? transaction;
  final bool isHeader;
  final bool isLoadMore;
}

