import 'package:drift/drift.dart';

import '../../core/constants/categories.dart';
import '../../core/constants/enums.dart';
import '../../data/database/app_database.dart';
import 'sms_parser.dart';

/// One row from the phone's SMS inbox.
class InboxSms {
  const InboxSms({required this.body, required this.receivedMillis});

  final String body;

  /// The provider's `date` column: when the phone received the SMS.
  final int receivedMillis;

  /// Stored in `sms_ref`; also how already-processed SMS are recognised.
  String get ref => '$receivedMillis|$body';
}

int receivedMillisOfRef(String ref) =>
    int.parse(ref.substring(0, ref.indexOf('|')));

class SmsImportResult {
  const SmsImportResult({
    required this.inserted,
    required this.newestReceivedMillis,
    this.latest,
  });

  final int inserted;

  /// Max receive time seen, parsed or not: the next watermark. Null when
  /// there were no messages.
  final int? newestReceivedMillis;

  /// The parsed SMS with the latest transaction time (for reconciliation).
  final ParsedSms? latest;
}

/// Inserts one transaction per parseable SMS. Insert-only: never updates or
/// deletes, and the unique `sms_ref` index silently drops repeats.
Future<SmsImportResult> importSmsMessages(
  AppDatabase db,
  List<InboxSms> messages,
) {
  return db.transaction(() async {
    final other =
        await (db.select(db.categoriesTable)..where(
              (c) =>
                  c.name.equals(DefaultCategories.other) &
                  c.isDollarCategory.equals(false),
            ))
            .getSingleOrNull();

    var inserted = 0;
    int? newest;
    ParsedSms? latest;
    for (final sms in messages) {
      if (newest == null || sms.receivedMillis > newest) {
        newest = sms.receivedMillis;
      }
      final parsed = parseTrustBankSms(sms.body);
      if (parsed == null) continue;
      if (latest == null || !parsed.dateTime.isBefore(latest.dateTime)) {
        latest = parsed;
      }

      final row = await db
          .into(db.transactionsTable)
          .insertReturningOrNull(
            TransactionsTableCompanion.insert(
              type: parsed.isCredit
                  ? TransactionType.income.dbValue
                  : TransactionType.expense.dbValue,
              amount: parsed.amount,
              categoryId: Value(parsed.isCredit ? null : other?.id),
              source: Value(
                parsed.isCredit ? IncomeSource.other.dbValue : null,
              ),
              note: Value(parsed.label),
              date: parsed.dateTime,
              smsRef: Value(sms.ref),
              needsReview: const Value(true),
            ),
            mode: InsertMode.insertOrIgnore,
          );
      if (row != null) inserted++;
    }

    return SmsImportResult(
      inserted: inserted,
      newestReceivedMillis: newest,
      latest: latest,
    );
  });
}
