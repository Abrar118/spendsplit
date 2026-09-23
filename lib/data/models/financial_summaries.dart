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
    required this.categoryId,
    required this.name,
    required this.iconKey,
    required this.colorValue,
    required this.amount,
    required this.share,
    this.monthlyLimit,
  });

  final int? categoryId;
  final String name;
  final String iconKey;
  final int colorValue;
  final double amount;
  final double share;

  /// Optional per-category monthly spending cap. Null when the category has no
  /// budget set (or is the uncategorized bucket).
  final double? monthlyLimit;
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
    required this.pacePerDay,
    required this.projectedYearEnd,
    required this.projectedVsLimit,
  });

  final int year;
  final double annualLimit;
  final double spentYtd;
  final double remaining;

  /// Average USD spent per elapsed day of [year].
  final double pacePerDay;

  /// [pacePerDay] extrapolated across the whole year.
  final double projectedYearEnd;

  /// [projectedYearEnd] minus [annualLimit] — positive means projected over.
  final double projectedVsLimit;
}

class SavingsInsights {
  const SavingsInsights({
    required this.averageMonthlySavings,
    required this.monthOverMonthDelta,
  });

  final double averageMonthlySavings;
  final double monthOverMonthDelta;
}

class SpendingRunway {
  const SpendingRunway({
    required this.dailyPace,
    required this.daysRemaining,
    required this.windowDays,
  });

  /// Trend-adjusted daily expense rate used for the runway estimate.
  final double dailyPace;

  /// Whole days of Available left at [dailyPace]. Null when there is no
  /// recent spending to project from.
  final int? daysRemaining;
  final int windowDays;
}

class BalancePoint {
  const BalancePoint({
    required this.month,
    required this.total,
    required this.savings,
    required this.available,
  });

  final DateTime month;
  final double total;
  final double savings;
  final double available;
}

class GoalProjection {
  const GoalProjection({
    required this.weeklyRate,
    required this.estimatedCompletion,
    required this.requiredWeeklyForDeadline,
  });

  /// Net linked contributions per week since the first contribution.
  final double weeklyRate;

  /// When the goal is projected to be fully funded at [weeklyRate].
  /// Null when there is no positive contribution rate to project from.
  final DateTime? estimatedCompletion;

  /// Weekly amount needed to hit the goal by its deadline. Null when the
  /// goal has no deadline.
  final double? requiredWeeklyForDeadline;
}

class MonthRecap {
  const MonthRecap({
    required this.month,
    required this.income,
    required this.expenses,
    required this.netSaved,
    required this.savingsRate,
    required this.topCategories,
    required this.budgetDelta,
    required this.expenseVsPrevMonth,
  });

  final DateTime month;
  final double income;
  final double expenses;
  final double netSaved;
  final double savingsRate;
  final List<MonthlyCategoryBreakdown> topCategories;

  /// `monthlyExpenseBudget - expenses` when a budget is set (positive = under).
  /// Null when there is no global monthly budget.
  final double? budgetDelta;

  /// Proportional change in expenses vs. the previous month.
  final double expenseVsPrevMonth;
}

abstract final class FinanceCalculators {
  static const double _epsilon = 1e-9;

