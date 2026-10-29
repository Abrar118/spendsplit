import '../../core/constants/enums.dart';
import '../../core/utils/date_utils.dart';
import '../../data/database/app_database.dart';

/// Month-to-date spending, running totals per day.
class MonthPace {
  const MonthPace({required this.current, required this.previous});

  /// Running total for day 1 up to today of this month (index 0 = day 1).
  final List<double> current;

  /// Running total for every day of last month.
  final List<double> previous;

  double get spentSoFar => current.isEmpty ? 0 : current.last;

  /// Last month's total by the same day of the month (or its last day, when
  /// last month was shorter).
  double get previousBySameDay {
    if (previous.isEmpty) return 0;
    final day = current.length.clamp(1, previous.length);
    return previous[day - 1];
  }
}

MonthPace buildMonthPace(List<TransactionsTableData> entries, DateTime now) {
  final thisMonth = DateTime(now.year, now.month);
  final lastMonth = DateTime(now.year, now.month - 1);
  final current = List<double>.filled(now.day, 0);
  final previous = List<double>.filled(_daysIn(lastMonth), 0);

  for (final entry in entries) {
    if (TransactionType.fromDbValue(entry.type) != TransactionType.expense) {
      continue;
    }
    final d = entry.date;
    if (d.year == thisMonth.year && d.month == thisMonth.month) {
      if (d.day <= current.length) current[d.day - 1] += entry.amount;
    } else if (d.year == lastMonth.year && d.month == lastMonth.month) {
      previous[d.day - 1] += entry.amount;
    }
  }
  return MonthPace(
    current: _runningTotal(current),
    previous: _runningTotal(previous),
  );
}

/// Spending per calendar day for whole weeks (Monday first), ending today.
class DailySpend {
  const DailySpend({required this.start, required this.days});

  /// The Monday the grid starts on.
  final DateTime start;

  /// Spending for each day from [start] up to today (index 0 = [start]).
  final List<double> days;

  DateTime dateAt(int index) =>
      DateTime(start.year, start.month, start.day + index);

  /// Cut points between the four shades: the quartiles of the days that had
  /// any spending, so a single large day doesn't wash out the rest.
  List<double> get thresholds {
    final spent = days.where((v) => v > 0).toList()..sort();
    if (spent.isEmpty) return const [];
    double at(double q) => spent[((spent.length - 1) * q).round()];
    return [at(0.25), at(0.5), at(0.75)];
  }

  /// 0 for no spending, then 1–4 from lightest to strongest.
  int level(double amount, List<double> cuts) {
    if (amount <= 0) return 0;
    var level = 1;
    for (final cut in cuts) {
      if (amount > cut) level++;
    }
    return level;
  }
}

DailySpend buildDailySpend(
  List<TransactionsTableData> entries,
  DateTime now, {
  int weeks = 13,
}) {
  final today = DateTime(now.year, now.month, now.day);
  final thisMonday = DateTime(
    today.year,
    today.month,
    today.day - (today.weekday - 1),
  );
  final start = DateTime(
    thisMonday.year,
    thisMonday.month,
    thisMonday.day - 7 * (weeks - 1),
  );
  final count = calendarDaysUntil(today, from: start) + 1;
  final days = List<double>.filled(count, 0);

  for (final entry in entries) {
    if (TransactionType.fromDbValue(entry.type) != TransactionType.expense) {
      continue;
    }
    final index = calendarDaysUntil(entry.date, from: start);
    if (index >= 0 && index < count) days[index] += entry.amount;
  }
  return DailySpend(start: start, days: days);
}

int _daysIn(DateTime month) => DateTime(month.year, month.month + 1, 0).day;

List<double> _runningTotal(List<double> perDay) {
  var sum = 0.0;
  return [for (final v in perDay) sum += v];
}
