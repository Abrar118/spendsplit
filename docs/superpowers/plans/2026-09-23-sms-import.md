# Trust Bank SMS Import Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Automatically log Trust Bank debit/credit SMS as SpendSplit transactions (on app open and in the background), flag them for review, and check the app's balance against the bank's.

**Architecture:** A Kotlin `MethodChannel` (`spendsplit/sms`) exposes SMS permissions and inbox reads. A pure Dart parser + an insert-only Drift importer turn inbox rows into transactions, deduped by a unique `sms_ref` column (schema v8). One Riverpod `SmsImportRunner` owns the watermark and is triggered on app start/resume, from the running engine by `SmsReceiver`, or by a headless engine (`smsBackgroundMain`) when the app process is dead.

**Tech Stack:** Flutter, Riverpod 2, Drift 2.34 (SQLite), SharedPreferences, Kotlin (Android `Telephony` provider, `BroadcastReceiver`, headless `FlutterEngine`). No new dependencies.

**Spec:** `docs/superpowers/specs/2026-09-23-sms-import-design.md` (rev 3)

## Global Constraints

- Android only. Every Dart entry to the channel returns an empty/denied result when `!Platform.isAndroid`.
- No new pub or Gradle dependencies.
- Sender: `TrustBank`, exact match, case-insensitive (`COLLATE NOCASE` / `equals(ignoreCase = true)`).
- Schema v8, additive only: `sms_ref TEXT NULL` + `needs_review BOOLEAN NOT NULL DEFAULT false` on `transactions_table`, unique index `transactions_sms_ref` on `sms_ref`.
- `sms_ref` = `"<provider receive millis>|<full SMS body>"`.
- Importer is insert-only (`insertOrIgnore`); never updates or deletes a row.
- DEBIT → `expense`, `categoryId` = predefined non-dollar **Other**; CREDIT → `income`, `source` = `other`, `categoryId` null; `note` = SMS label (e.g. `POS Txn`); `date` = SMS body datetime; `needs_review` = true.
- SharedPreferences keys: `sms_import_since` (int ms, null = off), `bank_balance` (double), `bank_balance_at` (ISO-8601 string).
- Enabling sets `sms_import_since` to now; SMS received before that are never read.
- Reconciliation compares Total Balance (initial + income − expenses) for transactions dated `<= bank_balance_at`; card shows when `|diff| >= 1`.
- Receiver: `goAsync()` in both branches, 9 s safety timeout, `finish()` exactly once.
- Use `AppColors` / `AppSpacing` / `GlassCard`; no hand-rolled colours.
- Execute in an isolated git worktree branched from `main`, so the three uncommitted files in the main checkout (`lib/data/models/financial_summaries.dart`, `lib/features/dashboard/widgets/balance_card.dart`, `test/finance_regression_test.dart`) stay untouched. Don't modify `financial_summaries.dart` or `balance_card.dart`. The only allowed edit to `test/finance_regression_test.dart` is the Task 1 `needsReview: false` fix. Always `git add` explicit paths, never `-A` / `.`.

## Spec Deviations (need approval with this plan)

Found while reading the code for this plan:

1. **Watermark query is `date > since`, not `>=`.** With `>=`, the SMS at exactly the watermark is reread on every run; if the user deleted that imported entry, it would be imported again. `>` means that can't happen. The limit that comes with it: an SMS that has the same receive millisecond as the watermark but reaches the inbox after the read would be skipped. That's close to impossible in practice.
2. **The receiver checks the sender, and the background import retries for up to ~4 s.** Android sends `SMS_RECEIVED` to other apps at about the same moment the default SMS app writes the message to the inbox. Reading the inbox immediately often finds nothing yet. So `run(waitForNew: true)` re-reads once per second, up to 4 more times. The receiver checks the PDU's originating address first, so non-bank SMS never start an engine. It still doesn't parse the message body.
3. **`hasPermission` / `requestPermission` return `{read, receive}` from phase 1.** In phase 1 `receive` is simply false because `RECEIVE_SMS` isn't declared yet, and it is still not requested. This avoids changing the channel contract in phase 4.
4. **The receiver is declared with `android:permission="android.permission.BROADCAST_SMS"`,** so only the system can trigger it.

## Review Focus

1. **12 AM / 12 PM times:** `12:05 AM` must become 00:05 and `12:41 PM` must become 12:41. The Task 2 parser test pins this.
2. **CRLF line endings / trailing spaces** in an SMS body must still parse. Pinned by a Task 2 parser test.
3. **A deleted imported entry must not come back** on the next open. Pinned by a Task 6 runner test.
4. **Switch turned off while an import is running** must stay off; `recordSmsImport` must not re-enable it. Pinned by a Task 4 settings test.
5. **The sender address is stored differently on this phone** (e.g. a short code instead of `TrustBank`). Then imports silently find nothing. Task 5 checks it by hand with `adb`.

---

## Phase 1 — On-open import, dedupe, Settings switch

### Task 1: Schema v8 + backup compatibility

**Files:**
- Modify: `lib/data/database/tables/transactions_table.dart`
- Modify: `lib/data/database/app_database.dart` (schemaVersion + `from < 8` block)
- Modify: `lib/data/repositories/snapshot_service.dart:89-97`
- Regenerate: `lib/data/database/app_database.g.dart`, `lib/data/database/daos/*.g.dart`
- Test: `test/migration_test.dart`, `test/database_regression_test.dart`

**Interfaces:**
- Produces: `TransactionsTableData.smsRef` (`String?`), `TransactionsTableData.needsReview` (`bool`); `TransactionsTableCompanion.insert(..., smsRef: Value<String?>, needsReview: Value<bool>)`; `copyWith(needsReview: bool?)`; generated index getter `AppDatabase.transactionsSmsRef`.

- [ ] **Step 1: Write the failing migration test**

In `test/migration_test.dart`, add this helper above `void main()`:

```dart
/// Rebuilds transactions_table with its exact v7 definition (no sms_ref,
/// needs_review or unique index) so the file matches a pre-v8 database.
Future<void> _stripV8(AppDatabase db) async {
  await db.customStatement('DROP TABLE transactions_table');
  await db.customStatement(
    'CREATE TABLE transactions_table ('
    'id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
    'type TEXT NOT NULL, amount REAL NOT NULL, category_id INTEGER, '
    'savings_goal_id INTEGER, source TEXT, note TEXT, '
    'date INTEGER NOT NULL, '
    "created_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)))",
  );
}
```

In **both** existing tests, call `await _stripV8(db);` on the line right after `await db.customSelect('SELECT 1').get();` (otherwise the v8 `addColumn` fails with "duplicate column"). Change both `user_version` expectations from `7` to `8` (lines ~68 and ~141).

Add `import 'package:sqlite3/sqlite3.dart' show SqliteException;` to the imports, then append this test inside `main()`:

```dart
  test('v7 -> v8 keeps every existing transaction unchanged', () async {
    final directory = await Directory.systemTemp.createTemp(
      'spendsplit_migration_v8',
    );
    final file = File('${directory.path}/legacy_v7.sqlite');
    var db = AppDatabase(executor: NativeDatabase(file));
    try {
      await db.customSelect('SELECT 1').get();
      await _stripV8(db);
      await db.customStatement(
        'INSERT INTO transactions_table '
        '(id, type, amount, category_id, savings_goal_id, source, note, date, created_at) VALUES '
        "(1, 'expense', 70.5, 3, NULL, NULL, 'Lunch', 1758450000, 1758450001), "
        "(2, 'income', 14500, NULL, NULL, 'salary', NULL, 1758460000, 1758460001), "
        "(3, 'savings_deposit', 1000, NULL, 1, NULL, 'Trip', 1758470000, 1758470001)",
      );
      await db.customStatement('PRAGMA user_version = 7');
      await db.close();

      db = AppDatabase(executor: NativeDatabase(file));
      final rows = await (db.select(
        db.transactionsTable,
      )..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
      int secs(DateTime d) => d.millisecondsSinceEpoch ~/ 1000;
      expect(
        rows
            .map(
              (r) => (
                r.id,
                r.type,
                r.amount,
                r.categoryId,
                r.savingsGoalId,
                r.source,
                r.note,
                secs(r.date),
                secs(r.createdAt),
              ),
            )
            .toList(),
        [
          (1, 'expense', 70.5, 3, null, null, 'Lunch', 1758450000, 1758450001),
          (2, 'income', 14500.0, null, null, 'salary', null, 1758460000, 1758460001),
          (3, 'savings_deposit', 1000.0, null, 1, null, 'Trip', 1758470000, 1758470001),
        ],
      );
      expect(rows.every((r) => r.smsRef == null && !r.needsReview), isTrue);

      // Any number of NULL refs coexist; a repeated non-null ref is rejected.
      Future<int> insertRef(String? ref) => db
          .into(db.transactionsTable)
          .insert(
            TransactionsTableCompanion.insert(
              type: 'expense',
              amount: 1,
              date: DateTime(2026),
              smsRef: Value(ref),
            ),
          );
      await insertRef(null);
      await insertRef('1|a');
      await expectLater(insertRef('1|a'), throwsA(isA<SqliteException>()));

      expect(
        (await db.customSelect('PRAGMA user_version').getSingle()).read<int>(
          'user_version',
        ),
        8,
      );
    } finally {
      await db.close();
      await directory.delete(recursive: true);
    }
  });
```

- [ ] **Step 2: Write the failing old-backup test**

Append inside `main()` of `test/database_regression_test.dart`:

```dart
  test('restores a pre-v8 backup that has no sms fields', () async {
    final service = SnapshotService(db);
    final tables = await service.exportTables();
    final date = DateTime(2026, 9, 1).millisecondsSinceEpoch;
    tables['transactions'] = [
      {
        'id': 1,
        'type': 'expense',
        'amount': 70.0,
        'categoryId': null,
        'savingsGoalId': null,
        'source': null,
        'note': 'old',
        'date': date,
        'createdAt': date,
      },
    ];
    await service.importTables(tables);
    final row = (await db.select(db.transactionsTable).get()).single;
    expect(row.note, 'old');
    expect(row.smsRef, isNull);
    expect(row.needsReview, isFalse);
  });
```

- [ ] **Step 3: Run tests to verify they fail**

Run: `flutter test test/migration_test.dart test/database_regression_test.dart`
Expected: compile errors — `smsRef` / `needsReview` not defined.

- [ ] **Step 4: Add the columns and index**

