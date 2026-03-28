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
}
