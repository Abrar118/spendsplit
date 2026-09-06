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
}