`lib/data/database/tables/transactions_table.dart` — annotate the class and add two columns at the end:

```dart
import 'package:drift/drift.dart';

@TableIndex(name: 'transactions_sms_ref', columns: {#smsRef}, unique: true)
class TransactionsTable extends Table {
  // ... existing columns unchanged ...

  /// `<provider receive millis>|<full SMS body>` for SMS-imported rows, null
  /// for anything entered by hand. The unique index blocks double imports.
  TextColumn get smsRef => text().nullable()();

  BoolColumn get needsReview => boolean().withDefault(const Constant(false))();
}
```

`lib/data/database/app_database.dart` — set `int get schemaVersion => 8;` and append after the `if (from < 7) { ... }` block:

```dart
      if (from < 8) {
        // Additive only: existing rows get sms_ref NULL, needs_review false.
        await m.addColumn(transactionsTable, transactionsTable.smsRef);
        await m.addColumn(transactionsTable, transactionsTable.needsReview);
        await m.createIndex(transactionsSmsRef);
      }
```

- [ ] **Step 5: Regenerate and confirm the index getter name**

Run: `dart run build_runner build --delete-conflicting-outputs`
Run: `rg -n "Index transactionsSmsRef" lib/data/database/app_database.g.dart`
Expected: one match. If the getter is named differently, use that name in the `from < 8` block.

- [ ] **Step 6: Make old backups restore**

In `lib/data/repositories/snapshot_service.dart`, replace the `TransactionsTableData.fromJson(j),` line inside the `rows('transactions')` loop with:

```dart
              // Pre-v8 backups lack these keys; Drift's fromJson<bool> throws
              // on a missing non-null field before the DB default applies.
              TransactionsTableData.fromJson({
                'smsRef': null,
                'needsReview': false,
                ...j,
              }),
```

- [ ] **Step 7: Run tests to verify they pass**

Run: `flutter test test/migration_test.dart test/database_regression_test.dart`
Expected: all PASS.

- [ ] **Step 8: Fix direct data-class constructors**

`needsReview` is now a required parameter of `TransactionsTableData(...)`. Add `needsReview: false,` to each existing direct call (HEAD versions of the files):
- `test/finance_regression_test.dart` — three calls (lines ~7, ~40, ~69)
- `test/widget_test.dart` — two calls (lines ~88, ~95)

Run: `rg -n "TransactionsTableData\(" test lib -g '!*.g.dart'` and confirm every hit passes `needsReview`.

- [ ] **Step 9: Run the whole suite**

Run: `flutter test`
Expected: all PASS.

- [ ] **Step 10: Commit**

```bash
git add lib/data/database/tables/transactions_table.dart lib/data/database/app_database.dart lib/data/database/app_database.g.dart lib/data/database/daos/ lib/data/repositories/snapshot_service.dart test/migration_test.dart test/database_regression_test.dart test/finance_regression_test.dart test/widget_test.dart
git commit -m "feat(db): schema v8 — sms_ref unique index and needs_review

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

### Task 2: Trust Bank SMS parser

**Files:**
- Create: `lib/features/sms_import/sms_parser.dart`
- Test: `test/sms_parser_test.dart`

**Interfaces:**
- Produces: `class ParsedSms { String label; double amount; bool isCredit; DateTime dateTime; double balance; }`, `ParsedSms? parseTrustBankSms(String body)`.

- [ ] **Step 1: Write the failing tests**

`test/sms_parser_test.dart`:

```dart
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
      sms('TRUST MONEY Txn', 'TK 223.00 DEBIT', '21/09/2026 04:03 PM', '480648.45'),
      ('TRUST MONEY Txn', 223.0, false, DateTime(2026, 9, 21, 16, 3), 480648.45),
    ),
    (
      sms('TRUST MONEY Txn', 'TK 1000.00 DEBIT', '13/09/2026 09:19 PM', '490681.55'),
      ('TRUST MONEY Txn', 1000.0, false, DateTime(2026, 9, 13, 21, 19), 490681.55),
    ),
    (
      sms('TRUST MONEY Txn', 'TK 14500.00 CREDIT', '05/09/2026 08:40 PM', '498503.55'),
      ('TRUST MONEY Txn', 14500.0, true, DateTime(2026, 9, 5, 20, 40), 498503.55),
    ),
    (
      sms('BRANCH TRANSFER Txn', 'TK 77000.00 CREDIT', '31/08/2026 12:41 PM', '484003.55'),
      ('BRANCH TRANSFER Txn', 77000.0, true, DateTime(2026, 8, 31, 12, 41), 484003.55),
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
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/sms_parser_test.dart`
Expected: FAIL — `sms_parser.dart` not found.

- [ ] **Step 3: Implement the parser**

`lib/features/sms_import/sms_parser.dart`:

```dart
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
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/sms_parser_test.dart`
Expected: all PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/sms_import/sms_parser.dart test/sms_parser_test.dart
git commit -m "feat(sms): Trust Bank SMS parser

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

### Task 3: Insert-only importer

**Files:**
- Create: `lib/features/sms_import/sms_importer.dart`
- Test: `test/sms_import_test.dart`

**Interfaces:**
- Consumes: `parseTrustBankSms`, `ParsedSms` (Task 2); `smsRef` / `needsReview` companion fields (Task 1).
- Produces:
  - `class InboxSms { const InboxSms({required String body, required int receivedMillis}); }`
  - `class SmsImportResult { int inserted; int? newestReceivedMillis; ParsedSms? latest; }`
  - `Future<SmsImportResult> importSmsMessages(AppDatabase db, List<InboxSms> messages)`

- [ ] **Step 1: Write the failing tests**

`test/sms_import_test.dart`:

```dart
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
      (credit.type, credit.amount, credit.categoryId, credit.source, credit.note),
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
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/sms_import_test.dart`
Expected: FAIL — `sms_importer.dart` not found.

- [ ] **Step 3: Implement the importer**

`lib/features/sms_import/sms_importer.dart`:

```dart
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
}

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
              source: Value(parsed.isCredit ? IncomeSource.other.dbValue : null),
              note: Value(parsed.label),
              date: parsed.dateTime,
              smsRef: Value('${sms.receivedMillis}|${sms.body}'),
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
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/sms_import_test.dart`
Expected: all PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/sms_import/sms_importer.dart test/sms_import_test.dart
git commit -m "feat(sms): insert-only SMS importer with sms_ref dedupe

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

### Task 4: SMS settings state (watermark, bank balance, restore gating)

**Files:**
- Modify: `lib/data/models/app_settings.dart`
- Modify: `lib/data/repositories/settings_repository.dart`
- Modify: `lib/providers/providers.dart` (`SettingsController`)
- Test: `test/sms_settings_test.dart`

**Interfaces:**
- Produces on `AppSettings`: `int? smsImportSince`, `double? bankBalance`, `DateTime? bankBalanceAt`, `bool get smsImportEnabled`; `copyWith(smsImportSince: int? Function()?, bankBalance: double? Function()?, bankBalanceAt: DateTime? Function()?)`.
- Produces on `SettingsController`:
  - `Future<void> enableSmsImport(int nowMillis)`
  - `Future<void> disableSmsImport()`
  - `Future<void> recordSmsImport({required int newestReceivedMillis, double? balance, DateTime? balanceAt})`
  - `Future<void> restoreSmsImport({required int? since, required bool readGranted})`

- [ ] **Step 1: Write the failing tests**

`test/sms_settings_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendsplit/providers/providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<(ProviderContainer, SharedPreferences)> setup([
    Map<String, Object> initial = const {},
  ]) async {
    SharedPreferences.setMockInitialValues(initial);
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    return (container, prefs);
  }

  test('enable and disable persist the watermark', () async {
    final (c, prefs) = await setup();
    final ctrl = c.read(appSettingsProvider.notifier);
    expect(c.read(appSettingsProvider).smsImportEnabled, isFalse);

    await ctrl.enableSmsImport(5000);
    expect(prefs.getInt('sms_import_since'), 5000);
    expect(c.read(appSettingsProvider).smsImportSince, 5000);

    await ctrl.disableSmsImport();
    expect(prefs.containsKey('sms_import_since'), isFalse);
    expect(c.read(appSettingsProvider).smsImportEnabled, isFalse);
  });

  test('loads persisted SMS state', () async {
    final (c, _) = await setup({
      'sms_import_since': 7000,
      'bank_balance': 480578.45,
      'bank_balance_at': DateTime(2026, 9, 21, 17, 28).toIso8601String(),
    });
    final s = c.read(appSettingsProvider);
    expect(s.smsImportSince, 7000);
    expect(s.bankBalance, 480578.45);
    expect(s.bankBalanceAt, DateTime(2026, 9, 21, 17, 28));
  });

  test('recordSmsImport only moves the watermark forward', () async {
    final (c, prefs) = await setup({'sms_import_since': 5000});
    final ctrl = c.read(appSettingsProvider.notifier);
    await ctrl.recordSmsImport(newestReceivedMillis: 6000);
    expect(prefs.getInt('sms_import_since'), 6000);
    await ctrl.recordSmsImport(newestReceivedMillis: 5500);
    expect(prefs.getInt('sms_import_since'), 6000);
  });

  test('recordSmsImport is a no-op once import was switched off', () async {
    final (c, prefs) = await setup();
    await c
        .read(appSettingsProvider.notifier)
        .recordSmsImport(
          newestReceivedMillis: 6000,
          balance: 10,
          balanceAt: DateTime(2026, 9, 21),
        );
    expect(prefs.containsKey('sms_import_since'), isFalse);
    expect(prefs.containsKey('bank_balance'), isFalse);
  });

  test('bank balance keeps the latest transaction time', () async {
    final (c, _) = await setup({'sms_import_since': 1});
    final ctrl = c.read(appSettingsProvider.notifier);
    await ctrl.recordSmsImport(
      newestReceivedMillis: 2,
      balance: 200,
      balanceAt: DateTime(2026, 9, 21),
    );
    await ctrl.recordSmsImport(
      newestReceivedMillis: 3,
      balance: 100,
      balanceAt: DateTime(2026, 9, 20),
    );
    expect(c.read(appSettingsProvider).bankBalance, 200);
  });

  test('restore keeps the backup watermark only with READ_SMS', () async {
    final (c, prefs) = await setup({
      'sms_import_since': 9000,
      'bank_balance': 1.0,
      'bank_balance_at': '2026-09-21T00:00:00.000',
    });
    final ctrl = c.read(appSettingsProvider.notifier);

    await ctrl.restoreSmsImport(since: 4000, readGranted: true);
    expect(prefs.getInt('sms_import_since'), 4000);
    expect(prefs.containsKey('bank_balance'), isFalse);
    expect(c.read(appSettingsProvider).bankBalanceAt, isNull);

    await ctrl.restoreSmsImport(since: 4000, readGranted: false);
    expect(prefs.containsKey('sms_import_since'), isFalse);

    await ctrl.restoreSmsImport(since: null, readGranted: true);
    expect(c.read(appSettingsProvider).smsImportEnabled, isFalse);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/sms_settings_test.dart`
Expected: FAIL — `smsImportEnabled`, `enableSmsImport` etc. not defined.

- [ ] **Step 3: Extend `AppSettings`**

In `lib/data/models/app_settings.dart` add constructor params `this.smsImportSince, this.bankBalance, this.bankBalanceAt,` (after `this.recapDismissedMonth,`), these fields:

```dart
  /// SMS provider receive-time watermark (ms). Null = SMS import off.
  final int? smsImportSince;

  /// Balance from the Trust Bank SMS with the latest transaction time, and
  /// that transaction's time.
  final double? bankBalance;
  final DateTime? bankBalanceAt;

  bool get smsImportEnabled => smsImportSince != null;
```

and extend `copyWith` (function-typed so callers can set null):

```dart
    int? Function()? smsImportSince,
    double? Function()? bankBalance,
    DateTime? Function()? bankBalanceAt,
  }) {
    return AppSettings(
      // ... existing fields unchanged ...
      smsImportSince:
          smsImportSince != null ? smsImportSince() : this.smsImportSince,
      bankBalance: bankBalance != null ? bankBalance() : this.bankBalance,
      bankBalanceAt:
          bankBalanceAt != null ? bankBalanceAt() : this.bankBalanceAt,
    );
  }
