# AGENTS.md — SpendSplit

Shared instructions for coding agents (Claude Code reads this via `CLAUDE.md`;
Codex reads it directly). Keep this file as the single source — don't fork
guidance back into `CLAUDE.md`.

## Project Overview

**SpendSplit** is a minimalist, offline-only mobile expense tracker built with
Flutter. It splits a single bank account balance into Available (spendable) and
Savings, with a dark glassmorphic UI, biometric lock, and an isolated USD
spending tracker.

- **Owner's device:** iPhone 17 (base model, iOS). Previously a Galaxy S25, so
  the codebase grew up Android-first — verify new work on iOS.
- **Platforms:** iOS + Android. Trust Bank SMS import works differently per
  platform (iOS has no SMS-read API — see Features). Android-only today: the
  home-screen widget (`home_widget` is wired with `iOSName: 'SpendSplitWidget'`,
  but no iOS widget extension exists in `ios/`).
- iOS builds need macOS + Xcode; the dev machine is Windows, so iOS changes
  can't be built or run locally here — say so rather than claiming they work.
- **State:** Riverpod (plain providers — no `riverpod_annotation` codegen)
- **Database:** Drift (SQLite)
- **Navigation:** GoRouter
- **Architecture:** feature-first MVVM; pure-Dart calculators in
  `FinanceCalculators` (unit-tested), exposed via providers, consumed by thin widgets.

