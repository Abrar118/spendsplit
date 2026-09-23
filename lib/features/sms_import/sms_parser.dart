/// A Trust Bank transaction alert:
///
/// ```
/// POS Txn
/// TK 70.00 DEBIT
/// AC No 031***492
/// 21/09/2026 05:28 PM
/// Balance TK 480578.45
/// ```
class ParsedSms {
  const ParsedSms({
    required this.label,
    required this.amount,
    required this.isCredit,
    required this.dateTime,
    required this.balance,
  });

  final String label;
  final double amount;
  final bool isCredit;
  final DateTime dateTime;
  final double balance;
}

final _labelLine = RegExp(r'^.+\bTxn$', caseSensitive: false);
final _amountLine = RegExp(
  r'^TK\s+([\d,]+(?:\.\d+)?)\s+(DEBIT|CREDIT)$',
  caseSensitive: false,
);
final _dateLine = RegExp(
  r'^(\d{1,2})/(\d{1,2})/(\d{4})\s+(\d{1,2}):(\d{2})\s*([AP]M)$',
  caseSensitive: false,
);
final _balanceLine = RegExp(
  r'^Balance\s+TK\s+(-?[\d,]+(?:\.\d+)?)$',
  caseSensitive: false,
);

/// Returns null for anything that isn't a transaction alert (OTPs, promos).
ParsedSms? parseTrustBankSms(String body) {
  final lines = body
      .split(RegExp(r'\r?\n'))
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();
  if (lines.isEmpty || !_labelLine.hasMatch(lines.first)) return null;

  RegExpMatch? find(RegExp pattern) {
    for (final line in lines) {
      final match = pattern.firstMatch(line);
      if (match != null) return match;
    }
    return null;
  }

  final amountMatch = find(_amountLine);
  final dateMatch = find(_dateLine);
  final balanceMatch = find(_balanceLine);
  if (amountMatch == null || dateMatch == null || balanceMatch == null) {
    return null;
  }

  final amount = _money(amountMatch.group(1)!);
  final balance = _money(balanceMatch.group(1)!);
  final dateTime = _dateTime(dateMatch);
  if (amount == null || amount <= 0 || balance == null || dateTime == null) {
    return null;
  }

  return ParsedSms(
    label: lines.first,
    amount: amount,
    isCredit: amountMatch.group(2)!.toUpperCase() == 'CREDIT',
    dateTime: dateTime,
    balance: balance,
  );
}

double? _money(String raw) => double.tryParse(raw.replaceAll(',', ''));

DateTime? _dateTime(RegExpMatch m) {
  final day = int.parse(m.group(1)!);
  final month = int.parse(m.group(2)!);
  final year = int.parse(m.group(3)!);
  final hour12 = int.parse(m.group(4)!);
  final minute = int.parse(m.group(5)!);
  if (month < 1 || month > 12 || hour12 < 1 || hour12 > 12 || minute > 59) {
    return null;
  }
  final hour = hour12 % 12 + (m.group(6)!.toUpperCase() == 'PM' ? 12 : 0);
  final result = DateTime(year, month, day, hour, minute);
  // DateTime rolls 31/02 over into March; reject instead.
  return result.month == month && result.day == day ? result : null;
}