```

- [ ] **Step 4: Persist it in `SettingsRepository`**

In `loadSettings()` add to the `AppSettings(...)` call:

```dart
      smsImportSince: _preferences.getInt(_smsImportSinceKey),
      bankBalance: _preferences.getDouble(_bankBalanceKey),
      bankBalanceAt: DateTime.tryParse(
        _preferences.getString(_bankBalanceAtKey) ?? '',
      ),
```

and add to the class:

```dart
  static const _smsImportSinceKey = 'sms_import_since';
  static const _bankBalanceKey = 'bank_balance';
  static const _bankBalanceAtKey = 'bank_balance_at';

  Future<void> setSmsImportSince(int? millis) async {
    if (millis == null) {
      await _preferences.remove(_smsImportSinceKey);
    } else {
      await _preferences.setInt(_smsImportSinceKey, millis);
    }
  }

  Future<void> setBankBalance(double? balance, DateTime? at) async {
    if (balance == null || at == null) {
      await _preferences.remove(_bankBalanceKey);
      await _preferences.remove(_bankBalanceAtKey);
      return;
    }
    await _preferences.setDouble(_bankBalanceKey, balance);
    await _preferences.setString(_bankBalanceAtKey, at.toIso8601String());
  }
```

- [ ] **Step 5: Add controller methods**

In `SettingsController` (`lib/providers/providers.dart`), after `setCardNumber`:

```dart
  Future<void> enableSmsImport(int nowMillis) async {
    await ref.read(settingsRepositoryProvider).setSmsImportSince(nowMillis);
    state = state.copyWith(smsImportSince: () => nowMillis);
  }

  Future<void> disableSmsImport() async {
    await ref.read(settingsRepositoryProvider).setSmsImportSince(null);
    state = state.copyWith(smsImportSince: () => null);
  }

  /// Advances the watermark and bank balance after an import. No-op when
  /// import was switched off while it ran, so it can't re-enable itself.
  Future<void> recordSmsImport({
    required int newestReceivedMillis,
    double? balance,
    DateTime? balanceAt,
  }) async {
    final since = state.smsImportSince;
    if (since == null) return;
    final repo = ref.read(settingsRepositoryProvider);
    if (newestReceivedMillis > since) {
      await repo.setSmsImportSince(newestReceivedMillis);
      state = state.copyWith(smsImportSince: () => newestReceivedMillis);
    }
    final currentAt = state.bankBalanceAt;
    if (balance != null &&
        balanceAt != null &&
        (currentAt == null || !balanceAt.isBefore(currentAt))) {
      await repo.setBankBalance(balance, balanceAt);
      state = state.copyWith(
        bankBalance: () => balance,
        bankBalanceAt: () => balanceAt,
      );
    }
  }

  /// Backup restore. Permissions aren't in a backup, so the backup's
  /// watermark is kept only when this phone already grants READ_SMS;
  /// otherwise import goes off. The bank balance is always cleared and the
  /// next import repopulates it.
  Future<void> restoreSmsImport({
    required int? since,
    required bool readGranted,
  }) async {
    final next = readGranted ? since : null;
    final repo = ref.read(settingsRepositoryProvider);
    await repo.setSmsImportSince(next);
    await repo.setBankBalance(null, null);
    state = state.copyWith(
      smsImportSince: () => next,
      bankBalance: () => null,
      bankBalanceAt: () => null,
    );
  }
```

- [ ] **Step 6: Run tests to verify they pass**

Run: `flutter test test/sms_settings_test.dart`
Expected: all PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/data/models/app_settings.dart lib/data/repositories/settings_repository.dart lib/providers/providers.dart test/sms_settings_test.dart
git commit -m "feat(sms): watermark, bank balance and restore gating in settings

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

### Task 5: Native SMS bridge + Dart gateway

**Files:**
- Modify: `android/app/src/main/AndroidManifest.xml`
- Create: `android/app/src/main/kotlin/com/example/spendsplit/SmsBridge.kt`
- Modify: `android/app/src/main/kotlin/com/example/spendsplit/MainActivity.kt`
- Create: `lib/features/sms_import/sms_gateway.dart`
- Create: `lib/features/sms_import/providers/sms_providers.dart`
- Create: `test/support/fake_sms_gateway.dart`

**Interfaces:**
- Consumes: `InboxSms` (Task 3).
- Produces:
  - Channel `spendsplit/sms`: `hasPermission` → `{read: bool, receive: bool}`; `requestPermission` → same; `readInbox({sinceMillis})` → `List<{body: String, date: int}>` (strictly newer, oldest first).
  - Kotlin: `SmsBridge.CHANNEL`, `SmsBridge.SENDER`, `SmsBridge.REQUESTED_PERMISSIONS`, `SmsBridge.handle(context, call, result)`, `SmsBridge.permissions(context)`; `MainActivity.runningChannel: MethodChannel?`.
  - Dart: `class SmsPermissions { bool read; bool receive; static const none; }`, `class SmsGateway { static const channel; hasPermission(); requestPermission(); readInbox({required int sinceMillis}); backgroundDone(); }`, `smsGatewayProvider`, `smsPermissionsProvider` (autoDispose `FutureProvider<SmsPermissions>`), test double `FakeSmsGateway`.

- [ ] **Step 1: Declare READ_SMS**

In `AndroidManifest.xml`, after the `USE_FINGERPRINT` line:

```xml
    <uses-permission android:name="android.permission.READ_SMS" />
```

- [ ] **Step 2: Create `SmsBridge.kt`**

```kotlin
package com.example.spendsplit

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.provider.Telephony
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/** Native side of the `spendsplit/sms` channel: permissions and inbox reads. */
object SmsBridge {
    const val CHANNEL = "spendsplit/sms"
    const val SENDER = "TrustBank"
    val REQUESTED_PERMISSIONS = arrayOf(Manifest.permission.READ_SMS)

    fun handle(context: Context, call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "hasPermission" -> result.success(permissions(context))
            "readInbox" -> {
                val since = call.argument<Number>("sinceMillis")?.toLong()
                if (since == null) {
                    result.error("bad_args", "sinceMillis is required", null)
                    return
                }
                try {
                    result.success(readInbox(context, since))
                } catch (e: Exception) {
                    result.error("read_failed", e.message, null)
                }
            }
            else -> result.notImplemented()
        }
    }

    fun permissions(context: Context): Map<String, Boolean> = mapOf(
        "read" to granted(context, Manifest.permission.READ_SMS),
        "receive" to granted(context, Manifest.permission.RECEIVE_SMS),
    )

    private fun granted(context: Context, permission: String) =
        ContextCompat.checkSelfPermission(context, permission) ==
            PackageManager.PERMISSION_GRANTED

    /** Trust Bank inbox rows received strictly after [sinceMillis], oldest first. */
    private fun readInbox(context: Context, sinceMillis: Long): List<Map<String, Any>> {
        val rows = mutableListOf<Map<String, Any>>()
        context.contentResolver.query(
            Telephony.Sms.Inbox.CONTENT_URI,
            arrayOf(Telephony.Sms.BODY, Telephony.Sms.DATE),
            "${Telephony.Sms.ADDRESS} = ? COLLATE NOCASE AND ${Telephony.Sms.DATE} > ?",
            arrayOf(SENDER, sinceMillis.toString()),
            "${Telephony.Sms.DATE} ASC",
        )?.use { cursor ->
            while (cursor.moveToNext()) {
                rows.add(mapOf("body" to (cursor.getString(0) ?: ""), "date" to cursor.getLong(1)))
            }
        }
        return rows
    }
}
```

- [ ] **Step 3: Register the channel in `MainActivity.kt`**

Replace the file with:

```kotlin
package com.example.spendsplit

import androidx.core.app.ActivityCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private var pendingPermissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SmsBridge.CHANNEL)
        channel.setMethodCallHandler { call, result ->
            if (call.method == "requestPermission") {
                requestSmsPermission(result)
            } else {
                SmsBridge.handle(applicationContext, call, result)
            }
        }
        runningChannel = channel
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        runningChannel = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    private fun requestSmsPermission(result: MethodChannel.Result) {
        if (pendingPermissionResult != null) {
            result.error("busy", "An SMS permission request is already showing", null)
            return
        }
        pendingPermissionResult = result
        ActivityCompat.requestPermissions(this, SmsBridge.REQUESTED_PERMISSIONS, SMS_PERMISSION_REQUEST)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != SMS_PERMISSION_REQUEST) return
        pendingPermissionResult?.success(SmsBridge.permissions(this))
        pendingPermissionResult = null
    }

    companion object {
        private const val SMS_PERMISSION_REQUEST = 4721

        /** The running engine's SMS channel; SmsReceiver uses it when non-null. */
        @Volatile
        var runningChannel: MethodChannel? = null
    }
}
```

If the compiler rejects the `onRequestPermissionsResult` signature, change `Array<String>` to `Array<out String>`.

- [ ] **Step 4: Create the Dart gateway**

`lib/features/sms_import/sms_gateway.dart`:

```dart
import 'dart:io';

