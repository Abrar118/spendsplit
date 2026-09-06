import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:spendsplit/data/database/app_database.dart';
import 'package:spendsplit/data/models/financial_summaries.dart';

TransactionsTableData _mkTx(String type, double amount, DateTime date) =>
    TransactionsTableData(
      id: date.microsecondsSinceEpoch % 100000000,
      type: type,
      amount: amount,
      date: date,
      createdAt: date,
    );

TransactionsTableData _expense({required double amount, required DateTime date}) =>
    _mkTx('expense', amount, date);
TransactionsTableData _income({required double amount, required DateTime date}) =>
    _mkTx('income', amount, date);
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
      expect(runway.avgDailyBurn, 0);
      expect(runway.daysRemaining, isNull);
    });

    test('computes burn and days from trailing 30 days of expenses only', () {
      final runway = FinanceCalculators.spendingRunway(
        transactions: [
          _expense(amount: 3000, date: DateTime(2026, 9, 5)),
          _expense(amount: 3000, date: DateTime(2026, 9, 20)),
          _income(amount: 50000, date: DateTime(2026, 9, 15)),
          _savingsDeposit(amount: 10000, date: DateTime(2026, 9, 15)),
        ],
        availableBalance: 30000,
        asOf: asOf,
        windowDays: 30,
      );
      expect(runway.avgDailyBurn, closeTo(200, 1e-6));
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
}