## Commands

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs  # Drift codegen
flutter analyze
flutter test
flutter run
```

Run `build_runner` after changing Drift tables/DAOs. Tests cover calculator
regressions, schema migrations, snapshot round-trip, SMS parsing/import
(`test/support/fake_sms_gateway.dart`), and widget layout guards.

---

## Project Structure

```
lib/
├── main.dart
├── app.dart              # MaterialApp + GoRouter (routerProvider) + Theme
├── core/                 # theme/, constants/ (enums incl. AppRoute), icons/, utils/, widgets/
├── data/
│   ├── database/         # app_database.dart, tables/, daos/
│   ├── models/
│   └── repositories/     # settings_repository, secure_storage_repository, …
├── features/
│   ├── auth/             # lock screen, biometric
│   ├── dashboard/
│   ├── transactions/     # list, filters, add/edit sheet
│   ├── monthly/
│   ├── graphs/           # spending and balance-trend charts
│   ├── goals/
│   ├── dollar_tracker/   # isolated USD tracker
│   ├── export/           # CSV/PDF export, CSV import, JSON snapshot
│   ├── settings/         # settings, manage categories/templates
│   ├── sms_import/       # Trust Bank SMS (Android)
│   └── widget/           # home-screen widget sync
└── providers/            # global Riverpod providers
```

Features use `screens/`, `widgets/`, `providers/` as needed. Android native code
(SMS bridge/receiver, widget provider) lives in
`android/app/src/main/kotlin/com/abrar/spendsplit/` (app ID `com.abrar.spendsplit`
on both platforms).

## Key Dependencies

`flutter_riverpod`, `drift` + `sqlite3`, `go_router`, `fl_chart`, `google_fonts`,
`flutter_animate`, `shimmer`, `local_auth`, `lucide_icons`, `flutter_slidable`,
`modal_bottom_sheet`, `shared_preferences`, `flutter_secure_storage`,
`share_plus`, `file_selector`, `path_provider`, `home_widget`, `pdf`, `gap`,
`intl`, `vibration`. Check `pubspec.yaml` before adding anything.

---

## Design System (MUST follow)

The visual system is **Grid Numerals**, documented in `DESIGN.md` at the repo
root (tokens in `.impeccable/design.json`); product context is in
`PRODUCT.md`. Code is the source of truth: `lib/core/theme/` (`AppColors`,
`AppTypography`, `AppDecorations`, `AppSpacing`) and the world's components in
`lib/core/widgets/`. Never hand-roll colours, radii or type.

- **Dark only**, near-black ground (`AppColors.background`). Square modules
  (`AppDecorations.radius` is 0), hairline rules, no glows or gradients. The only
  glass is the floating frosted tab bar.
- **Colour is a legend; each hue has one job.** Orange `accent` = Available and
  the primary action only. Bone `savings` = Savings. `income` green, `spend`
  magenta-red (spending totals, delete, the review stamp), `warning` yellow,
  `usd` blue = Dollar Tracker only. Controls (chips, segmented controls, tabs)
  are neutral. Category colours are a muted ramp kept clear of the legend:
  draw them with `categoryColor(stored)` (`core/constants/categories.dart`),
  which also remaps colours older builds stored.
- **Type:** the platform sans (SF Pro / Roboto) with tabular figures, in
  sentence case. Doto dot-grid numerals only for a screen's one hero figure,
  via `DotFigure`, which draws the construction grid at the figure's dot pitch
  (cell = size / 10). Doto has no ৳; the sign is set in the sans.
- **Entries are coupons** (`Coupon`): stub (time or date), perforation, body.
  Posted solid, upcoming dashed, unchecked SMS stamped.
- **Tabs** use `LargeTitlePage` (iOS large title that collapses on scroll) and
  `PageBody`; pages reserve `AppSpacing.navClearance` under the tab bar.
- **Motion:** one count-up per hero figure and ease-out fills; both respect
  Reduce Motion. **Haptics** on +, save and swipe-delete.

### Design references (historical)

`asset/DESIGN.md`, `asset/stitch_add_transaction_sheet/*/{screen.png,code.html}`
and `lucid_obsidian/DESIGN.md` describe discarded looks (glass, gold, Manrope).
Don't follow them. `asset/SpendSplit_Flutter_Guide.md` is still useful for
screen specs and calculated-value definitions.

---

## Navigation

```
ShellRoute (BottomNavBar)
├── /                    → DashboardScreen (tab 0)
├── /transactions        → TransactionsScreen (tab 1; ?month=, ?categoryId=, ?review=1)
├── /monthly             → MonthlyScreen (tab 3)
├── /graphs              → GraphsScreen (tab 4)
└── /goals               → GoalsScreen (tab 5)

Pushed on root navigator:
/dollar-tracker, /goal/:id, /settings, /export, /manage-categories,
/manage-templates, /lock
```

Paths come from the `AppRoute` enum (`core/constants/enums.dart`). Center "+"
(index 2) opens `AddTransactionSheet` via `showModalBottomSheet` — it does NOT
navigate. `/lock` is enforced by the router redirect when biometric is enabled
and the session is locked.

## Data

Drift, `schemaVersion` 8, six tables: `transactions_table`, `categories_table`,
`savings_goals_table`, `dollar_expenses_table`, `transaction_templates_table`
(`use_count`, `is_monthly`), `category_budgets_table` (one `monthly_limit` per
`category_id`). `transactions_table` carries `sms_ref` (unique;
`<receive millis>|<SMS body>`, null for manual rows) and `needs_review`.
Migrations are additive only — add a migration test for any schema change.

SharedPreferences: `biometric_enabled`, `dollar_annual_limit`,
`dollar_limit_year`, `monthly_expense_budget`, `recap_dismissed_month`,
`sms_import_since`, `sms_seen_refs`, `bank_balance`, `bank_balance_at`,
`sms_unparsed_count`, `sms_unparsed_latest`. `initial_balance` and
`card_number` live in the platform keystore (`SecureStorageRepository`); the
bootstrap removes any old plaintext copies, and on iOS clears the keystore on
a fresh install (no database file), since the Keychain survives app deletion.

The database runs in WAL mode with a 5 s busy timeout, because the Android
SMS background engine opens its own connection. Each engine also caches
SharedPreferences separately, so SMS imports call
`SettingsController.reloadFromDisk()` first.

**Time and future-dated entries:**
- Balances, charts, summaries, budgets and goal/dollar pacing use
  `postedTransactionsProvider`, which drops entries dated after now. Lists
  use `transactionsProvider`.
- Date-based providers `ref.watch(clockTickProvider)` (bumped on resume and
  at midnight), then read `DateTime.now()`. Never store a time in a provider:
  it would lag behind entries saved later.
- Use `calendarDaysUntil` for "days left", not `Duration.inDays`.

**Goal amount invariant:** a goal's `currentAmount` equals the sum of its
linked deposits minus withdrawals. Contribute, edit, delete and undo all add
or reverse the full amount; never cap at the target.

**Calculated values (derived, never stored):**
- Total Balance = initial_balance + SUM(income) − SUM(expenses)
- Savings Balance = SUM(savings_deposits) − SUM(savings_withdrawals)
- Available Balance = Total Balance − Savings Balance
- Dollar Remaining = dollar_annual_limit − SUM(dollar_expenses for year)

## Critical Rules

1. **Dollar Tracker is fully isolated** — never feeds BDT graphs, monthly
   summaries, or balance calculations.
2. **Currency:** BDT (৳) for the main tracker, USD ($) only in the dollar
   tracker. No conversion.
3. **Amounts are stored positive**; direction comes from the type enum
   (`income`, `expense`, `savings_deposit`, `savings_withdrawal`).
4. **Categories:** 6 predefined (Food, Transport, Utilities, Health, Shopping,
   Other — fully locked) + user-created custom ones. Dollar tracker has its own.
5. **Edit:** tap a transaction → `AddTransactionSheet` pre-filled → "Update".
6. **Delete:** swipe left → red panel → snackbar with 3-second Undo.

## Features

- **Future-dated entries** are excluded from balances.
- **Balance trend** — 6-month reconstructed Available/Savings chart (Graphs).
- **Spending chart** — rolling 12-month expense bars with income overlay
  (Graphs).
- **Month pace** — this month's running spend against last month's, day by
  day (Graphs).
- **Daily spending heatmap** — 13 weeks of days shaded by spend quartile;
  tap a day for its total (Graphs). Series maths in `graphs/graph_series.dart`.
- **Card number** — stored in the keystore, edited and shown masked in
  Settings.
- **Category budgets** — per-category monthly limits, edited inline on Monthly's
  Category Details rows.
- **Category editor** — rename/re-icon/recolour custom categories
  (`_CategoryEditorSheet`).
- **Goal contributions** — "Add Contribution" logs a linked `savings_deposit`
  and bumps the goal; tapping a goal opens `/goal/:id` with history and a
  completion projection.
- **Budget pace** — on the current month, `BudgetProgressBar` shows a tick at
  the share of the month gone. Bars turn amber when spending is ahead of pace.
- **Dollar pacing** — projected year-end USD spend vs. the annual limit,
  hidden for the first 30 days of the year.
- **Month-end recap** — dismissible dashboard card (days 1–5) for the prior
  month; dismissal stored in `recap_dismissed_month`. Flags up to two
  categories ±25% or more from their 3-month average.
- **Privacy cover** — on Android 13+, `setRecentsScreenshotEnabled(false)`.
  On iOS, a cover with the app icon whenever the app isn't resumed.
- **Templates** — top-3 by `use_count` as quick chips in the add sheet;
  "Expected monthly" templates not yet logged this month surface on the dashboard.
- **Export/backup** — CSV/PDF export, CSV import, full JSON snapshot of all six
  tables + settings (`SnapshotService`), restore behind hold-to-confirm.
- **Home-screen widget** (Android) — Available balance via `home_widget`.
- **Trust Bank SMS import** — Android: Settings → "Import Trust Bank SMS".
  Debits → expenses in Other, credits → income, flagged `needs_review` until
  saved from the edit sheet. Runs on app open/resume and in the background via
  `SmsReceiver` + headless `smsBackgroundMain`. Dedupe: unique `sms_ref`; the
  `sms_import_since` watermark trails the newest SMS by 10 min and
  `sms_seen_refs` skips already-processed SMS in that window, so deleted entries
  stay deleted. Restore runs under `SmsImportRunner.whilePaused`. Dashboard
  shows a review card and a bank-balance reconciliation card
  (`bankReconciliationProvider`). Settings counts alerts that mention
  DEBIT/CREDIT but fail to parse, a sign the bank changed its format.
  **iOS:** a user-built Shortcuts automation (message contains "Balance TK",
  no confirm) saves each alert as a file in `Documents/SMS Inbox` (exposed in
  Files via `UIFileSharingEnabled`). On open/resume `SmsImportRunner` imports
  and deletes those files; receive time = file mtime. Shortcuts saves text
  copied from Messages as RTFD, so files are decoded natively
  (`spendsplit/text` channel in `AppDelegate.swift`, `NSAttributedString`); an
  unreadable file is kept and skipped. The first iOS import switches
  `sms_import_since` on so the reconciliation card works.

## Gotchas

- Wrap system pickers in
  `appSessionUnlockedProvider.notifier.stayUnlockedDuring(...)`. Android
  backgrounds the app for them, and re-locking tears down the waiting screen.
- Callbacks that outlive a screen (snackbar Undo, multi-step restore) must
  `ref.read` everything up front. `ref` throws once the widget is disposed,
  and tab switches dispose screens.
- `CategoryDao.deleteCategory(id, moveTo:)` moves the category's rows to
  `moveTo`, or, without it, detaches the transactions and templates (sets
  them to null). Either way it removes the budget. Restore keeps the category
  ID sequence above every referenced ID.
- Deleting a goal returns the IDs of the transactions it unlinked;
  `restoreGoal` relinks them for Undo.

Ideas and known-but-unfixed bugs: `docs/BACKLOG.md`.

## Out of Scope

Cloud sync, multiple accounts, push notifications/reminders, recurring
transactions (the monthly-template checklist is the substitute), currency
conversion, light mode, onboarding tutorial.
