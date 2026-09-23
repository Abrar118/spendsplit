# Trust Bank SMS Import — Design

**Date:** 2026-09-23
**Status:** Approved in chat; revised after review (rev 2)

## Goal

Stop manually typing card purchases. Trust Bank sends an SMS for every debit and
credit; SpendSplit reads those, creates the transaction automatically, and lets
the user fix category/note later. Android only (iOS forbids SMS access). The app
is sideloaded from GitHub releases, so Play Store SMS-permission policy does not
apply.

## SMS format

Sender address: `TrustBank`. Body:

```
POS Txn
TK 70.00 DEBIT
AC No 031***492
21/09/2026 05:28 PM
Balance TK 480578.45
Call Center at your fingertips: t.tblbd.com/SIVR
```

Observed labels: `POS Txn`, `TRUST MONEY Txn`, `BRANCH TRANSFER Txn`. Direction
is `DEBIT` or `CREDIT`. Date is `dd/MM/yyyy hh:mm a`.

## Scope

1. On-open import + dedupe + Settings toggle
2. "Needs review" marker
3. Bank balance reconciliation
4. Background capture

Each phase ships independently in this order.

Out of scope: multiple bank accounts / account-number filtering, other banks,
notifications, iOS.

---

## 0. Existing data safety (hard requirement)

Updating to this version must not erase, alter, or re-import anything already in
the database.

- **Migration v7 → v8 is additive only:** two `ALTER TABLE transactions_table
  ADD COLUMN` statements plus `CREATE UNIQUE INDEX` on `sms_ref`. The table is
  never dropped or recreated. Existing rows get `sms_ref = NULL` and
  `needs_review = false`. SQLite unique indexes permit any number of NULLs, so
  existing rows never collide with each other or with imports.
- **Off by default:** after the update nothing reads SMS until the user turns the
  Settings switch on.
- **No history import:** turning it on sets the watermark to *now*; SMS received
  before that moment (already entered by hand) are never read.
- **Insert-only:** the importer only inserts. It never updates or deletes an
  existing row.

Verified by tests (see Testing): a v7 database with rows migrates to v8 with
every row unchanged; enabling with older SMS in the inbox imports nothing.

---

## 1. On-open import

### Native bridge (`MainActivity.kt`, no new dependency)

`MainActivity` overrides `configureFlutterEngine` to register
`MethodChannel("spendsplit/sms")`:

| Method | Returns |
|---|---|
| `hasPermission` | `bool` — `READ_SMS` granted |
| `requestPermission` | `bool` — requests `READ_SMS` only (phase 4 adds `RECEIVE_SMS`, see §4), resolves with the result |
| `readInbox({sinceMillis})` | `List<{body: String, date: int}>` from `content://sms/inbox` where `address = 'TrustBank' COLLATE NOCASE` (exact match) and `date >= sinceMillis`, ordered `date ASC` |

Phase 1 manifest adds `READ_SMS` only. Android refuses to grant a permission that
isn't declared, so `RECEIVE_SMS` is declared and requested only in phase 4.

### Parser — `lib/features/sms_import/sms_parser.dart`

Pure function `ParsedSms? parseTrustBankSms(String body)` returning
`{label, amount, isCredit, dateTime, balance}`. Returns `null` for any body that
doesn't match all required lines (OTPs, promos). Amount and balance parsed with
thousands separators tolerated.

### Mapping

| SMS | type | category / source | note | date |
|---|---|---|---|---|
| DEBIT | `expense` | `categoryId` = the predefined **Other** category | label, e.g. `POS Txn` | SMS body datetime |
| CREDIT | `income` | `source` = `IncomeSource.other`, `categoryId` null | label | SMS body datetime |

Income uses `source`, not categories — matching `add_transaction_sheet.dart`.

### Dedupe (two layers)

- **Schema v8** (additive, see §0): `transactions_table` gains
  - `sms_ref TEXT NULL` with a **unique index**
  - `needs_review BOOLEAN NOT NULL DEFAULT false` (phase 2)

  `sms_ref` = `"<provider receive millis>|<full SMS body>"`. The SMS body's
  timestamp has only minute precision, so body fields alone could collide for two
  real transactions; the provider receive time plus the whole body identifies
  one inbox message. Inserts use `InsertMode.insertOrIgnore`, so the DB rejects
  repeats regardless of watermark state (restored backup, reinstall, reset).
  Trade-off accepted: a bank that re-sends the same SMS would produce two rows;
  both carry the Review chip, so the user can spot and delete one. A silently
  dropped transaction would be worse.
- **Watermark:** SharedPreferences `sms_import_since` (int millis, SMS provider
  receive time). `null` = feature off. Enabling sets it to `now`. After a run it
  advances to the max `date` returned. The inbox query uses `>=`, so a message
  sharing the boundary millisecond is reread and dropped by the unique index
  rather than skipped.

### Backup / restore

- **Old backups:** `SnapshotService.importTables` fills absent transaction fields
  before `TransactionsTableData.fromJson` (`needsReview: false`, `smsRef: null`),
  because Drift's generated `fromJson<bool>` throws on a missing non-null field
  before the DB default applies.