import 'package:flutter/services.dart';

import 'sms_importer.dart';

class SmsPermissions {
  const SmsPermissions({required this.read, required this.receive});

  factory SmsPermissions.fromMap(Map<Object?, Object?>? map) =>
      SmsPermissions(read: map?['read'] == true, receive: map?['receive'] == true);

  static const none = SmsPermissions(read: false, receive: false);

  final bool read;
  final bool receive;
}

/// Dart side of the `spendsplit/sms` channel (see SmsBridge.kt). Android
/// only; everywhere else it reports no permission and an empty inbox.
class SmsGateway {
  const SmsGateway();

  static const channel = MethodChannel('spendsplit/sms');

  Future<SmsPermissions> hasPermission() => _permissions('hasPermission');

  Future<SmsPermissions> requestPermission() =>
      _permissions('requestPermission');

  Future<SmsPermissions> _permissions(String method) async {
    if (!Platform.isAndroid) return SmsPermissions.none;
    return SmsPermissions.fromMap(
      await channel.invokeMapMethod<Object?, Object?>(method),
    );
  }

  /// Trust Bank SMS received strictly after [sinceMillis], oldest first.
  Future<List<InboxSms>> readInbox({required int sinceMillis}) async {
    if (!Platform.isAndroid) return const [];
    final rows =
        await channel.invokeListMethod<Map<Object?, Object?>>('readInbox', {
          'sinceMillis': sinceMillis,
        }) ??
        const [];
    return [
      for (final row in rows)
        InboxSms(
          body: row['body']! as String,
          receivedMillis: row['date']! as int,
        ),
    ];
  }

  /// Headless engine only: tells SmsReceiver the background run finished.
  Future<void> backgroundDone() => channel.invokeMethod<void>('backgroundDone');
}
```

- [ ] **Step 5: Create the providers file**

`lib/features/sms_import/providers/sms_providers.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../sms_gateway.dart';

final smsGatewayProvider = Provider<SmsGateway>((ref) => const SmsGateway());

final smsPermissionsProvider = FutureProvider.autoDispose<SmsPermissions>(
  (ref) => ref.watch(smsGatewayProvider).hasPermission(),
);
```

- [ ] **Step 6: Create the shared test double**

`test/support/fake_sms_gateway.dart`:

```dart
import 'package:spendsplit/features/sms_import/sms_gateway.dart';
import 'package:spendsplit/features/sms_import/sms_importer.dart';

class FakeSmsGateway extends SmsGateway {
  FakeSmsGateway({
    this.permissions = const SmsPermissions(read: true, receive: true),
  });

  SmsPermissions permissions;

  /// What [requestPermission] grants.
  SmsPermissions grantOnRequest = const SmsPermissions(
    read: true,
    receive: true,
  );

  final inbox = <InboxSms>[];
  final sinceCalls = <int>[];
  Object? failWith;

  /// Called with the 1-based read count before each read.
  void Function(int readCount)? onRead;

  @override
  Future<SmsPermissions> hasPermission() async => permissions;

  @override
  Future<SmsPermissions> requestPermission() async =>
      permissions = grantOnRequest;

  @override
  Future<List<InboxSms>> readInbox({required int sinceMillis}) async {
    sinceCalls.add(sinceMillis);
    onRead?.call(sinceCalls.length);
    if (failWith != null) throw failWith!;
    // Mirrors SmsBridge.kt: strictly newer than the watermark, oldest first.
    return inbox.where((m) => m.receivedMillis > sinceMillis).toList()
      ..sort((a, b) => a.receivedMillis.compareTo(b.receivedMillis));
  }
}
```

- [ ] **Step 7: Verify it compiles**

Run: `flutter analyze`
Expected: no new issues.
Run: `flutter build apk --debug`
Expected: build succeeds.

- [ ] **Step 8: Check the sender address on the real phone (Review Focus 5)**

With the phone connected over USB debugging:

Run: `adb shell content query --uri content://sms/inbox --projection address --where "address LIKE '%rust%'"`
Expected: rows showing `address=TrustBank`. If the address is different (e.g. a short code), set `SmsBridge.SENDER` to that value and re-run Step 7. Record the observed value in the commit message.

- [ ] **Step 9: Commit**

```bash
git add android/app/src/main/AndroidManifest.xml android/app/src/main/kotlin/com/example/spendsplit/SmsBridge.kt android/app/src/main/kotlin/com/example/spendsplit/MainActivity.kt lib/features/sms_import/sms_gateway.dart lib/features/sms_import/providers/sms_providers.dart test/support/fake_sms_gateway.dart
git commit -m "feat(sms): native SMS channel (READ_SMS, inbox query) and Dart gateway

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

### Task 6: Import runner

**Files:**
- Create: `lib/features/sms_import/sms_import_runner.dart`
- Test: `test/sms_import_runner_test.dart`

**Interfaces:**
- Consumes: `smsGatewayProvider` (Task 5), `importSmsMessages` (Task 3), `SettingsController.recordSmsImport` + `AppSettings.smsImportSince` (Task 4), `appDatabaseProvider`.
- Produces: `class SmsImportRunner { SmsImportRunner(Ref ref, {Duration retryDelay}); Future<int> run({bool waitForNew = false}); }` (never throws, returns rows inserted), `smsImportRunnerProvider`.

- [ ] **Step 1: Write the failing tests**

`test/sms_import_runner_test.dart`:

```dart
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendsplit/data/database/app_database.dart';
import 'package:spendsplit/features/sms_import/providers/sms_providers.dart';
import 'package:spendsplit/features/sms_import/sms_gateway.dart';
import 'package:spendsplit/features/sms_import/sms_import_runner.dart';
import 'package:spendsplit/features/sms_import/sms_importer.dart';
import 'package:spendsplit/providers/providers.dart';

import 'support/fake_sms_gateway.dart';

