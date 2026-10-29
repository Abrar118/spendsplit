import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spendsplit/core/icons/lucide_icons.dart';

import '../../../core/widgets/large_title_page.dart';
import '../../../core/constants/enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/shimmer_skeleton.dart';
import '../../../data/database/app_database.dart';
import '../../../providers/providers.dart';
import '../../sms_import/providers/sms_providers.dart';
import '../widgets/add_transaction_sheet.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../widgets/filter_chips_row.dart';
import '../widgets/transaction_tile.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({
    super.key,
    this.initialMonth,
    this.initialCategoryId,
    this.initialReviewOnly = false,
  });

  final DateTime? initialMonth;
  final int? initialCategoryId;
  final bool initialReviewOnly;

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
    if (widget.initialReviewOnly) _quickFilter = TransactionQuickFilter.review;
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
    if (widget.initialReviewOnly && !oldWidget.initialReviewOnly) {
      _quickFilter = TransactionQuickFilter.review;
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

    return LargeTitlePage(
      title: 'History',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          BarIconButton(
            icon: _showSearch ? LucideIcons.x : LucideIcons.search,
            tooltip: _showSearch ? 'Close search' : 'Search',
            color: _showSearch ? AppColors.textPrimary : null,
            onPressed: () => setState(() {
              _showSearch = !_showSearch;
              if (!_showSearch) _searchController.clear();
            }),
          ),
          BarIconButton(
            icon: LucideIcons.listFilter,
            tooltip: 'Filters',
            color: _advancedFilters.hasActiveFilters
                ? AppColors.textPrimary
                : null,
            onPressed: categoriesAsync.hasValue
                ? () => _openFilters(categoriesAsync.value!)
                : null,
          ),
        ],
      ),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilterChipsRow(
                  selectedFilter: _quickFilter,
                  showReview:
                      ref.watch(needsReviewCountProvider) > 0 ||
                      _quickFilter == TransactionQuickFilter.review,
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
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search amount, note, category…',
                      prefixIcon: const Icon(LucideIcons.search, size: 18),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              tooltip: 'Clear search',
                              icon: const Icon(LucideIcons.x, size: 16),
                              onPressed: _searchController.clear,
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        ...transactionsAsync.when(
          loading: () => [
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
              sliver: SliverToBoxAdapter(child: _TransactionsSkeleton()),
            ),
          ],
          error: (error, _) => [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  "History couldn't load. Close and reopen the app to try again.",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ),
          ],
          data: (transactions) {
            final categoriesById = {
              for (final category
                  in categoriesAsync.valueOrNull ??
                      const <CategoriesTableData>[])
                category.id: category,
            };
            final filtered = _applyFilters(transactions, categoriesById);

            if (filtered.isEmpty) {
              // Only "no transactions yet" when there really are none;
              // otherwise say a filter is hiding them.
              final reviewOnly = _quickFilter == TransactionQuickFilter.review;
              return [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 48, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      children: [
                        if (transactions.isEmpty)
                          const EmptyState(
                            icon: LucideIcons.wallet,
                            title: 'No transactions yet',
                            message: 'Tap + to add your first one.',
                          )
                        else ...[
                          EmptyState(
                            icon: reviewOnly
                                ? LucideIcons.checkCircle
                                : LucideIcons.search,
                            title: reviewOnly
                                ? 'Nothing to review'
                                : 'No matches',
                            message: reviewOnly
                                ? 'Every imported transaction has been checked.'
                                : 'Nothing fits the current search or filters.',
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          TextButton(
                            onPressed: _clearFilters,
                            child: const Text('Clear filters'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ];
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

            return [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  0,
                  16,
                  AppSpacing.navClearance,
                ),
                sliver: SliverList.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];

                    if (item.isHeader) {
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: 8,
                          top: index == 0 ? 12 : 20,
                        ),
                        child: Semantics(
                          header: true,
                          child: Text(
                            item.headerText!,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      );
                    }

                    if (item.isLoadMore) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: TextButton(
                            onPressed: () =>
                                setState(() => _visibleCount += 40),
                            child: Text(
                              'Load more (${filtered.length - _visibleCount} remaining)',
                            ),
                          ),
                        ),
                      );
                    }

                    final transaction = item.transaction!;
                    return Padding(
                      key: ValueKey(transaction.id),
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TransactionTile(
                        transaction: transaction,
                        category: categoriesById[transaction.categoryId],
                        onTap: () => showAddTransactionSheet(
                          context,
                          existingTransaction: transaction,
                        ),
                        onLongPress: () => _copyAmount(transaction),
                        onSaveAsTemplate: () =>
                            _saveTransactionAsTemplate(transaction),
                        onDelete: () => _deleteTransaction(transaction),
                      ),
                    );
                  },
                ),
              ),
            ];
          },
        ),
      ],
    );
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _quickFilter = TransactionQuickFilter.all;
      _advancedFilters = const TransactionAdvancedFilters();
      _showSearch = false;
    });
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
        TransactionQuickFilter.review => transaction.needsReview,
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
    // The hint shows the note, so an empty field means "use the note".
    final typed = nameController.text.trim();
    final name = typed.isEmpty ? (transaction.note?.trim() ?? '') : typed;
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Give the template a name')));
      return;
    }

    await ref
        .read(transactionTemplateRepositoryProvider)
        .createTemplate(
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Template saved')));
  }

  TransactionAdvancedFilters _filtersForMonth(
    DateTime? month, {
    int? categoryId,
  }) {
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

    // Captured now: the Undo snackbar outlives this screen when the user
    // switches tabs, and `ref` is unusable after dispose.
    final db = ref.read(appDatabaseProvider);
    try {
      await db.transaction(() async {
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
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      return;
    }

    HapticFeedback.mediumImpact();
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
            try {
              await db.transaction(() async {
                await repository.createTransactionWithId(transaction);
                // Only re-apply goal delta if the goal still exists. Completed
                // goals too: the delete took the amount off them as well.
                if (linkedGoalId != null && goalDelta.abs() > 1e-9) {
                  final goal = await savingsRepository.getGoalById(
                    linkedGoalId,
                  );
                  if (goal != null) {
                    final updated = await savingsRepository.adjustGoalAmountBy(
                      linkedGoalId,
                      goalDelta,
                    );
                    if (!updated) {
                      throw StateError(
                        'Failed to restore linked savings goal.',
                      );
                    }
                  }
                }
              });
            } catch (e) {
              messenger.showSnackBar(
                SnackBar(content: Text('Undo failed: $e')),
              );
            }
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
}

class _TransactionsSkeleton extends StatelessWidget {
  const _TransactionsSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        ShimmerSkeleton(
          child: Column(
            children: [
              SkeletonCard(height: 64, radius: 6),
              SizedBox(height: 12),
              SkeletonCard(height: 64, radius: 6),
              SizedBox(height: 12),
              SkeletonCard(height: 64, radius: 6),
              SizedBox(height: 12),
              SkeletonCard(height: 64, radius: 6),
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
