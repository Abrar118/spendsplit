import 'package:flutter_test/flutter_test.dart';
import 'package:spendsplit/data/database/app_database.dart';
import 'package:spendsplit/features/graphs/graph_series.dart';

TransactionsTableData _tx(String type, double amount, DateTime date) =>
    TransactionsTableData(
      id: date.microsecondsSinceEpoch % 100000000,
      type: type,
      amount: amount,
      date: date,
      createdAt: date,
      needsReview: false,
    );

void main() {
  test('month pace keeps running totals and compares by the same day', () {
    final now = DateTime(2026, 3, 10, 18);
    final pace = buildMonthPace([
      _tx('expense', 100, DateTime(2026, 3, 2, 9)),
      _tx('expense', 50, DateTime(2026, 3, 10, 8)),
      _tx('income', 999, DateTime(2026, 3, 3)),
      _tx('expense', 70, DateTime(2026, 2, 5)),
      _tx('expense', 30, DateTime(2026, 2, 20)),
      _tx('expense', 500, DateTime(2026, 1, 31)),
    ], now);

    expect(pace.current, hasLength(10));
    expect(pace.current[0], 0);
    expect(pace.current[1], 100);
    expect(pace.spentSoFar, 150);
    expect(pace.previous, hasLength(28)); // February 2026
    expect(pace.previous.last, 100);
    expect(pace.previousBySameDay, 70);
  });

  test('daily spend starts on a Monday and shades by quartile', () {
    final now = DateTime(2026, 3, 11, 12); // a Wednesday
    final grid = buildDailySpend(
      [
        _tx('expense', 10, DateTime(2026, 3, 11, 9)),
        _tx('expense', 5, DateTime(2026, 3, 11, 20)),
        _tx('expense', 400, DateTime(2026, 3, 9)),
        _tx('expense', 1, DateTime(2025, 1, 1)),
      ],
      now,
      weeks: 2,
    );

    expect(grid.start, DateTime(2026, 3, 2));
    expect(grid.start.weekday, DateTime.monday);
    expect(grid.days, hasLength(10));
    expect(grid.days.last, 15);
    expect(grid.days[7], 400);
    expect(grid.level(0, grid.thresholds), 0);
    expect(grid.level(15, grid.thresholds), 1);
    expect(grid.level(400, grid.thresholds), greaterThan(1));
  });
}