- **Watermark travels with the backup:** `smsImportSince` is added to the
  `settings` block on export. On restore it is written back; if absent (backup
  predates the feature), importing is turned **off**. Otherwise restoring an
  older backup would leave a newer watermark and permanently skip the SMS whose
  rows the restore just removed. With the backup's watermark restored, those SMS
  are reread and the unique index drops any already present.
- Restore clears `bank_balance` / `bank_balance_at` (§3); the next import
  repopulates them.

### Import service — `lib/features/sms_import/sms_import_service.dart`

`Future<int> runSmsImport(...)`:

1. Return 0 if `sms_import_since` is null or permission is missing.
2. `readInbox(since)` → parse each → skip `null`s.
3. In one DB transaction, `insertOrIgnore` each row; count actual inserts.
4. Advance watermark; store latest bank balance (phase 3).
5. Return inserted count.

Triggered on app start and on `AppLifecycleState.resumed` (existing observer in
`app.dart`). A non-zero count shows a snackbar: "Imported N transactions from SMS".
Failures (channel error, parse crash) are logged and swallowed — import never
blocks app start — and the watermark is **not** advanced on failure.

### Settings toggle

Settings screen: switch **"Import Trust Bank SMS"**.

- **On:** `requestPermission`; if granted, set `sms_import_since = now`; if
  denied, switch stays off with a snackbar explaining why.
- **Off:** clear `sms_import_since`. All triggers (foreground + background) no-op.

Exposed through `AppSettings` / `SettingsController` like the other settings.

---

## 2. Needs-review marker

- SMS imports set `needs_review = true`.
- Saving a transaction from the add/edit sheet clears it (saving unchanged
  counts as "reviewed").
- Transaction tile shows a small amber **Review** chip when set.
- Dashboard card **"N SMS entries to review"** (hidden when N = 0) opens the
  Transactions screen filtered to `needs_review = true`.

---

## 3. Bank balance reconciliation

- On import, keep the bank balance from the SMS with the latest transaction
  datetime: SharedPreferences `bank_balance` (double) and `bank_balance_at`
  (ISO datetime). Only overwrite when the new SMS is later.
- Compare against app **Total Balance** (initial + income − expenses, not
  Available — savings lives in the same account), counting only transactions
  with `date <= bank_balance_at`.
- If `|diff| >= 1`, a separate dashboard card shows
  "Bank ৳X · App ৳Y · off by ৳Z" with one action, **Adjust start balance**,
  which sets `initial_balance += diff` (secure storage). No adjustment
  transaction is created, so charts stay clean. If the gap is a missing entry,
  the user adds it and the card disappears on its own.
- Card is hidden when SMS import is off or `bank_balance` is unset.
- Known ceiling: a manual entry dated at midnight but made after the bank txn
  that day can produce a small false mismatch.

The card is a new widget; `balance_card.dart` / `financial_summaries.dart`
(which have unrelated uncommitted work) are not modified.

---

## 4. Background capture

- Manifest adds `RECEIVE_SMS` and `SmsReceiver`
  (`android.provider.Telephony.SMS_RECEIVED`). `requestPermission` now requests
  `READ_SMS` + `RECEIVE_SMS`; users who enabled the switch in phase 1 are asked
  for `RECEIVE_SMS` on the next app open while the switch is on. Without it,
  on-open import still works.
- **Engine registration:** `MainActivity` stores its `spendsplit/sms`
  `MethodChannel` in a companion-object field in `configureFlutterEngine` and
  nulls it in `cleanUpFlutterEngine`. That field is the "running engine" handle.
- `SmsReceiver.onReceive` (main thread) does not parse. It only triggers the same
  `runSmsImport`:
  - Channel field non-null (app process and engine alive, foreground or not) →
    `invokeMethod("import")`. One DB connection, and Drift streams refresh the UI.
  - Otherwise → `goAsync()`, start a headless `FlutterEngine` running Dart
    entrypoint `@pragma('vm:entry-point') smsBackgroundMain()`, which runs the
    import, syncs the home-screen widget, then calls back so the receiver
    destroys the engine and finishes the pending result.
- Home-widget sync is extracted from `app.dart` into a shared function used by
  both the app and `smsBackgroundMain`.
- On-open import remains the safety net (OEM autostart restrictions can kill
  receivers).
- Known ceiling: if the app is launched while a headless run is in flight, two
  DB connections exist briefly; the unique index prevents duplicates and the
  on-open import re-reads.

---

## Testing

- `test/sms_parser_test.dart`: the 5 provided samples (POS/TRUST MONEY debits,
  TRUST MONEY/BRANCH TRANSFER credits) parse to exact values; an OTP/promo body
  returns `null`.
- `test/sms_import_test.dart` (in-memory Drift, fake inbox):
  - same SMS imported twice → one row
  - two SMS with identical bodies but different receive millis → two rows
  - debit → expense/Other/needs_review; credit → income/source other
  - inbox SMS older than the watermark → nothing imported
  - watermark advances only on success
  - existing rows (null `sms_ref`) are untouched after an import
- `test/migration_test.dart`: a v7 database with transactions migrates to v8
  with every row's values unchanged, `sms_ref` null, `needs_review` false
  (follows the existing v5 fixture pattern).
- Snapshot: restoring a backup JSON without `needsReview` / `smsRef` /
  `smsImportSince` succeeds and turns import off.
- Reconciliation diff: a unit test for the "transactions up to
  `bank_balance_at`" total.
- Background capture and permissions verified manually on device.