String debit(int amount) =>
    'POS Txn\nTK $amount.00 DEBIT\nAC No 031***492\n21/09/2026 05:28 PM\n'
    'Balance TK 1000.00';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<(SmsImportRunner, AppDatabase, FakeSmsGateway, SharedPreferences)>
  setup({int? since = 5000}) async {
    SharedPreferences.setMockInitialValues({
      if (since != null) 'sms_import_since': since,
    });
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase(executor: NativeDatabase.memory());
    final gateway = FakeSmsGateway();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appDatabaseProvider.overrideWithValue(db),
        smsGatewayProvider.overrideWithValue(gateway),
        smsImportRunnerProvider.overrideWith(
          (ref) => SmsImportRunner(ref, retryDelay: Duration.zero),
        ),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await db.close();
    });
    return (container.read(smsImportRunnerProvider), db, gateway, prefs);
  }

  test('does nothing while switched off', () async {
    final (runner, _, gateway, _) = await setup(since: null);
    gateway.inbox.add(InboxSms(body: debit(70), receivedMillis: 6000));
    expect(await runner.run(), 0);
    expect(gateway.sinceCalls, isEmpty);
  });

  test('does nothing without READ_SMS', () async {
    final (runner, _, gateway, _) = await setup();
    gateway.permissions = SmsPermissions.none;
    gateway.inbox.add(InboxSms(body: debit(70), receivedMillis: 6000));
    expect(await runner.run(), 0);
    expect(gateway.sinceCalls, isEmpty);
  });

  test('imports only SMS newer than the watermark, then advances it', () async {
    final (runner, db, gateway, prefs) = await setup();
    gateway.inbox.addAll([
      InboxSms(body: debit(1), receivedMillis: 4000), // before enabling
      InboxSms(body: debit(70), receivedMillis: 6000),
    ]);
    expect(await runner.run(), 1);
    expect((await db.select(db.transactionsTable).get()).single.amount, 70);
    expect(prefs.getInt('sms_import_since'), 6000);
    expect(prefs.getDouble('bank_balance'), 1000);
  });

  test('a deleted imported entry is not imported again', () async {
    final (runner, db, gateway, _) = await setup();
    gateway.inbox.add(InboxSms(body: debit(70), receivedMillis: 6000));
    await runner.run();
    await db.delete(db.transactionsTable).go();
    expect(await runner.run(), 0);
    expect(await db.select(db.transactionsTable).get(), isEmpty);
    expect(gateway.sinceCalls.last, 6000);
  });

  test('a failed read leaves the watermark alone', () async {
    final (runner, _, gateway, prefs) = await setup();
    gateway.failWith = Exception('provider unavailable');
    expect(await runner.run(), 0);
    expect(prefs.getInt('sms_import_since'), 5000);
  });

  test('waitForNew retries until the SMS reaches the inbox', () async {
    final (runner, _, gateway, _) = await setup();
    gateway.onRead = (n) {
      if (n == 3) {
        gateway.inbox.add(InboxSms(body: debit(70), receivedMillis: 6000));
      }
    };
    expect(await runner.run(waitForNew: true), 1);
    expect(gateway.sinceCalls, hasLength(3));
  });

  test('without waitForNew an empty inbox is read once', () async {
    final (runner, _, gateway, _) = await setup();
    expect(await runner.run(), 0);
    expect(gateway.sinceCalls, hasLength(1));
  });

  test('overlapping runs are serialized', () async {
    final (runner, _, gateway, _) = await setup();
    gateway.inbox.add(InboxSms(body: debit(70), receivedMillis: 6000));
    expect(await Future.wait([runner.run(), runner.run()]), [1, 0]);
    expect(gateway.sinceCalls, [5000, 6000]);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/sms_import_runner_test.dart`
Expected: FAIL — `sms_import_runner.dart` not found.

- [ ] **Step 3: Implement the runner**

`lib/features/sms_import/sms_import_runner.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';
import 'providers/sms_providers.dart';
import 'sms_importer.dart';

final smsImportRunnerProvider = Provider<SmsImportRunner>(
  (ref) => SmsImportRunner(ref),
);

/// Imports Trust Bank SMS newer than the watermark, one run at a time.
/// Never throws; returns the number of transactions inserted.
class SmsImportRunner {
  SmsImportRunner(this._ref, {this.retryDelay = const Duration(seconds: 1)});

  final Ref _ref;
  final Duration retryDelay;
  static const _retries = 4;
  Future<int>? _inFlight;

  /// [waitForNew]: an SMS just arrived. The default SMS app may not have
  /// written it to the inbox yet, so re-read for a few seconds.
  Future<int> run({bool waitForNew = false}) async {
    while (_inFlight != null) {
      await _inFlight;
    }
    final current = _inFlight = _runOnce(waitForNew);
    try {
      return await current;
    } finally {
      if (identical(_inFlight, current)) _inFlight = null;
    }
  }

  Future<int> _runOnce(bool waitForNew) async {
    try {
      final since = _ref.read(appSettingsProvider).smsImportSince;
      if (since == null) return 0;
      final gateway = _ref.read(smsGatewayProvider);
      if (!(await gateway.hasPermission()).read) return 0;

      var messages = await gateway.readInbox(sinceMillis: since);
      for (var i = 0; waitForNew && messages.isEmpty && i < _retries; i++) {
        await Future<void>.delayed(retryDelay);
        messages = await gateway.readInbox(sinceMillis: since);
      }
      if (messages.isEmpty) return 0;

      final result = await importSmsMessages(
        _ref.read(appDatabaseProvider),
        messages,
      );
      // Only after a successful import, so a failure rereads next time.
      await _ref
          .read(appSettingsProvider.notifier)
          .recordSmsImport(
            newestReceivedMillis: result.newestReceivedMillis!,
            balance: result.latest?.balance,
            balanceAt: result.latest?.dateTime,
          );
      return result.inserted;
    } catch (error, stack) {
      debugPrint('SMS import failed: $error\n$stack');
      return 0;
    }
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/sms_import_runner_test.dart`
Expected: all PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/sms_import/sms_import_runner.dart test/sms_import_runner_test.dart
git commit -m "feat(sms): serialized import runner with watermark and retry

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

### Task 7: Wire into the app — triggers, Settings switch, backup

**Files:**
- Modify: `lib/app.dart`
- Modify: `lib/features/settings/screens/settings_screen.dart`
- Modify: `lib/features/export/screens/export_data_screen.dart` (~line 599 export, ~line 687 restore)
- Modify: `lib/core/icons/lucide_icons.dart`
- Test: `test/sms_settings_screen_test.dart`

**Interfaces:**
- Consumes: `smsImportRunnerProvider` (Task 6), `SmsGateway.channel`, `smsGatewayProvider`, `smsPermissionsProvider` (Task 5), `enableSmsImport` / `disableSmsImport` / `restoreSmsImport` (Task 4).
- Produces: `rootScaffoldMessengerKey` (top-level in `app.dart`); the Dart handler for channel method `import` (args `{waitForNew: bool}`, returns `int`), used by Task 11's receiver.

- [ ] **Step 1: Write the failing widget tests**

`test/sms_settings_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendsplit/features/settings/screens/settings_screen.dart';
import 'package:spendsplit/features/sms_import/providers/sms_providers.dart';
import 'package:spendsplit/features/sms_import/sms_gateway.dart';
import 'package:spendsplit/providers/providers.dart';

import 'support/fake_sms_gateway.dart';

void main() {
  Future<SharedPreferences> pumpSettings(
    WidgetTester tester,
    FakeSmsGateway gateway, [
    Map<String, Object> initial = const {},
  ]) async {
    SharedPreferences.setMockInitialValues(initial);
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          smsGatewayProvider.overrideWithValue(gateway),
        ],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    return prefs;
  }

  Finder smsSwitch() => find.descendant(
    of: find
        .ancestor(
          of: find.text('Import Trust Bank SMS'),
          matching: find.byType(Row),
        )
        .first,
    matching: find.byType(Switch),
  );

  testWidgets('switching on asks for permission and starts from now', (
    tester,
  ) async {
    final gateway = FakeSmsGateway(permissions: SmsPermissions.none);
    final prefs = await pumpSettings(tester, gateway);
    final before = DateTime.now().millisecondsSinceEpoch;

    await tester.tap(smsSwitch());
    await tester.pumpAndSettle();

    expect(prefs.getInt('sms_import_since'), greaterThanOrEqualTo(before));
    expect(
      find.text('New bank SMS are imported when you open the app'),
      findsOneWidget,
    );
  });

  testWidgets('denied permission keeps the switch off', (tester) async {
    final gateway = FakeSmsGateway(permissions: SmsPermissions.none)
      ..grantOnRequest = SmsPermissions.none;
    final prefs = await pumpSettings(tester, gateway);

    await tester.tap(smsSwitch());
    await tester.pumpAndSettle();

    expect(prefs.containsKey('sms_import_since'), isFalse);
    expect(find.textContaining('Allow SMS access'), findsOneWidget);
  });

  testWidgets('switching off clears the watermark', (tester) async {
    final prefs = await pumpSettings(tester, FakeSmsGateway(), {
      'sms_import_since': 5000,
    });

    await tester.tap(smsSwitch());
    await tester.pumpAndSettle();

    expect(prefs.containsKey('sms_import_since'), isFalse);
  });

  testWidgets('revoked READ_SMS shows a tap-to-allow subtitle', (tester) async {
    await pumpSettings(
      tester,
      FakeSmsGateway(permissions: SmsPermissions.none),
      {'sms_import_since': 5000},
    );
    expect(find.text('SMS permission is off — tap to allow'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/sms_settings_screen_test.dart`
Expected: FAIL — text 'Import Trust Bank SMS' not found.

- [ ] **Step 3: Add the icon**

In `lib/core/icons/lucide_icons.dart`, add in alphabetical position:

```dart
  static const messageSquare = IconData(
    0xf3ce,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons',
  );
```

- [ ] **Step 4: Add the Settings switch**

In `settings_screen.dart`, add imports:

```dart
import '../../sms_import/providers/sms_providers.dart';
import '../../sms_import/sms_gateway.dart';
```

Insert a new card directly after the SECURITY `GlassCard(...)` (before the `FINANCIAL DEFAULTS` card's leading `SizedBox`):

```dart
            const SizedBox(height: AppSpacing.section),
            GlassCard(
              glowColor: AppColors.amber,
              radius: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BANK SMS',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const _SmsImportRow(),
                ],
              ),
            ),
```

Add an optional tap target to `_SwitchRow`: a field `final VoidCallback? onTap;`, constructor param `this.onTap,`, and wrap the returned `Container` as:

```dart
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        // ... existing Container unchanged ...
      ),
    );
```

Add the row widget at the end of the file:

```dart
class _SmsImportRow extends ConsumerWidget {
  const _SmsImportRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(
      appSettingsProvider.select((s) => s.smsImportEnabled),
    );
    final perms = ref.watch(smsPermissionsProvider).valueOrNull;
    final missingRead = enabled && perms != null && !perms.read;

    return _SwitchRow(
      icon: LucideIcons.messageSquare,
      title: 'Import Trust Bank SMS',
      subtitle: !enabled
          ? 'Log card debits and credits from bank SMS automatically'
          : missingRead
          ? 'SMS permission is off — tap to allow'
          : 'New bank SMS are imported when you open the app',
      value: enabled,
      onTap: missingRead ? () => _request(context, ref) : null,
      onChanged: (value) async {
        final controller = ref.read(appSettingsProvider.notifier);
        if (!value) {
          await controller.disableSmsImport();
          return;
        }
        if (await _request(context, ref)) {
          // Start from now: SMS already on the phone were entered by hand.
          await controller.enableSmsImport(
            DateTime.now().millisecondsSinceEpoch,
          );
        }
      },
    );
  }

  Future<bool> _request(BuildContext context, WidgetRef ref) async {
    final perms = await ref.read(smsGatewayProvider).requestPermission();
    ref.invalidate(smsPermissionsProvider);
    if (!perms.read && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Allow SMS access to import bank messages. If Android stopped '
            'asking, enable it in App info → Permissions.',
          ),
        ),
      );
    }
    return perms.read;
  }
}
```

- [ ] **Step 5: Run the widget tests**

Run: `flutter test test/sms_settings_screen_test.dart`
Expected: all PASS.

- [ ] **Step 6: Trigger imports from the app**

In `lib/app.dart`, add imports:

```dart
import 'features/sms_import/sms_gateway.dart';
import 'features/sms_import/sms_import_runner.dart';
```

Add a top-level key under `_shellNavigatorKey`:

```dart
final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
```

In `_SpendSplitAppState`, replace `initState`, `dispose`, `didChangeAppLifecycleState` with:

```dart
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // SmsReceiver calls this while the app's engine is alive.
    SmsGateway.channel.setMethodCallHandler((call) async {
      if (call.method != 'import') throw MissingPluginException();
      final args = call.arguments as Map<Object?, Object?>?;
      return _importSms(waitForNew: args?['waitForNew'] == true);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _importSms());
  }

  @override
  void dispose() {
    SmsGateway.channel.setMethodCallHandler(null);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _importSms();
    }
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      // Re-lock when the app is backgrounded
      final settings = ref.read(appSettingsProvider);
      if (settings.biometricEnabled) {
        ref.read(appSessionUnlockedProvider.notifier).lock();
      }
    }
  }

  Future<int> _importSms({bool waitForNew = false}) async {
    final count = await ref
        .read(smsImportRunnerProvider)
        .run(waitForNew: waitForNew);
    final locked =
        ref.read(appSettingsProvider).biometricEnabled &&
        !ref.read(appSessionUnlockedProvider);
    if (count > 0 && !locked) {
      rootScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(
            'Imported $count transaction${count == 1 ? '' : 's'} from SMS',
          ),
        ),
      );
    }
    return count;
  }
```

Add `scaffoldMessengerKey: rootScaffoldMessengerKey,` to the `MaterialApp.router(...)` call. `MissingPluginException` comes from `package:flutter/services.dart`; add that import if the analyzer asks.

- [ ] **Step 7: Carry the watermark through backups**

In `export_data_screen.dart` `_handleJsonExport`, add to the `'settings': {...}` map:

```dart
          'smsImportSince': settings.smsImportSince,
