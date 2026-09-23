import 'package:flutter_test/flutter_test.dart';
import 'package:spendsplit/features/sms_import/sms_parser.dart';

String sms(String label, String amountLine, String date, String balance) =>
    '$label\n$amountLine\nAC No 031***492\n$date\nBalance TK $balance\n'
    'Call Center at your fingertips: t.tblbd.com/SIVR';

void main() {
  final samples = [
    (
      sms('POS Txn', 'TK 70.00 DEBIT', '21/09/2026 05:28 PM', '480578.45'),
      ('POS Txn', 70.0, false, DateTime(2026, 9, 21, 17, 28), 480578.45),
    ),
    (
      sms(
        'TRUST MONEY Txn',
        'TK 223.00 DEBIT',
        '21/09/2026 04:03 PM',
        '480648.45',
      ),
      (
        'TRUST MONEY Txn',
        223.0,
        false,
        DateTime(2026, 9, 21, 16, 3),
        480648.45,
      ),
    ),
    (
      sms(
        'TRUST MONEY Txn',
        'TK 1000.00 DEBIT',
        '13/09/2026 09:19 PM',
        '490681.55',
      ),
      (
        'TRUST MONEY Txn',
        1000.0,
        false,
        DateTime(2026, 9, 13, 21, 19),
        490681.55,
      ),
    ),
    (
      sms(
        'TRUST MONEY Txn',
        'TK 14500.00 CREDIT',
        '05/09/2026 08:40 PM',
        '498503.55',
      ),
      (
        'TRUST MONEY Txn',
        14500.0,
        true,
        DateTime(2026, 9, 5, 20, 40),
        498503.55,
      ),
    ),
    (
      sms(
        'BRANCH TRANSFER Txn',
        'TK 77000.00 CREDIT',
        '31/08/2026 12:41 PM',
        '484003.55',
      ),
      (
        'BRANCH TRANSFER Txn',
        77000.0,
        true,
        DateTime(2026, 8, 31, 12, 41),
        484003.55,
      ),
    ),
  ];

  for (final (body, expected) in samples) {
    test('parses ${expected.$1} ${expected.$2}', () {
      final p = parseTrustBankSms(body)!;
      expect((p.label, p.amount, p.isCredit, p.dateTime, p.balance), expected);
    });
  }

  test('tolerates thousands separators', () {
    final p = parseTrustBankSms(
      sms('POS Txn', 'TK 1,000.00 DEBIT', '21/09/2026 05:28 PM', '480,578.45'),
    )!;
    expect(p.amount, 1000.0);
    expect(p.balance, 480578.45);
  });

  test('12 AM is midnight', () {
    final p = parseTrustBankSms(
      sms('POS Txn', 'TK 5.00 DEBIT', '22/09/2026 12:05 AM', '10.00'),
    )!;
    expect(p.dateTime, DateTime(2026, 9, 22, 0, 5));
  });

  test('tolerates CRLF line endings and trailing spaces', () {
    final body = sms(
      'POS Txn',
      'TK 70.00 DEBIT',
      '21/09/2026 05:28 PM',
      '480578.45',
    ).split('\n').map((l) => '$l  ').join('\r\n');
    expect(parseTrustBankSms(body)?.amount, 70.0);
  });

  test('ignores OTPs, promos and malformed alerts', () {
    expect(parseTrustBankSms('Your OTP is 482913. Do not share it.'), isNull);
    expect(
      parseTrustBankSms('Enjoy 10% cashback with Trust Bank cards!\nT&C apply'),
      isNull,
    );
    expect(
      parseTrustBankSms(
        sms('POS Txn', 'TK 70.00 DEBIT', '31/02/2026 05:28 PM', '1.00'),
      ),
      isNull,
    );
    expect(
      parseTrustBankSms(
        sms('POS Txn', 'TK 0.00 DEBIT', '21/09/2026 05:28 PM', '1.00'),
      ),
      isNull,
    );
  });
}
