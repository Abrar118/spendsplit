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

/// Whole taka show no decimals; anything with paisa shows two.
String formatBdtExact(num amount) => formatBdtAmount(
  amount,
  fractionDigits: amount.roundToDouble() == amount ? 0 : 2,
);

String formatCompactBdt(num amount) {
  // Compact form only abbreviates from 1K up; below that a decimal is noise.
  final abs = amount.abs();
  final formatter = NumberFormat.compactCurrency(
    locale: 'en_US',
    symbol: '৳',
    decimalDigits: abs >= 1000 && abs < 10000 ? 1 : 0,
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
