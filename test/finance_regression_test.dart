import 'package:flutter_test/flutter_test.dart';
import 'package:spendsplit/data/database/app_database.dart';
import 'package:spendsplit/data/models/financial_summaries.dart';

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
}
