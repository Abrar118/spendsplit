import '../database/app_database.dart';

class BalanceSummary {
  const BalanceSummary({
    required this.totalBalance,
    required this.savingsBalance,
    required this.availableBalance,
  });

  final double totalBalance;
  final double savingsBalance;
  final double availableBalance;
}

class MonthlyFinanceSummary {
  const MonthlyFinanceSummary({
    required this.month,
    required this.income,
    required this.expenses,
    required this.saved,
  });

  final DateTime month;
  final double income;
  final double expenses;
  final double saved;
}

class MonthlyCategoryBreakdown {
  const MonthlyCategoryBreakdown({
    required this.name,
    required this.iconKey,
    required this.colorValue,
    required this.amount,
    required this.share,
  });

  final String name;
  final String iconKey;
  final int colorValue;
  final double amount;
  final double share;
}

class MonthlyAnalytics {
  const MonthlyAnalytics({
    required this.summary,
    required this.incomeDelta,
    required this.expenseDelta,
    required this.savingsRate,
    required this.transactionCount,
    required this.categories,
  });

  final MonthlyFinanceSummary summary;
  final double incomeDelta;
  final double expenseDelta;
  final double savingsRate;
  final int transactionCount;
  final List<MonthlyCategoryBreakdown> categories;

  String? get topCategoryName =>
      categories.isEmpty ? null : categories.first.name;
}

class DollarTrackerSummary {
  const DollarTrackerSummary({
    required this.year,
    required this.annualLimit,
    required this.spentYtd,
    required this.remaining,
  });

  final int year;
  final double annualLimit;
  final double spentYtd;
  final double remaining;
}

class SavingsInsights {
  const SavingsInsights({
    required this.averageMonthlySavings,
    required this.monthOverMonthDelta,
  });

  final double averageMonthlySavings;
  final double monthOverMonthDelta;
}

abstract final class FinanceCalculators {
  static BalanceSummary balanceSummary({
    required Iterable<TransactionsTableData> transactions,
    required double initialBalance,
  }) {
    final income = _sumByType(transactions, const {'income'});
    final expenses = _sumByType(transactions, const {'expense'});
    final savingsDeposits = _sumByType(transactions, const {'savings_deposit'});
    final savingsWithdrawals = _sumByType(transactions, const {
      'savings_withdrawal',
    });

    final totalBalance = initialBalance + income - expenses;
    final savingsBalance = savingsDeposits - savingsWithdrawals;

    return BalanceSummary(
      totalBalance: totalBalance,
      savingsBalance: savingsBalance,
      availableBalance: totalBalance - savingsBalance,
    );
  }

  static MonthlyFinanceSummary monthlySummary({
    required Iterable<TransactionsTableData> transactions,
    required DateTime month,
  }) {
    final scoped = transactions.where(
      (entry) => _isSameMonth(entry.date, month),
    );

    return MonthlyFinanceSummary(
      month: DateTime(month.year, month.month),
      income: _sumByType(scoped, const {'income'}),
      expenses: _sumByType(scoped, const {'expense'}),
      saved:
          _sumByType(scoped, const {'savings_deposit'}) -
          _sumByType(scoped, const {'savings_withdrawal'}),
    );
  }

  static DollarTrackerSummary dollarSummary({
    required Iterable<DollarExpensesTableData> expenses,
    required double annualLimit,
    required int year,
  }) {
    final spentYtd = expenses
        .where((expense) => expense.date.year == year)
        .fold<double>(0, (sum, expense) => sum + expense.amount);

    return DollarTrackerSummary(
      year: year,
      annualLimit: annualLimit,
      spentYtd: spentYtd,
      remaining: annualLimit - spentYtd,
    );
  }

