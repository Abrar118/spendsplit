import 'package:intl/intl.dart';

String formatBdtAmount(num amount, {int fractionDigits = 0}) {
  final formatter = NumberFormat.currency(
    locale: 'en_US',
    symbol: '৳ ',
    decimalDigits: fractionDigits,
  );
  return formatter.format(amount);
}

String formatCompactBdt(num amount) {
  final formatter = NumberFormat.compactCurrency(
    locale: 'en_US',
    symbol: '৳',
    decimalDigits: amount.abs() >= 10000 ? 0 : 1,
  );
  return formatter.format(amount);
}

String formatUsdAmount(num amount, {int fractionDigits = 0}) {
  final formatter = NumberFormat.currency(
    locale: 'en_US',
    symbol: r'$',
    decimalDigits: fractionDigits,
  );
  return formatter.format(amount);
}
