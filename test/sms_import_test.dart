import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendsplit/core/constants/categories.dart';
import 'package:spendsplit/data/database/app_database.dart';
import 'package:spendsplit/features/sms_import/sms_importer.dart';

const debitBody =
    'POS Txn\nTK 70.00 DEBIT\nAC No 031***492\n21/09/2026 05:28 PM\n'
    'Balance TK 480578.45';
const creditBody =
    'BRANCH TRANSFER Txn\nTK 77000.00 CREDIT\nAC No 031***492\n'
    '31/08/2026 12:41 PM\nBalance TK 484003.55';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(executor: NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<List<TransactionsTableData>> rows() => (db.select(
    db.transactionsTable,
  )..orderBy([(t) => OrderingTerm.asc(t.id)])).get();

  test('debit -> expense in Other, credit -> income from other', () async {
    final result = await importSmsMessages(db, const [
      InboxSms(body: creditBody, receivedMillis: 1000),
      InboxSms(body: debitBody, receivedMillis: 2000),
    ]);
    expect(result.inserted, 2);
    expect(result.newestReceivedMillis, 2000);

    final other = (await db.select(db.categoriesTable).get()).firstWhere(
      (c) => c.name == DefaultCategories.other && !c.isDollarCategory,
    );
    final [credit, debit] = await rows();
    expect(
      (
        credit.type,
        credit.amount,
        credit.categoryId,
        credit.source,
        credit.note,
      ),
      ('income', 77000.0, null, 'other', 'BRANCH TRANSFER Txn'),
    );
    expect(credit.date, DateTime(2026, 8, 31, 12, 41));
    expect(
      (debit.type, debit.amount, debit.categoryId, debit.source, debit.note),
      ('expense', 70.0, other.id, null, 'POS Txn'),
    );
    expect(debit.smsRef, '2000|$debitBody');
    expect(credit.needsReview && debit.needsReview, isTrue);
  });

  test('the same SMS imported twice is one row', () async {
    const sms = InboxSms(body: debitBody, receivedMillis: 2000);
    await importSmsMessages(db, const [sms]);
    final second = await importSmsMessages(db, const [sms]);
    expect(second.inserted, 0);
    expect(await rows(), hasLength(1));
  });

  test('identical bodies received at different times are two rows', () async {
    final result = await importSmsMessages(db, const [
      InboxSms(body: debitBody, receivedMillis: 2000),
      InboxSms(body: debitBody, receivedMillis: 2001),
    ]);
    expect(result.inserted, 2);
  });

  test('unparseable SMS still advance the watermark', () async {
    final result = await importSmsMessages(db, const [
      InboxSms(body: 'Your OTP is 123456', receivedMillis: 9000),
    ]);
    expect(result.inserted, 0);
    expect(result.newestReceivedMillis, 9000);
    expect(result.latest, isNull);
    expect(await rows(), isEmpty);
  });

  test('existing hand-entered rows are untouched', () async {
    final id = await db.transactionDao.insertTransaction(
      TransactionsTableCompanion.insert(
        type: 'expense',
        amount: 70,
        note: const Value('Lunch'),
        date: DateTime(2026, 9, 21, 17, 28),
      ),
    );
    final before = await db.transactionDao.getTransactionById(id);
    await importSmsMessages(db, const [
      InboxSms(body: debitBody, receivedMillis: 2000),
    ]);
    expect(await db.transactionDao.getTransactionById(id), before);
    expect(await rows(), hasLength(2));
  });

  test('latest is the newest transaction time, not receive order', () async {
    final result = await importSmsMessages(db, const [
      InboxSms(body: debitBody, receivedMillis: 1000), // 21 Sep
      InboxSms(body: creditBody, receivedMillis: 2000), // 31 Aug
    ]);
    expect(result.latest!.balance, 480578.45);
  });
}
