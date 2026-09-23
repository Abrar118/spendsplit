# Trust Bank SMS Import — Design

**Date:** 2026-09-23
**Status:** Approved in chat, pending spec review

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

## 1. On-open import

### Native bridge (`MainActivity.kt`, no new dependency)

`MethodChannel("spendsplit/sms")`:

| Method | Returns |
|---|---|
| `hasPermission` | `bool` — `READ_SMS` granted |
| `requestPermission` | `bool` — requests `READ_SMS` + `RECEIVE_SMS`, resolves with the result |
| `readInbox({sinceMillis})` | `List<{body: String, date: int}>` from `content://sms/inbox` where `address LIKE '%TrustBank%'` and `date > sinceMillis`, ordered `date ASC` |

Manifest adds `READ_SMS` (and `RECEIVE_SMS` for phase 4).

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

- **Schema v8** (additive, same pattern as v6→v7): `transactions_table` gains
  - `sms_ref TEXT NULL` with a **unique index**
  - `needs_review BOOLEAN NOT NULL DEFAULT false` (phase 2)

  `sms_ref` = `"<ISO dateTime>|<amount toStringAsFixed(2)>|<balance toStringAsFixed(2)>"`,
  e.g. `2026-09-21T17:28:00.000|70.00|480578.45`. Inserts use
  `InsertMode.insertOrIgnore`, so the DB rejects repeats regardless of
  watermark state (restored backup, reinstall, reset).
- **Watermark:** SharedPreferences `sms_import_since` (int millis, SMS provider
  receive time). `null` = feature off. Enabling sets it to `now`, so historical
  SMS (already entered by hand) are never imported. After a run it advances to
  the max `date` returned.

JSON snapshots pick the new columns up automatically via `toJson`/`fromJson`;
older snapshots without them restore as `null` / `false`.

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
- Known ceiling: a manual entry dated at midnight but made after the bank txn
  that day can produce a small false mismatch.

The card is a new widget; `balance_card.dart` / `financial_summaries.dart`
(which have unrelated uncommitted work) are not modified.

---

## 4. Background capture

- Manifest: `RECEIVE_SMS` + `SmsReceiver` (`android.provider.Telephony.SMS_RECEIVED`).
- `SmsReceiver` does not parse. It only triggers the same `runSmsImport`:
  - Process alive with a Flutter engine → invoke `import` on the running
    engine's `spendsplit/sms` channel.
  - Otherwise → `goAsync()`, start a headless `FlutterEngine` running Dart
    entrypoint `@pragma('vm:entry-point') smsBackgroundMain()`, which runs the
    import, syncs the home-screen widget, then signals completion so the engine
    is destroyed.
- Home-widget sync is extracted from `app.dart` into a shared function used by
  both the app and `smsBackgroundMain`.
- On-open import remains the safety net (OEM autostart restrictions can kill
  receivers).
- Known ceiling: a headless run concurrent with app launch briefly means two DB
  connections; the unique index prevents duplicates and the app re-reads on open.

---

## Testing

- `test/sms_parser_test.dart`: the 5 provided samples (POS/TRUST MONEY debits,
  TRUST MONEY/BRANCH TRANSFER credits) parse to exact values; an OTP/promo body
  returns `null`.
- `test/sms_import_test.dart` (in-memory Drift): importing the same SMS twice
  yields one row; debit → expense/Other/needs_review; credit →
  income/source other; watermark advances only on success.
- Reconciliation diff: a unit test for the "transactions up to
  `bank_balance_at`" total.
- Background capture and permissions verified manually on device.
