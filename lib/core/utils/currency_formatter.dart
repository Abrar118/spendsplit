import 'dart:math' as math;

import 'package:intl/intl.dart';

String formatBdtAmount(num amount, {int fractionDigits = 0}) {
  final formatter = NumberFormat.currency(
    locale: 'en_US',
    symbol: '৳ ',
    decimalDigits: fractionDigits,
  );
  return formatter.format(_zeroIfRoundsAway(amount, fractionDigits));
}

String formatCompactBdt(num amount) {
  final formatter = NumberFormat.compactCurrency(
    locale: 'en_US',
    symbol: '৳',
    decimalDigits: amount.abs() >= 10000 ? 0 : 1,
  );
  return formatter.format(_zeroIfRoundsAway(amount, 1));
}

String formatUsdAmount(num amount, {int fractionDigits = 0}) {
  final formatter = NumberFormat.currency(
    locale: 'en_US',
    symbol: r'$',
    decimalDigits: fractionDigits,
  );
  return formatter.format(_zeroIfRoundsAway(amount, fractionDigits));
}

/// Tiny negatives (float leftovers, -0.0) would otherwise print as "-৳ 0".
num _zeroIfRoundsAway(num amount, int fractionDigits) =>
    amount.abs() < 0.5 / math.pow(10, fractionDigits) ? 0 : amount;