  static BalanceSummary balanceSummary({
    required Iterable<TransactionsTableData> transactions,
    required double initialBalance,
    DateTime? asOf,
  }) {
    final cutoff = asOf ?? DateTime.now();
    final posted = transactions.where((entry) => !entry.date.isAfter(cutoff));
    final income = _sumByType(posted, const {'income'});
    final expenses = _sumByType(posted, const {'expense'});
    final savingsDeposits = _sumByType(posted, const {'savings_deposit'});
    final savingsWithdrawals = _sumByType(posted, const {'savings_withdrawal'});

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
    DateTime? asOf,
  }) {
    final spentYtd = expenses
        .where((expense) => expense.date.year == year)
        .fold<double>(0, (sum, expense) => sum + expense.amount);

    final now = asOf ?? DateTime.now();
    final refInYear = now.year == year
        ? now
        : (now.year > year ? DateTime(year, 12, 31) : DateTime(year));
    final dayOfYear = refInYear.difference(DateTime(year)).inDays + 1;
    final daysInYear = DateTime(year + 1).difference(DateTime(year)).inDays;
    final pacePerDay = dayOfYear <= 0 ? 0.0 : spentYtd / dayOfYear;
    final projectedYearEnd = pacePerDay * daysInYear;

    return DollarTrackerSummary(
      year: year,
      annualLimit: annualLimit,
      spentYtd: spentYtd,
      remaining: annualLimit - spentYtd,
      pacePerDay: pacePerDay,
      projectedYearEnd: projectedYearEnd,
      projectedVsLimit: projectedYearEnd - annualLimit,
    );
  }

  /// How many days Available lasts at a trend-adjusted expense rate.
  ///
  /// The estimate blends 65% of the latest seven-day pace with 35% of the
  /// trailing [windowDays] baseline. For histories shorter than [windowDays],
  /// both rates use the number of calendar days actually observed. Only
  /// `expense` transactions count as burn; future entries are ignored.
  static SpendingRunway spendingRunway({
    required Iterable<TransactionsTableData> transactions,
    required double availableBalance,
    DateTime? asOf,
    int windowDays = 30,
  }) {
    if (windowDays <= 0) {
      throw ArgumentError.value(windowDays, 'windowDays', 'Must be positive');
    }

    final now = asOf ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final windowStart = today.subtract(Duration(days: windowDays - 1));
    final observed = transactions.where((transaction) {
      final date = transaction.date;
      return !date.isBefore(windowStart) && !date.isAfter(now);
    }).toList();

    if (observed.isEmpty) {
      return SpendingRunway(
        dailyPace: 0,
        daysRemaining: null,
        windowDays: windowDays,
      );
    }

    final firstObservedDay = observed
        .map((transaction) {
          final date = transaction.date;
          return DateTime(date.year, date.month, date.day);
        })
        .reduce((first, date) => date.isBefore(first) ? date : first);
    final observedDays = today.difference(firstObservedDay).inDays + 1;
    final baselineExpense = observed
        .where((transaction) => transaction.type == 'expense')
        .fold<double>(0, (sum, transaction) => sum + transaction.amount);
    final baselineRate = baselineExpense / observedDays;

    final recentDays = observedDays < 7 ? observedDays : 7;
    final recentStart = today.subtract(Duration(days: recentDays - 1));
    final recentExpense = observed
        .where(
          (transaction) =>
              transaction.type == 'expense' &&
              !transaction.date.isBefore(recentStart),
        )
        .fold<double>(0, (sum, transaction) => sum + transaction.amount);
    final recentRate = recentExpense / recentDays;
    final dailyPace = observedDays <= 7
        ? baselineRate
        : (recentRate * 0.65) + (baselineRate * 0.35);

    if (dailyPace <= _epsilon) {
      return SpendingRunway(
        dailyPace: 0,
        daysRemaining: null,
        windowDays: windowDays,
      );
    }
    final days = availableBalance <= 0
        ? 0
        : (availableBalance / dailyPace).floor();
    return SpendingRunway(
      dailyPace: dailyPace,
      daysRemaining: days,
      windowDays: windowDays,
    );
  }

  /// End-of-month Available / Savings / Total for the trailing [months]
  /// window. Transactions before the window fold into the first point;
  /// months with no activity carry the previous value forward.
  static List<BalancePoint> balanceTrend({
    required Iterable<TransactionsTableData> transactions,
    required double initialBalance,
    int months = 6,
    DateTime? asOf,
  }) {
    final now = asOf ?? DateTime.now();
    final firstMonth = DateTime(now.year, now.month - (months - 1));
    final sorted = transactions.toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    var total = initialBalance;
    var savings = 0.0;
    var index = 0;
    final points = <BalancePoint>[];

    for (var i = 0; i < months; i++) {
      final monthStart = DateTime(firstMonth.year, firstMonth.month + i);
      final nextMonth = DateTime(firstMonth.year, firstMonth.month + i + 1);
      while (index < sorted.length && sorted[index].date.isBefore(nextMonth)) {
        final entry = sorted[index];
        switch (entry.type) {
          case 'income':
            total += entry.amount;
          case 'expense':
            total -= entry.amount;
          case 'savings_deposit':
            savings += entry.amount;
          case 'savings_withdrawal':
            savings -= entry.amount;
        }
        index++;
      }
      points.add(
        BalancePoint(
          month: monthStart,
          total: total,
          savings: savings,
          available: total - savings,
        ),
      );
    }
    return points;
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
      if (_isNearZero(delta)) continue;
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

    final delta = _isNearZero(previous)
        ? (_isNearZero(current) ? 0.0 : 1.0)
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
    Map<int, double> categoryBudgets = const {},
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
        categoryId: entry.key,
        name: category?.name ?? 'Uncategorized',
        iconKey: category?.icon ?? 'more_horiz',
        colorValue: category?.color ?? 0xFF8892A7,
        amount: amount,
        share: currentSummary.expenses <= 0
            ? 0
            : amount / currentSummary.expenses,
        monthlyLimit: entry.key == null ? null : categoryBudgets[entry.key],
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
      transactionCount: scopedTransactions.length,
      categories: breakdown,
    );
  }

  /// Projects when a goal will be funded from the cadence of its linked
  /// contributions. [linkedTransactions] must already be filtered to the
  /// goal (`savingsGoalId == goal.id`).
  static GoalProjection goalProjection({
    required SavingsGoalsTableData goal,
    required Iterable<TransactionsTableData> linkedTransactions,
    DateTime? asOf,
  }) {
    final now = asOf ?? DateTime.now();
    final linked = linkedTransactions.toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    var net = 0.0;
    for (final t in linked) {
      net += switch (t.type) {
        'savings_deposit' => t.amount,
        'savings_withdrawal' => -t.amount,
        _ => 0.0,
      };
    }

    final remaining = (goal.targetAmount - goal.currentAmount) <= 0
        ? 0.0
        : goal.targetAmount - goal.currentAmount;

    double weeklyRate = 0;
    if (linked.isNotEmpty && net > _epsilon) {
      final elapsedDays = now.difference(linked.first.date).inDays;
      final weeks = elapsedDays < 7 ? 1.0 : elapsedDays / 7.0;
      weeklyRate = net / weeks;
    }

    DateTime? estimatedCompletion;
    if (weeklyRate > _epsilon && remaining > _epsilon) {
      final weeksLeft = remaining / weeklyRate;
      estimatedCompletion = now.add(Duration(days: (weeksLeft * 7).ceil()));
    }

    double? requiredWeeklyForDeadline;
    if (goal.deadline != null) {
      final daysUntil = goal.deadline!.difference(now).inDays;
      final weeksUntil = daysUntil < 7 ? 1.0 : daysUntil / 7.0;
      requiredWeeklyForDeadline = remaining / weeksUntil;
    }

    return GoalProjection(
      weeklyRate: weeklyRate,
      estimatedCompletion: estimatedCompletion,
      requiredWeeklyForDeadline: requiredWeeklyForDeadline,
    );
  }

  /// A summary of the given [month] for the month-end recap card.
  static MonthRecap monthRecap({
    required DateTime month,
    required Iterable<TransactionsTableData> transactions,
    required Iterable<CategoriesTableData> categories,
    Map<int, double> categoryBudgets = const {},
    double monthlyExpenseBudget = 0,
  }) {
    final analytics = monthlyAnalytics(
      transactions: transactions,
      categories: categories,
      month: month,
      categoryBudgets: categoryBudgets,
    );
    final expenses = analytics.summary.expenses;

    return MonthRecap(
      month: DateTime(month.year, month.month),
      income: analytics.summary.income,
      expenses: expenses,
      netSaved: analytics.summary.saved,
      savingsRate: analytics.savingsRate,
      topCategories: analytics.categories.take(3).toList(),
      budgetDelta: monthlyExpenseBudget > 0
          ? monthlyExpenseBudget - expenses
          : null,
      expenseVsPrevMonth: analytics.expenseDelta,
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
    if (_isNearZero(previous)) {
      return _isNearZero(current) ? 0 : 1;
    }

    return (current - previous) / previous;
  }

  static bool _isNearZero(double value) => value.abs() < _epsilon;
}
