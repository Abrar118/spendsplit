import 'package:intl/intl.dart';

String formatMonthYear(DateTime date) {
  return DateFormat('MMMM yyyy').format(date);
}

String formatShortDate(DateTime date) {
  return DateFormat('MMM d, yyyy').format(date);
}

String formatSheetDate(DateTime date, {DateTime? reference}) {
  final now = reference ?? DateTime.now();
  if (_isSameDay(date, now)) {
    return 'Today, ${DateFormat('MMM d yyyy').format(date)}';
  }
  return formatShortDate(date);
}

String formatTransactionHeader(DateTime date, {DateTime? reference}) {
  final now = reference ?? DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(date.year, date.month, date.day);
  final yesterday = today.subtract(const Duration(days: 1));

  if (target == today) return 'TODAY';
  if (target == yesterday) return 'YESTERDAY';
  return DateFormat('MMMM d, yyyy').format(date).toUpperCase();
}

/// Whole calendar days from [from] (default now) to [date], ignoring time of
/// day: tomorrow is always 1, and the result goes negative once [date] has
/// passed. UTC dates so a DST shift can't turn a day into 23 hours.
int calendarDaysUntil(DateTime date, {DateTime? from}) {
  final now = from ?? DateTime.now();
  return DateTime.utc(
    date.year,
    date.month,
    date.day,
  ).difference(DateTime.utc(now.year, now.month, now.day)).inDays;
}

/// [day]'s calendar date at [time]'s time of day. Date pickers return
/// midnight; this keeps an entry's time when only its date changes.
DateTime onDayKeepingTime(DateTime day, DateTime time) => DateTime(
  day.year,
  day.month,
  day.day,
  time.hour,
  time.minute,
  time.second,
  time.millisecond,
);

/// Share of [month] gone by the end of today, for budget pace markers.
/// Null unless [month] is the current month: past months are complete and
/// future ones haven't started.
double? monthPaceFraction(DateTime month, {DateTime? now}) {
  final today = now ?? DateTime.now();
  if (month.year != today.year || month.month != today.month) return null;
  final daysInMonth = DateTime(today.year, today.month + 1, 0).day;
  return today.day / daysInMonth;
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
