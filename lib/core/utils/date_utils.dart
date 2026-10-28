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

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