```

In `_handleJsonRestore`, directly after the closing `}` of `if (settings != null) { ... }` (before `if (!mounted) return;`), add:

```dart
      // Permissions aren't in a backup: keep its SMS watermark only when
      // this phone already allows READ_SMS, otherwise import goes off.
      final smsPermissions = await ref
          .read(smsGatewayProvider)
          .hasPermission();
      await ref
          .read(appSettingsProvider.notifier)
          .restoreSmsImport(
            since: (settings?['smsImportSince'] as num?)?.toInt(),
            readGranted: smsPermissions.read,
          );
```

and import `'../../sms_import/providers/sms_providers.dart'`.

- [ ] **Step 8: Full check**

Run: `flutter analyze && flutter test`
Expected: no issues; all PASS.

- [ ] **Step 9: Manual check on the phone**

Run: `flutter run` on the phone.
- Settings → turn on **Import Trust Bank SMS** → allow. Subtitle reads "New bank SMS are imported when you open the app".
- Make one small card payment. When the SMS arrives, switch away and back to the app. Expect the snackbar "Imported 1 transaction from SMS" and a new expense in Other with note `POS Txn` (or the matching label).
- Switch away and back again. No second snackbar, no duplicate row.

- [ ] **Step 10: Commit**

```bash
git add lib/app.dart lib/features/settings/screens/settings_screen.dart lib/features/export/screens/export_data_screen.dart lib/core/icons/lucide_icons.dart test/sms_settings_screen_test.dart
git commit -m "feat(sms): import on open/resume, Settings switch, backup watermark

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

## Phase 2 — Needs-review marker

### Task 8: Review chip, filter, dashboard card, clear on save

**Files:**
- Modify: `lib/features/sms_import/providers/sms_providers.dart`
- Modify: `lib/core/constants/enums.dart` (`TransactionQuickFilter`)
- Modify: `lib/features/transactions/widgets/filter_chips_row.dart`
- Modify: `lib/features/transactions/widgets/transaction_tile.dart`
- Modify: `lib/features/transactions/screens/transactions_screen.dart`
- Modify: `lib/features/transactions/widgets/add_transaction_sheet.dart` (~line 757, inside `existing.copyWith(`)
- Modify: `lib/app.dart` (transactions route)
- Create: `lib/features/dashboard/widgets/sms_review_card.dart`
- Modify: `lib/features/dashboard/screens/dashboard_screen.dart`
- Test: `test/sms_review_test.dart`

**Interfaces:**
- Consumes: `TransactionsTableData.needsReview` (Task 1).
- Produces: `needsReviewCountProvider` (`Provider<int>`), `TransactionQuickFilter.review`, route `/transactions?review=1`, `TransactionsScreen(initialReviewOnly: bool)`.

- [ ] **Step 1: Write the failing tests**

`test/sms_review_test.dart`:

```dart
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendsplit/core/constants/categories.dart';
import 'package:spendsplit/data/database/app_database.dart';
import 'package:spendsplit/features/sms_import/providers/sms_providers.dart';
import 'package:spendsplit/features/transactions/widgets/add_transaction_sheet.dart';
import 'package:spendsplit/providers/providers.dart';

Future<TransactionsTableData> insertSmsEntry(AppDatabase db) async {
  final other = (await db.select(db.categoriesTable).get()).firstWhere(
    (c) => c.name == DefaultCategories.other && !c.isDollarCategory,
  );
  final id = await db.transactionDao.insertTransaction(
    TransactionsTableCompanion.insert(
      type: 'expense',
      amount: 70,
      categoryId: Value(other.id),
      note: const Value('POS Txn'),
      date: DateTime(2026, 9, 21, 17, 28),
      smsRef: const Value('1|x'),
      needsReview: const Value(true),
    ),
  );
  return (await db.transactionDao.getTransactionById(id))!;
}

void main() {
  test('needsReviewCountProvider counts flagged rows', () async {
    final db = AppDatabase(executor: NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(() async {
      container.dispose();
      await db.close();
    });
    await insertSmsEntry(db);
    await db.transactionDao.insertTransaction(
      TransactionsTableCompanion.insert(
        type: 'expense',
        amount: 5,
        date: DateTime(2026, 9, 21),
      ),
    );
    await container.read(transactionsProvider.future);
    expect(container.read(needsReviewCountProvider), 1);
  });

  testWidgets('saving an SMS entry from the edit sheet clears the flag', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase(executor: NativeDatabase.memory());
    final entry = (await tester.runAsync(() => insertSmsEntry(db)))!;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showAddTransactionSheet(
                  context,
                  existingTransaction: entry,
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final finder = find.ancestor(
      of: find.text('UPDATE'),
      matching: find.byType(FilledButton),
    );
    final dynamic save = tester.widget<FilledButton>(finder).onPressed;
    await tester.runAsync(() async => await (save() as Future<void>));
    await tester.pumpAndSettle();

    final saved = await tester.runAsync(
      () => db.transactionDao.getTransactionById(entry.id),
    );
    expect(saved!.needsReview, isFalse);
    expect(saved.smsRef, '1|x');

    await tester.pumpWidget(const SizedBox.shrink());
    final closing = db.close();
    await tester.pump(const Duration(milliseconds: 1));
    await closing;
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/sms_review_test.dart`
Expected: FAIL — `needsReviewCountProvider` not defined.

- [ ] **Step 3: Add the count provider**

Append to `lib/features/sms_import/providers/sms_providers.dart` (add `import '../../../providers/providers.dart';`):

```dart
final needsReviewCountProvider = Provider<int>((ref) {
  final transactions = ref.watch(transactionsProvider).valueOrNull;
  return transactions?.where((t) => t.needsReview).length ?? 0;
});
```

- [ ] **Step 4: Clear the flag on save**

In `add_transaction_sheet.dart`, inside `existing.copyWith(` in the `_isEditing` branch, add after `date: _selectedDate,`:

```dart
              // Saving counts as reviewed, even with no changes.
              needsReview: false,
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `flutter test test/sms_review_test.dart`
Expected: all PASS.

- [ ] **Step 6: Review chip on the tile**

In `transaction_tile.dart`, pass `needsReview: transaction.needsReview,` into `_TileBody(...)`. In `_TileBody` add `required this.needsReview,` and `final bool needsReview;`. Replace the title `Text(presentation.title, ...)` with:

```dart
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            presentation.title,
                            style: theme.textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (needsReview) ...[
                          const SizedBox(width: 6),
                          const _ReviewChip(),
                        ],
                      ],
                    ),
```

Add at the bottom of the file:

```dart
class _ReviewChip extends StatelessWidget {
  const _ReviewChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.amber.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Review',
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: AppColors.amber),
      ),
    );
  }
}
```

- [ ] **Step 7: Review filter**

`enums.dart`: `enum TransactionQuickFilter { all, income, expense, savings, review }`.

`filter_chips_row.dart`: add `this.showReview = false,` to the constructor and `final bool showReview;`, then after the Savings chip:

```dart
          if (showReview) ...[
            const SizedBox(width: 10),
            AccentChip(
              label: 'Review',
              selected: selectedFilter == TransactionQuickFilter.review,
              color: AppColors.amber,
              onTap: () => onSelected(TransactionQuickFilter.review),
            ),
          ],
```

`transactions_screen.dart`:
- Constructor: add `this.initialReviewOnly = false` and `final bool initialReviewOnly;`.
- `initState`: after `_advancedFilters = ...;` add `if (widget.initialReviewOnly) _quickFilter = TransactionQuickFilter.review;`.
- `didUpdateWidget`: add `if (widget.initialReviewOnly && !oldWidget.initialReviewOnly) _quickFilter = TransactionQuickFilter.review;`.
- `FilterChipsRow(...)`: add `showReview: ref.watch(needsReviewCountProvider) > 0 || _quickFilter == TransactionQuickFilter.review,` (import `'../../sms_import/providers/sms_providers.dart'`).
- `_applyFilters` switch: add `TransactionQuickFilter.review => transaction.needsReview,`.

`app.dart` transactions route: add to `TransactionsScreen(...)`:

```dart
                initialReviewOnly: state.uri.queryParameters['review'] == '1',
```

- [ ] **Step 8: Dashboard card**

`lib/features/dashboard/widgets/sms_review_card.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spendsplit/core/icons/lucide_icons.dart';

import '../../../core/constants/enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../sms_import/providers/sms_providers.dart';

