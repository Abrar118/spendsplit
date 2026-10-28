import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:spendsplit/core/utils/currency_formatter.dart';
import 'package:spendsplit/core/utils/date_utils.dart';
import 'package:spendsplit/data/database/app_database.dart';
import 'package:spendsplit/data/models/financial_summaries.dart';

TransactionsTableData _mkTx(String type, double amount, DateTime date) =>
    TransactionsTableData(
      id: date.microsecondsSinceEpoch % 100000000,
      type: type,
      amount: amount,
      date: date,
      createdAt: date,
      needsReview: false,
    );

TransactionsTableData _expense({
  required double amount,
  required DateTime date,
}) => _mkTx('expense', amount, date);
TransactionsTableData _income({
  required double amount,
  required DateTime date,
}) => _mkTx('income', amount, date);
TransactionsTableData _savingsDeposit({
  required double amount,
  required DateTime date,
}) => _mkTx('savings_deposit', amount, date);

DollarExpensesTableData _dollar({
  required double amount,
  required DateTime date,
}) => DollarExpensesTableData(
  id: date.microsecondsSinceEpoch % 100000000,
  amount: amount,
  purpose: 'test',
  categoryId: 0,
  date: date,
  createdAt: date,
);

TransactionsTableData _linkedDeposit({
  required double amount,
  required DateTime date,
  required int goalId,
}) => TransactionsTableData(
  id: date.microsecondsSinceEpoch % 100000000,
  type: 'savings_deposit',
  amount: amount,
  date: date,
  createdAt: date,
  savingsGoalId: goalId,
  needsReview: false,
);

SavingsGoalsTableData _goal({
  required double target,
  required double current,
  DateTime? deadline,
}) => SavingsGoalsTableData(
  id: 7,
  name: 'Mac Mini',
  currentAmount: current,
  targetAmount: target,
  icon: 'flag',
  deadline: deadline,
  isCompleted: false,
  createdAt: DateTime(2026, 1, 1),
);