  static SavingsInsights savingsInsights({
    required Iterable<TransactionsTableData> transactions,
    required DateTime referenceMonth,
  }) {
    final bucketedSavings = <String, double>{};

    for (final entry in transactions) {
      final monthKey =
          '${entry.date.year.toString().padLeft(4, '0')}-${entry.date.month.toString().padLeft(2, '0')}';
      final delta = switch (entry.type) {
        'savings_deposit' => entry.amount,
        'savings_withdrawal' => -entry.amount,
        _ => 0.0,
      };
      if (delta == 0) continue;
      bucketedSavings.update(
        monthKey,
        (value) => value + delta,
        ifAbsent: () => delta,
      );
    }

    if (bucketedSavings.isEmpty) {
      return const SavingsInsights(
        averageMonthlySavings: 0,
        monthOverMonthDelta: 0,
      );
    }

    final average =
        bucketedSavings.values.fold<double>(0, (sum, value) => sum + value) /
        bucketedSavings.length;

    final current = monthlySummary(
      transactions: transactions,
      month: referenceMonth,
    ).saved;
    final previousMonth = DateTime(
      referenceMonth.year,
      referenceMonth.month - 1,
    );
    final previous = monthlySummary(
      transactions: transactions,
      month: previousMonth,
    ).saved;

    final delta = previous == 0
        ? (current == 0 ? 0.0 : 1.0)
        : (current - previous) / previous;

    return SavingsInsights(
      averageMonthlySavings: average,
      monthOverMonthDelta: delta,
    );
  }

  static MonthlyAnalytics monthlyAnalytics({
    required Iterable<TransactionsTableData> transactions,
    required Iterable<CategoriesTableData> categories,
    required DateTime month,
  }) {
    final normalizedMonth = DateTime(month.year, month.month);
    final currentSummary = monthlySummary(
      transactions: transactions,
      month: normalizedMonth,
    );
    final previousSummary = monthlySummary(
      transactions: transactions,
      month: DateTime(normalizedMonth.year, normalizedMonth.month - 1),
    );
    final scopedTransactions = transactions
        .where((entry) => _isSameMonth(entry.date, normalizedMonth))
        .toList();
    final expenseTransactions = scopedTransactions
        .where((entry) => entry.type == 'expense')
        .toList();
    final categoriesById = {
      for (final category in categories) category.id: category,
    };
    final amountByCategory = <int?, double>{};

    for (final entry in expenseTransactions) {
      amountByCategory.update(
        entry.categoryId,
        (value) => value + entry.amount,
        ifAbsent: () => entry.amount,
      );
    }

    final breakdown = amountByCategory.entries.map((entry) {
      final category = categoriesById[entry.key];
      final amount = entry.value;
      return MonthlyCategoryBreakdown(
        name: category?.name ?? 'Uncategorized',
        iconKey: category?.icon ?? 'more_horiz',
        colorValue: category?.color ?? 0xFF8892A7,
        amount: amount,
        share: currentSummary.expenses <= 0
            ? 0
            : amount / currentSummary.expenses,
      );
    }).toList()..sort((a, b) => b.amount.compareTo(a.amount));

    return MonthlyAnalytics(
      summary: currentSummary,
      incomeDelta: _monthDelta(
        current: currentSummary.income,
        previous: previousSummary.income,
      ),
      expenseDelta: _monthDelta(
        current: currentSummary.expenses,
        previous: previousSummary.expenses,
      ),
      savingsRate: currentSummary.income <= 0
          ? 0
          : currentSummary.saved / currentSummary.income,
      transactionCount: expenseTransactions.length,
      categories: breakdown,
    );
  }

  static double _sumByType(
    Iterable<TransactionsTableData> transactions,
    Set<String> types,
  ) {
    return transactions
        .where((entry) => types.contains(entry.type))
        .fold<double>(0, (sum, entry) => sum + entry.amount);
  }

  static bool _isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }

  static double _monthDelta({
    required double current,
    required double previous,
  }) {
    if (previous == 0) {
      return current == 0 ? 0 : 1;
    }

    return (current - previous) / previous;
  }
}