/// "N SMS entries to review" — opens Transactions filtered to them.
class SmsReviewCard extends ConsumerWidget {
  const SmsReviewCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(needsReviewCountProvider);
    return GestureDetector(
      onTap: () => context.go('${AppRoute.transactions.path}?review=1'),
      child: GlassCard(
        glowColor: AppColors.amber,
        radius: 20,
        child: Row(
          children: [
            const Icon(
              LucideIcons.messageSquare,
              color: AppColors.amber,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$count SMS ${count == 1 ? 'entry' : 'entries'} to review',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const Icon(
              LucideIcons.chevronRight,
              color: AppColors.textSecondary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
```

In `dashboard_screen.dart`, import it plus `'../../sms_import/providers/sms_providers.dart'`, add `const _SmsReviewSlot(),` directly after `const _MonthRecapSlot(),`, and add next to `_MonthRecapSlot`:

```dart
class _SmsReviewSlot extends ConsumerWidget {
  const _SmsReviewSlot();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(needsReviewCountProvider) == 0) {
      return const SizedBox.shrink();
    }
    return const Column(
      children: [
        SmsReviewCard(),
        SizedBox(height: AppSpacing.section),
      ],
    );
  }
}
```

- [ ] **Step 9: Full check**

Run: `flutter analyze && flutter test`
Expected: no issues; all PASS.

- [ ] **Step 10: Commit**

```bash
git add lib/features/sms_import/providers/sms_providers.dart lib/core/constants/enums.dart lib/features/transactions/widgets/filter_chips_row.dart lib/features/transactions/widgets/transaction_tile.dart lib/features/transactions/screens/transactions_screen.dart lib/features/transactions/widgets/add_transaction_sheet.dart lib/app.dart lib/features/dashboard/widgets/sms_review_card.dart lib/features/dashboard/screens/dashboard_screen.dart test/sms_review_test.dart
git commit -m "feat(sms): needs-review chip, filter and dashboard card

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

## Phase 3 — Bank balance reconciliation

### Task 9: Reconciliation card

**Files:**
- Create: `lib/features/sms_import/reconciliation.dart`
- Modify: `lib/features/sms_import/providers/sms_providers.dart`
- Create: `lib/features/dashboard/widgets/bank_reconcile_card.dart`
- Modify: `lib/features/dashboard/screens/dashboard_screen.dart`
- Modify: `lib/core/icons/lucide_icons.dart`
- Test: `test/reconciliation_test.dart`

**Interfaces:**
- Consumes: `AppSettings.bankBalance` / `bankBalanceAt` / `smsImportEnabled` / `initialBalance` (Task 4), `SettingsController.setInitialBalance` (existing).
- Produces: `class BankReconciliation { double bank; double app; double get diff; }`, `double appTotalAsOf(Iterable<TransactionsTableData>, {required double initialBalance, required DateTime asOf})`, `bankReconciliationProvider` (`Provider<BankReconciliation?>`).

Do **not** reuse `FinanceCalculators.balanceSummary(asOf:)`. That parameter is part of the uncommitted work in `financial_summaries.dart`.

- [ ] **Step 1: Write the failing tests**

`test/reconciliation_test.dart`:

```dart
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendsplit/data/database/app_database.dart';
import 'package:spendsplit/features/sms_import/providers/sms_providers.dart';
import 'package:spendsplit/features/sms_import/reconciliation.dart';
import 'package:spendsplit/providers/providers.dart';

TransactionsTableData txn(String type, double amount, DateTime date) =>
    TransactionsTableData(
      id: 0,
      type: type,
      amount: amount,
      date: date,
      createdAt: date,
      needsReview: false,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final at = DateTime(2026, 9, 21, 17, 28);

  test('appTotalAsOf counts income/expense up to asOf, ignores savings', () {
    final total = appTotalAsOf(
      [
        txn('income', 500, at),
        txn('expense', 70, at.subtract(const Duration(days: 1))),
        txn('expense', 999, at.add(const Duration(minutes: 1))), // after
        txn('savings_deposit', 300, at), // same bank account
      ],
      initialBalance: 1000,
      asOf: at,
    );
    expect(total, 1430);
  });

  Future<ProviderContainer> setup(Map<String, Object> prefs) async {
    SharedPreferences.setMockInitialValues(prefs);
    final p = await SharedPreferences.getInstance();
    final db = AppDatabase(executor: NativeDatabase.memory());
    final c = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(p),
        appDatabaseProvider.overrideWithValue(db),
        secureInitialBalanceProvider.overrideWithValue(1000),
      ],
    );
    addTearDown(() async {
      c.dispose();
      await db.close();
    });
    await c.read(transactionsProvider.future);
    return c;
  }

  Map<String, Object> bank(double balance) => {
    'sms_import_since': 1,
    'bank_balance': balance,
    'bank_balance_at': at.toIso8601String(),
  };

  test('reports a mismatch of at least one taka', () async {
    final c = await setup(bank(1478.45));
    final r = c.read(bankReconciliationProvider)!;
    expect((r.bank, r.app), (1478.45, 1000.0));
    expect(r.diff, closeTo(478.45, 1e-9));
  });

  test('hidden under one taka, when off, or with no bank balance', () async {
    expect((await setup(bank(1000.5))).read(bankReconciliationProvider), isNull);
    expect(
      (await setup({...bank(5000)}..remove('sms_import_since'))).read(
        bankReconciliationProvider,
      ),
      isNull,
    );
    expect(
      (await setup({'sms_import_since': 1})).read(bankReconciliationProvider),
      isNull,
    );
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/reconciliation_test.dart`
Expected: FAIL — `reconciliation.dart` not found.

- [ ] **Step 3: Implement the math**

`lib/features/sms_import/reconciliation.dart`:

```dart
import '../../core/constants/enums.dart';
import '../../data/database/app_database.dart';

class BankReconciliation {
  const BankReconciliation({required this.bank, required this.app});

  final double bank;
  final double app;

  double get diff => bank - app;
}

/// App Total Balance (initial + income − expenses) counting only
/// transactions dated at or before [asOf]. Savings moves are ignored: they
/// stay in the same bank account.
double appTotalAsOf(
  Iterable<TransactionsTableData> transactions, {
  required double initialBalance,
  required DateTime asOf,
}) {
  var total = initialBalance;
  for (final t in transactions) {
    if (t.date.isAfter(asOf)) continue;
    if (t.type == TransactionType.income.dbValue) total += t.amount;
    if (t.type == TransactionType.expense.dbValue) total -= t.amount;
  }
  return total;
}
```

Append to `sms_providers.dart` (import `'../reconciliation.dart'`):

```dart
/// Non-null when the latest bank SMS balance and the app disagree by ≥ ৳1.
final bankReconciliationProvider = Provider<BankReconciliation?>((ref) {
  final settings = ref.watch(appSettingsProvider);
  final transactions = ref.watch(transactionsProvider).valueOrNull;
  final bank = settings.bankBalance;
  final at = settings.bankBalanceAt;
  if (!settings.smsImportEnabled ||
      bank == null ||
      at == null ||
      transactions == null) {
    return null;
  }
  final result = BankReconciliation(
    bank: bank,
    app: appTotalAsOf(
      transactions,
      initialBalance: settings.initialBalance,
      asOf: at,
    ),
  );
  return result.diff.abs() >= 1 ? result : null;
});
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/reconciliation_test.dart`
Expected: all PASS.

- [ ] **Step 5: Card + icon**

Add to `lucide_icons.dart` (alphabetical):

```dart
  static const scale = IconData(
    0xf49f,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons',
  );
```

`lib/features/dashboard/widgets/bank_reconcile_card.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spendsplit/core/icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../providers/providers.dart';
import '../../sms_import/providers/sms_providers.dart';

/// Shown when the latest Trust Bank SMS balance disagrees with the app.
class BankReconcileCard extends ConsumerWidget {
  const BankReconcileCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = ref.watch(bankReconciliationProvider);
    if (r == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    String bdt(double v) => formatBdtAmount(v, fractionDigits: 0);

    return GlassCard(
      glowColor: AppColors.coral,
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.scale, color: AppColors.coral, size: 18),
              const SizedBox(width: 10),
              Text('Balance check', style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Bank ${bdt(r.bank)} · App ${bdt(r.app)} · off by ${bdt(r.diff.abs())}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Missing an entry? Add it and this clears. Otherwise, adjust the start balance.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                final settings = ref.read(appSettingsProvider);
                ref
                    .read(appSettingsProvider.notifier)
                    .setInitialBalance(settings.initialBalance + r.diff);
              },
              child: const Text('Adjust start balance'),
            ),
          ),
        ],
      ),
    );
  }
}
```

In `dashboard_screen.dart`, import it, add `const _BankReconcileSlot(),` right after `const _SmsReviewSlot(),`, and add:

```dart
class _BankReconcileSlot extends ConsumerWidget {
  const _BankReconcileSlot();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(bankReconciliationProvider) == null) {
      return const SizedBox.shrink();
    }
    return const Column(
      children: [
        BankReconcileCard(),
        SizedBox(height: AppSpacing.section),
      ],
    );
  }
}
```

- [ ] **Step 6: Full check**

Run: `flutter analyze && flutter test`
Expected: no issues; all PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/features/sms_import/reconciliation.dart lib/features/sms_import/providers/sms_providers.dart lib/features/dashboard/widgets/bank_reconcile_card.dart lib/features/dashboard/screens/dashboard_screen.dart lib/core/icons/lucide_icons.dart test/reconciliation_test.dart
git commit -m "feat(sms): bank balance reconciliation card

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

## Phase 4 — Background capture

### Task 10: Extract bootstrap and home-widget sync (no behaviour change)

**Files:**
- Create: `lib/bootstrap.dart`
- Create: `lib/features/widget/home_widget_sync.dart`
- Modify: `lib/main.dart`
- Modify: `lib/app.dart` (`_syncHomeWidget`)

**Interfaces:**
- Produces: `Future<List<Override>> bootstrapOverrides()`, `typedef ProviderReader = T Function<T>(ProviderListenable<T> provider)`, `Future<void> syncHomeWidget(ProviderReader read)`.

- [ ] **Step 1: Create `lib/bootstrap.dart`**

Move the body of `main()` between `WidgetDataService.initialize()` and `runApp` into:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/repositories/secure_storage_repository.dart';
import 'providers/providers.dart';

/// Provider overrides shared by the app and the SMS background entrypoint.
Future<List<Override>> bootstrapOverrides() async {
  final sharedPreferences = await SharedPreferences.getInstance();
  const secureStorage = FlutterSecureStorage();
  final secureRepo = SecureStorageRepository(secureStorage);

  // One-time migration: move sensitive data from SharedPreferences to keystore
  await secureRepo.migrateFromSharedPreferences(
    oldCardNumber: sharedPreferences.getString('card_number'),
    oldInitialBalance: sharedPreferences.getDouble('initial_balance'),
  );

  // Pre-load secure values so providers can access them synchronously
  final secureCardNumber = await secureRepo.getCardNumber();
  final secureInitialBalance = await secureRepo.getInitialBalance();

  return [
    sharedPreferencesProvider.overrideWithValue(sharedPreferences),
    secureStorageProvider.overrideWithValue(secureRepo),
    secureCardNumberProvider.overrideWithValue(secureCardNumber),
    secureInitialBalanceProvider.overrideWithValue(secureInitialBalance),
  ];
}
```

`lib/main.dart` becomes:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app.dart';
import 'bootstrap.dart';
import 'features/widget/widget_data_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  await WidgetDataService.initialize();

  runApp(
    ProviderScope(
      overrides: await bootstrapOverrides(),
      child: const SpendSplitApp(),
    ),
  );
}
```

- [ ] **Step 2: Create `lib/features/widget/home_widget_sync.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';
import 'widget_data_service.dart';

/// `WidgetRef.read` and `ProviderContainer.read` both fit this.
typedef ProviderReader = T Function<T>(ProviderListenable<T> provider);

/// Pushes the current Available balance to the home-screen widget.
Future<void> syncHomeWidget(ProviderReader read) async {
  final balance = read(balanceSummaryProvider).valueOrNull;
  if (balance == null) return;

  final savingsPercent =
      (read(savingsInsightsProvider).valueOrNull?.monthOverMonthDelta ?? 0) *
      100;

  await WidgetDataService.updateBalance(
    availableBalance: balance.availableBalance,
    savingsPercent: savingsPercent,
  );
}
```

In `app.dart`, replace the body of `_syncHomeWidget()` with `syncHomeWidget(ref.read);`, import `'features/widget/home_widget_sync.dart'`, and drop the now-unused `widget_data_service.dart` import if the analyzer flags it.

- [ ] **Step 3: Full check**

Run: `flutter analyze && flutter test`
Expected: no issues; all PASS.
Run: `flutter run` → dashboard loads, and the home-screen widget still updates after adding a transaction.

- [ ] **Step 4: Commit**

```bash
git add lib/bootstrap.dart lib/features/widget/home_widget_sync.dart lib/main.dart lib/app.dart
git commit -m "refactor: share bootstrap overrides and home-widget sync

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

### Task 11: SmsReceiver, headless entrypoint, RECEIVE_SMS

**Files:**
- Modify: `android/app/src/main/AndroidManifest.xml`
- Modify: `android/app/src/main/kotlin/com/example/spendsplit/SmsBridge.kt` (`REQUESTED_PERMISSIONS`)
- Create: `android/app/src/main/kotlin/com/example/spendsplit/SmsReceiver.kt`
- Modify: `lib/main.dart` (`smsBackgroundMain`)
- Modify: `lib/features/settings/screens/settings_screen.dart` (`_SmsImportRow`)
- Test: `test/sms_settings_screen_test.dart`

**Interfaces:**
- Consumes: `MainActivity.runningChannel`, `SmsBridge.handle` (Task 5); the Dart `import` handler (Task 7); `bootstrapOverrides`, `syncHomeWidget` (Task 10); `smsImportRunnerProvider` (Task 6); `SmsGateway.backgroundDone`.
- Produces: top-level Dart entrypoint `smsBackgroundMain` in `lib/main.dart`.

- [ ] **Step 1: Update the settings tests (failing)**

In `test/sms_settings_screen_test.dart`:
- Change the expected subtitle in 'switching on asks for permission and starts from now' to `'Imported automatically, even in the background'`. The fake grants both permissions by default.
- Append:

```dart
  testWidgets('missing RECEIVE_SMS keeps import on with a tap-to-allow hint', (
    tester,
  ) async {
    final gateway = FakeSmsGateway(
      permissions: const SmsPermissions(read: true, receive: false),
    );
    final prefs = await pumpSettings(tester, gateway, {
      'sms_import_since': 5000,
    });
    expect(find.text('Background capture off — tap to allow'), findsOneWidget);
    expect(prefs.getInt('sms_import_since'), 5000);

    await tester.tap(find.text('Background capture off — tap to allow'));
    await tester.pumpAndSettle();
    expect(
      find.text('Imported automatically, even in the background'),
      findsOneWidget,
    );
  });

  testWidgets('switch turns on with READ_SMS even if RECEIVE_SMS is denied', (
    tester,
  ) async {
    final gateway = FakeSmsGateway(permissions: SmsPermissions.none)
      ..grantOnRequest = const SmsPermissions(read: true, receive: false);
    final prefs = await pumpSettings(tester, gateway);

    await tester.tap(smsSwitch());
    await tester.pumpAndSettle();

    expect(prefs.getInt('sms_import_since'), isNotNull);
    expect(find.text('Background capture off — tap to allow'), findsOneWidget);
  });
```

Run: `flutter test test/sms_settings_screen_test.dart`
Expected: the three changed/new tests FAIL.

- [ ] **Step 2: Update `_SmsImportRow`**

In `settings_screen.dart`, replace the `missingRead` line, `subtitle:` and `onTap:` in `_SmsImportRow.build`:

```dart
    final missingRead = enabled && perms != null && !perms.read;
    final missingReceive = enabled && perms != null && !perms.receive;
```

```dart
      subtitle: !enabled
          ? 'Log card debits and credits from bank SMS automatically'
          : missingRead
          ? 'SMS permission is off — tap to allow'
          : missingReceive
          ? 'Background capture off — tap to allow'
          : 'Imported automatically, even in the background',
      value: enabled,
      onTap: missingRead || missingReceive ? () => _request(context, ref) : null,
```

`_request` already returns `perms.read`, so the switch turns on with only READ_SMS.

Run: `flutter test test/sms_settings_screen_test.dart`
Expected: all PASS.

- [ ] **Step 3: Request RECEIVE_SMS and declare the receiver**

`SmsBridge.kt`:

```kotlin
    val REQUESTED_PERMISSIONS = arrayOf(
        Manifest.permission.READ_SMS,
        Manifest.permission.RECEIVE_SMS,
    )
```

`AndroidManifest.xml`: add after the READ_SMS permission

```xml
    <uses-permission android:name="android.permission.RECEIVE_SMS" />
```

and inside `<application>`, after the widget `<receiver>`:

```xml
        <!-- Wakes the SMS importer when a Trust Bank SMS arrives. Only the
             system (BROADCAST_SMS holder) can send this. -->
        <receiver
            android:name=".SmsReceiver"
            android:exported="true"
            android:permission="android.permission.BROADCAST_SMS">
            <intent-filter>
                <action android:name="android.provider.Telephony.SMS_RECEIVED" />
            </intent-filter>
        </receiver>
```

- [ ] **Step 4: Create `SmsReceiver.kt`**

```kotlin
package com.example.spendsplit

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.provider.Telephony
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

/**
 * Wakes the Dart SMS importer when a Trust Bank SMS arrives. Doesn't parse:
 * the importer reads the inbox itself, so there is one code path.
 */
class SmsReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Telephony.Sms.Intents.SMS_RECEIVED_ACTION) return
        val fromBank = Telephony.Sms.Intents.getMessagesFromIntent(intent)
            ?.any { it?.originatingAddress.equals(SmsBridge.SENDER, ignoreCase = true) } == true
        if (!fromBank) return

        // goAsync() in both branches: invokeMethod and the headless run are async.
        val pending = goAsync()
        val app = context.applicationContext
        val handler = Handler(Looper.getMainLooper())
        var engine: FlutterEngine? = null
        var finished = false
        lateinit var timeout: Runnable

        fun finish() {
            if (finished) return
            finished = true
            handler.removeCallbacks(timeout)
            val headless = engine
            engine = null
            // Destroy after the current channel callback has returned.
            if (headless != null) handler.post { headless.destroy() }
            pending.finish()
        }
        timeout = Runnable { finish() }
        handler.postDelayed(timeout, TIMEOUT_MS)

        val running = MainActivity.runningChannel
        if (running != null) {
            running.invokeMethod(
                "import",
                mapOf("waitForNew" to true),
                object : MethodChannel.Result {
                    override fun success(result: Any?) = finish()
                    override fun error(code: String, message: String?, details: Any?) = finish()
                    override fun notImplemented() = finish()
                },
            )
            return
        }

        val headless = FlutterEngine(app)
        engine = headless
        MethodChannel(headless.dartExecutor.binaryMessenger, SmsBridge.CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "backgroundDone") {
                    result.success(null)
                    finish()
                } else {
                    SmsBridge.handle(app, call, result)
                }
            }
        headless.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint(
                FlutterInjector.instance().flutterLoader().findAppBundlePath(),
                "smsBackgroundMain",
            ),
        )
    }

    private companion object {
        /** Receivers get ~10 s after goAsync(); stay under it. */
        const val TIMEOUT_MS = 9_000L
    }
}
```

- [ ] **Step 5: Add the Dart entrypoint**

Append to `lib/main.dart` (add imports `'features/sms_import/sms_gateway.dart'`, `'features/sms_import/sms_import_runner.dart'`, `'features/widget/home_widget_sync.dart'`, `'providers/providers.dart'`):

```dart
/// Entrypoint for SmsReceiver's headless engine when the app isn't running.
@pragma('vm:entry-point')
Future<void> smsBackgroundMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  await WidgetDataService.initialize();
  final container = ProviderContainer(overrides: await bootstrapOverrides());
  try {
    final inserted = await container
        .read(smsImportRunnerProvider)
        .run(waitForNew: true);
    if (inserted > 0) {
      await container.read(transactionsProvider.future);
      await syncHomeWidget(container.read);
    }
  } finally {
    container.dispose();
    await const SmsGateway().backgroundDone();
  }
}
```

- [ ] **Step 6: Build**

Run: `flutter analyze && flutter test`
Expected: no issues; all PASS.
Run: `flutter build apk --debug`
Expected: build succeeds.

- [ ] **Step 7: Manual check on the phone**

Install with `flutter run`, then open Settings. The switch asks for SMS receive permission (existing users tap the "Background capture off" hint). Then:
1. **App in background:** press Home and make a small card payment. Within ~5 s of the SMS the home-screen widget balance changes. Opening the app shows the entry with the Review chip and no snackbar duplicate.
2. **App killed:** swipe SpendSplit away in Recents and repeat. The widget updates and the entry exists on next open.
3. **Non-bank SMS:** send yourself an SMS from another phone. Nothing happens; `adb logcat | rg -i flutter` shows no engine start.
4. **Deny RECEIVE_SMS** in App info → Permissions. The Settings switch stays on with "Background capture off — tap to allow", and on-open import still works.

- [ ] **Step 8: Commit**

```bash
git add android/app/src/main/AndroidManifest.xml android/app/src/main/kotlin/com/example/spendsplit/SmsBridge.kt android/app/src/main/kotlin/com/example/spendsplit/SmsReceiver.kt lib/main.dart lib/features/settings/screens/settings_screen.dart test/sms_settings_screen_test.dart
git commit -m "feat(sms): background capture via SmsReceiver and headless engine

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

### Task 12: Update CLAUDE.md

**Files:**
- Modify: `CLAUDE.md`

- [ ] **Step 1: Update the docs**

In `CLAUDE.md`:
- Database Schema: change `schemaVersion` 7 → 8. Add: "`transactions_table` carries `sms_ref` (unique; `<receive millis>|<SMS body>`, null for manual rows) and `needs_review`. The v7 → v8 migration is additive only." Add `sms_import_since`, `bank_balance`, `bank_balance_at` to the SharedPreferences key list.
- Features: add

```markdown
- **Trust Bank SMS import** (Android) — Settings → "Import Trust Bank SMS".
  Debits become expenses in Other, credits become income (source other),
  flagged `needs_review` until saved from the edit sheet. Runs on app
  open/resume and, via `SmsReceiver` + headless `smsBackgroundMain`, in the
  background. Dedupe: unique `sms_ref` + `sms_import_since` watermark
  (strictly newer). Dashboard shows a review card and a bank-balance
  reconciliation card (`bankReconciliationProvider`).
```

- [ ] **Step 2: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: CLAUDE.md — SMS import, schema v8

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```