void main() {
  test('income-only months contain activity', () {
    final month = DateTime(2026, 9);
    final result = FinanceCalculators.monthlyAnalytics(
      transactions: [
        TransactionsTableData(
          id: 1,
          type: 'income',
          amount: 500,
          date: month,
          createdAt: month,
          needsReview: false,
        ),
      ],
      categories: [],
      month: month,
    );
    expect(result.transactionCount, 1);
    expect(result.summary.income, 500);
    expect(result.categories, isEmpty);
  });

  group('spendingRunway', () {
    final asOf = DateTime(2026, 9, 30);

    test('no expenses in window -> daysRemaining is null', () {
      final runway = FinanceCalculators.spendingRunway(
        transactions: [
          _expense(amount: 500, date: DateTime(2026, 1, 1)),
          _income(amount: 9000, date: DateTime(2026, 9, 10)),
        ],
        availableBalance: 20000,
        asOf: asOf,
      );
      expect(runway.dailyPace, 0);
      expect(runway.daysRemaining, isNull);
    });

    test('computes steady pace from expenses only', () {
      final runway = FinanceCalculators.spendingRunway(
        transactions: [
          for (var day = 1; day <= 30; day++)
            _expense(amount: 200, date: DateTime(2026, 9, day)),
          _income(amount: 50000, date: DateTime(2026, 9, 15)),
          _savingsDeposit(amount: 10000, date: DateTime(2026, 9, 15)),
        ],
        availableBalance: 30000,
        asOf: asOf,
        windowDays: 30,
      );
      expect(runway.dailyPace, closeTo(200, 1e-6));
      expect(runway.daysRemaining, 150);
    });

    test('negative available balance -> daysRemaining 0', () {
      final runway = FinanceCalculators.spendingRunway(
        transactions: [_expense(amount: 3000, date: DateTime(2026, 9, 10))],
        availableBalance: -100,
        asOf: asOf,
      );
      expect(runway.daysRemaining, 0);
    });

    test('short history uses observed days instead of assuming 30 days', () {
      final transactions = [
        for (var day = 26; day <= 30; day++)
          _expense(amount: 500, date: DateTime(2026, 9, day)),
      ];

      final runway = FinanceCalculators.spendingRunway(
        transactions: transactions,
        availableBalance: 30000,
        asOf: asOf,
      );

      expect(runway.dailyPace, closeTo(500, 1e-6));
      expect(runway.daysRemaining, 60);
    });

    test('accelerating spending gives the latest seven days more weight', () {
      final transactions = [
        for (var day = 1; day <= 23; day++)
          _expense(amount: 50, date: DateTime(2026, 9, day)),
        for (var day = 24; day <= 30; day++)
          _expense(amount: 500, date: DateTime(2026, 9, day)),
      ];

      final runway = FinanceCalculators.spendingRunway(
        transactions: transactions,
        availableBalance: 30000,
        asOf: asOf,
      );

      // 65% of the recent 500/day pace + 35% of the 155/day baseline.
      expect(runway.dailyPace, closeTo(379.25, 1e-6));
      expect(runway.daysRemaining, 79);
    });

    test('slowing spending retains some longer-term baseline', () {
      final transactions = [
        for (var day = 1; day <= 23; day++)
          _expense(amount: 500, date: DateTime(2026, 9, day)),
        for (var day = 24; day <= 30; day++)
          _expense(amount: 50, date: DateTime(2026, 9, day)),
      ];

      final runway = FinanceCalculators.spendingRunway(
        transactions: transactions,
        availableBalance: 30000,
        asOf: asOf,
      );

      // 65% of the recent 50/day pace + 35% of the 395/day baseline.
      expect(runway.dailyPace, closeTo(170.75, 1e-6));
      expect(runway.daysRemaining, 175);
    });

    test('rejects a non-positive averaging window', () {
      expect(
        () => FinanceCalculators.spendingRunway(
          transactions: const [],
          availableBalance: 30000,
          asOf: asOf,
          windowDays: 0,
        ),
        throwsArgumentError,
      );
    });
  });

  test('balance summary excludes future-dated transactions', () {
    final summary = FinanceCalculators.balanceSummary(
      transactions: [
        _expense(amount: 100, date: DateTime(2026, 9, 29)),
        _income(amount: 5000, date: DateTime(2026, 10, 1)),
        _expense(amount: 200, date: DateTime(2026, 10, 2)),
      ],
      initialBalance: 1000,
      asOf: DateTime(2026, 9, 30, 23, 59),
    );

    expect(summary.totalBalance, 900);
    expect(summary.availableBalance, 900);
  });

  group('goalProjection', () {
    test('projects completion from a known weekly cadence', () {
      final asOf = DateTime(2026, 3, 1); // 8 weeks after first contribution
      final goal = _goal(target: 10000, current: 4000);
      final projection = FinanceCalculators.goalProjection(
        goal: goal,
        linkedTransactions: [
          _linkedDeposit(amount: 2000, date: DateTime(2026, 1, 4), goalId: 7),
          _linkedDeposit(amount: 2000, date: DateTime(2026, 2, 1), goalId: 7),
        ],
        asOf: asOf,
      );
      // 4000 over 8 weeks -> 500/week; 6000 remaining -> 12 weeks -> ~May 24.
      expect(projection.weeklyRate, closeTo(500, 1));
      expect(projection.estimatedCompletion, isNotNull);
      expect(projection.estimatedCompletion!.isAfter(asOf), isTrue);
      expect(projection.requiredWeeklyForDeadline, isNull);
    });

    test('no contributions -> null completion, zero rate', () {
      final projection = FinanceCalculators.goalProjection(
        goal: _goal(target: 10000, current: 0),
        linkedTransactions: const [],
        asOf: DateTime(2026, 3, 1),
      );
      expect(projection.weeklyRate, 0);
      expect(projection.estimatedCompletion, isNull);
    });

    test('deadline -> required weekly amount', () {
      final projection = FinanceCalculators.goalProjection(
        goal: _goal(
          target: 10000,
          current: 2000,
          deadline: DateTime(2026, 4, 1),
        ),
        linkedTransactions: [
          _linkedDeposit(amount: 2000, date: DateTime(2026, 2, 1), goalId: 7),
        ],
        asOf: DateTime(2026, 3, 4), // 4 weeks to deadline
      );
      // 8000 remaining over 4 weeks -> 2000/week.
      expect(projection.requiredWeeklyForDeadline, closeTo(2000, 50));
    });
  });

  group('monthRecap', () {
    test('summarises net saved, savings rate, and budget delta', () {
      final month = DateTime(2026, 9);
      final recap = FinanceCalculators.monthRecap(
        month: month,
        transactions: [
          _income(amount: 10000, date: DateTime(2026, 9, 1)),
          _expense(amount: 3000, date: DateTime(2026, 9, 5)),
          _savingsDeposit(amount: 2000, date: DateTime(2026, 9, 10)),
        ],
        categories: const [],
        monthlyExpenseBudget: 5000,
      );
      expect(recap.income, 10000);
      expect(recap.expenses, 3000);
      expect(recap.netSaved, 2000);
      expect(recap.savingsRate, closeTo(0.2, 1e-9));
      expect(recap.budgetDelta, 2000); // 5000 - 3000, under
    });

    test('no budget -> null budgetDelta', () {
      final recap = FinanceCalculators.monthRecap(
        month: DateTime(2026, 9),
        transactions: [_expense(amount: 100, date: DateTime(2026, 9, 2))],
        categories: const [],
      );
      expect(recap.budgetDelta, isNull);
    });
  });

  group('balanceTrend', () {
    test('reconstructs month-end totals and carries empty months forward', () {
      final points = FinanceCalculators.balanceTrend(
        transactions: [
          _income(amount: 500, date: DateTime(2026, 6, 10)),
          _savingsDeposit(amount: 300, date: DateTime(2026, 7, 5)),
          _expense(amount: 200, date: DateTime(2026, 8, 20)),
        ],
        initialBalance: 1000,
        months: 4,
        asOf: DateTime(2026, 9, 15),
      );
      expect(points, hasLength(4));
      expect(points[0].month, DateTime(2026, 6));
      expect(points[0].total, 1500);
      expect(points[0].savings, 0);
      expect(points[0].available, 1500);
      expect(points[1].total, 1500);
      expect(points[1].savings, 300);
      expect(points[1].available, 1200);
      expect(points[2].total, 1300);
      expect(points[2].available, 1000);
      expect(points[3].month, DateTime(2026, 9));
      expect(points[3].total, 1300);
      expect(points[3].savings, 300);
      expect(points[3].available, 1000);
    });

    test('history before the window folds into the first point', () {
      final points = FinanceCalculators.balanceTrend(
        transactions: [
          _income(amount: 9000, date: DateTime(2025, 1, 1)),
          _expense(amount: 1000, date: DateTime(2025, 2, 1)),
        ],
        initialBalance: 0,
        months: 3,
        asOf: DateTime(2026, 9, 15),
      );
      expect(points.first.total, 8000);
      expect(points.last.total, 8000);
    });
  });

  group('monthlyAnalytics budgets', () {
    final month = DateTime(2026, 9);

    CategoriesTableData cat(int id, String name) => CategoriesTableData(
      id: id,
      name: name,
      icon: 'restaurant',
      color: 0xFFFF6B6B,
      isPredefined: true,
      isDollarCategory: false,
    );

    test('breakdown carries the matching category budget', () {
      final analytics = FinanceCalculators.monthlyAnalytics(
        transactions: [
          _mkTx(
            'expense',
            1200,
            DateTime(2026, 9, 4),
          ).copyWith(categoryId: const Value(1)),
          _mkTx(
            'expense',
            300,
            DateTime(2026, 9, 9),
          ).copyWith(categoryId: const Value(2)),
        ],
        categories: [cat(1, 'Food'), cat(2, 'Transport')],
        month: month,
        categoryBudgets: const {1: 2000.0},
      );
      final food = analytics.categories.firstWhere((c) => c.categoryId == 1);
      final transport = analytics.categories.firstWhere(
        (c) => c.categoryId == 2,
      );
      expect(food.monthlyLimit, 2000.0);
      expect(transport.monthlyLimit, isNull);
    });

    test('no budgets map -> all limits null', () {
      final analytics = FinanceCalculators.monthlyAnalytics(
        transactions: [
          _mkTx(
            'expense',
            500,
            DateTime(2026, 9, 4),
          ).copyWith(categoryId: const Value(1)),
        ],
        categories: [cat(1, 'Food')],
        month: month,
      );
      expect(analytics.categories.single.monthlyLimit, isNull);
    });
  });

  group('dollarSummary pacing', () {
    test('projects year-end from ytd spend at day-of-year rate', () {
      final asOf = DateTime(2026, 4, 10); // day 100 of a 365-day year
      final summary = FinanceCalculators.dollarSummary(
        expenses: [
          _dollar(amount: 300, date: DateTime(2026, 2, 1)),
          _dollar(amount: 200, date: DateTime(2026, 3, 1)),
          _dollar(amount: 100, date: DateTime(2025, 12, 1)),
        ],
        annualLimit: 1000,
        year: 2026,
        asOf: asOf,
      );
      expect(summary.spentYtd, 500);
      expect(summary.pacePerDay, closeTo(5, 1e-6));
      expect(summary.projectedYearEnd, closeTo(1825, 1e-3));
      expect(summary.projectedVsLimit, closeTo(825, 1e-3));
    });

    test('zero ytd spend -> zero projection', () {
      final summary = FinanceCalculators.dollarSummary(
        expenses: const [],
        annualLimit: 1000,
        year: 2026,
        asOf: DateTime(2026, 6, 1),
      );
      expect(summary.pacePerDay, 0);
      expect(summary.projectedYearEnd, 0);
      expect(summary.projectedVsLimit, -1000);
    });
  });

  group('fixes 2026-10-28', () {
    test('runway counts a quiet stretch as zero spending', () {
      // Long-time user, nothing logged for weeks, then one 6,000 expense.
      final runway = FinanceCalculators.spendingRunway(
        transactions: [
          _income(amount: 50000, date: DateTime(2026, 6, 1)),
          _expense(amount: 6000, date: DateTime(2026, 10, 25)),
        ],
        availableBalance: 30000,
        asOf: DateTime(2026, 10, 28),
      );
      // Baseline over the full 30-day window (200/day), not 4 days (1,500).
      expect(
        runway.dailyPace,
        closeTo(6000 / 30 * 0.35 + 6000 / 7 * 0.65, 1e-6),
      );
    });

    test('savings month-over-month sign follows better/worse', () {
      double delta(double previous, double current) =>
          FinanceCalculators.savingsInsights(
            transactions: [
              if (previous != 0)
                _mkTx(
                  previous > 0 ? 'savings_deposit' : 'savings_withdrawal',
                  previous.abs(),
                  DateTime(2026, 9, 10),
                ),
              if (current != 0)
                _mkTx(
                  current > 0 ? 'savings_deposit' : 'savings_withdrawal',
                  current.abs(),
                  DateTime(2026, 10, 10),
                ),
            ],
            referenceMonth: DateTime(2026, 10),
          ).monthOverMonthDelta;

      expect(delta(-2000, 1000), closeTo(1.5, 1e-9));
      expect(delta(0, -3000), -1.0);
      expect(delta(-2000, -4000), closeTo(-1.0, 1e-9));
      expect(delta(1000, 1500), closeTo(0.5, 1e-9));
    });

    test('average monthly savings includes quiet months, not future ones', () {
      final insights = FinanceCalculators.savingsInsights(
        transactions: [
          _savingsDeposit(amount: 12000, date: DateTime(2026, 1, 5)),
          _savingsDeposit(amount: 99999, date: DateTime(2026, 12, 5)),
        ],
        referenceMonth: DateTime(2026, 10),
      );
      expect(insights.averageMonthlySavings, closeTo(1200, 1e-9));
    });

    test('dollar pace waits a month and ignores future-dated expenses', () {
      final early = FinanceCalculators.dollarSummary(
        expenses: [_dollar(amount: 300, date: DateTime(2027, 1, 1))],
        annualLimit: 12000,
        year: 2027,
        asOf: DateTime(2027, 1, 2),
      );
      expect(early.hasPace, isFalse);
      expect(early.projectedOver, isFalse);

      final later = FinanceCalculators.dollarSummary(
        expenses: [
          _dollar(amount: 300, date: DateTime(2026, 2, 1)),
          _dollar(amount: 500, date: DateTime(2026, 12, 1)),
        ],
        annualLimit: 12000,
        year: 2026,
        asOf: DateTime(2026, 10, 28),
      );
      expect(later.hasPace, isTrue);
      expect(later.spentYtd, 300);
    });

    test('a passed deadline asks for no weekly amount', () {
      final projection = FinanceCalculators.goalProjection(
        goal: _goal(
          target: 1000,
          current: 200,
          deadline: DateTime(2026, 10, 1),
        ),
        linkedTransactions: [
          _linkedDeposit(amount: 200, date: DateTime(2026, 9, 1), goalId: 7),
        ],
        asOf: DateTime(2026, 10, 28),
      );
      expect(projection.requiredWeeklyForDeadline, isNull);
    });

    test('calendarDaysUntil ignores time of day', () {
      expect(
        calendarDaysUntil(
          DateTime(2026, 10, 29),
          from: DateTime(2026, 10, 28, 15),
        ),
        1,
      );
      expect(
        calendarDaysUntil(DateTime(2026, 10, 27), from: DateTime(2026, 10, 28)),
        -1,
      );
    });

    test('upcoming lists future entries and Available after them', () {
      final summary = FinanceCalculators.upcoming(
        transactions: [
          _expense(amount: 15000, date: DateTime(2026, 11, 1)),
          _income(amount: 50000, date: DateTime(2026, 10, 31)),
          _savingsDeposit(amount: 5000, date: DateTime(2026, 11, 2)),
          _expense(amount: 999, date: DateTime(2026, 10, 1)), // posted
        ],
        availableNow: 10000,
        asOf: DateTime(2026, 10, 28),
      );
      expect(summary.entries.map((e) => e.amount), [50000, 15000, 5000]);
      expect(summary.availableAfter, 10000 + 50000 - 15000 - 5000);
    });

    test('safe to spend runs to the usual payday, net of scheduled', () {
      final safe = FinanceCalculators.safeToSpend(
        transactions: [
          _income(amount: 80000, date: DateTime(2026, 8, 25)),
          _income(amount: 80000, date: DateTime(2026, 9, 26)),
          _income(amount: 2000, date: DateTime(2026, 10, 3)), // not salary
          _expense(amount: 1000, date: DateTime(2026, 11, 2)), // scheduled
        ],
        availableNow: 9000,
        asOf: DateTime(2026, 10, 28, 12),
      );
      // Days 25 and 26 seen; lower median 25 has passed, so Nov 25.
      expect(safe.isPayday, isTrue);
      expect(safe.until, DateTime(2026, 11, 25));
      expect(safe.days, 28);
      expect(safe.perDay, closeTo((9000 - 1000) / 28, 1e-9));
    });

    test('safe to spend falls back to month end without a payday', () {
      final safe = FinanceCalculators.safeToSpend(
        transactions: const [],
        availableNow: 400,
        asOf: DateTime(2026, 10, 28),
      );
      expect(safe.isPayday, isFalse);
      expect(safe.until, DateTime(2026, 11));
      expect(safe.days, 4); // 28, 29, 30, 31
      expect(safe.perDay, 100);
    });

    test('recap flags categories well off their 3-month usual', () {
      TransactionsTableData spend(int cat, double amount, DateTime date) =>
          _expense(
            amount: amount,
            date: date,
          ).copyWith(id: cat * 1000 + date.month, categoryId: Value(cat));
      CategoriesTableData category(int id, String name) => CategoriesTableData(
        id: id,
        name: name,
        icon: 'x',
        color: 0,
        isPredefined: false,
        isDollarCategory: false,
      );

      final recap = FinanceCalculators.monthRecap(
        month: DateTime(2026, 9),
        transactions: [
          for (final m in [6, 7, 8]) spend(1, 1000, DateTime(2026, m, 5)),
          spend(1, 1400, DateTime(2026, 9, 5)), // Food +40%
          for (final m in [6, 7, 8]) spend(2, 1000, DateTime(2026, m, 6)),
          spend(2, 1100, DateTime(2026, 9, 6)), // Rent +10%: not notable
          spend(3, 900, DateTime(2026, 9, 7)), // no history: skipped
        ],
        categories: [
          category(1, 'Food'),
          category(2, 'Rent'),
          category(3, 'Gifts'),
        ],
      );
      expect(recap.categoryChanges.map((c) => c.category.name), ['Food']);
      expect(recap.categoryChanges.single.change, closeTo(0.4, 1e-9));
    });

    test('budget pace is the share of the current month gone', () {
      final now = DateTime(2026, 10, 15, 9);
      expect(monthPaceFraction(DateTime(2026, 10), now: now), 15 / 31);
      expect(monthPaceFraction(DateTime(2026, 9), now: now), isNull);
      expect(monthPaceFraction(DateTime(2026, 11), now: now), isNull);
    });

    test('amounts that round to zero never print a minus sign', () {
      expect(formatBdtAmount(-0.3), '৳ 0');
      expect(formatBdtAmount(-0.0), '৳ 0');
      expect(formatBdtAmount(-1), '-৳ 1');
    });
  });
}
