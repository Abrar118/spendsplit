# SpendSplit Feature Expansion — Design

**Date:** 2026-09-06
**Status:** Approved for spec review

## Goal

Add a set of intelligence, budgeting, and data-safety features to SpendSplit, plus
targeted layout fixes, delivered in three staged batches. No color or theme changes.

## Constraints

- **No color/theme changes.** Reuse the existing `AppColors` accent set and
  `AppDecorations`. New UI matches the current pure-black + frosted-glass style.
- **Dollar Tracker stays isolated** — no new cross-contamination with BDT
  calculations, charts, or summaries.
- **Additive schema migration only** (v6 → v7). No existing rows mutated. Ship a
  regression test for the upgrade path, matching the v6 test.
- Each batch is built, device-verified on the connected phone, committed, and
  pushed before the next begins.

## Delivery batches

1. **Group 1** — CLAUDE.md reconciliation, layout fixes, runway/burn rate,
   dollar-tracker pacing.
2. **Group 2** — balance trend chart, rolling-12-month spending velocity with
   income, category icon/color/rename, per-category budgets (schema v7).
3. **Group 3** — goal contributions + goal detail + projection, template
   most-used chips + monthly checklist (schema v7), month-end recap, full JSON
   snapshot backup/restore.

Schema v7 is introduced at the **start of Group 2** and carries every new
column/table needed by Groups 2 and 3 (`category_budgets_table`, plus
`useCount` and `isMonthly` on `transaction_templates_table`), so there is only
one migration.

---

## Group 1

### 1.1 CLAUDE.md reconciliation

Rewrite the stale sections of `CLAUDE.md` to match the shipped app:

- **Design System Rules → Dark Theme Only**: base void is pure black `#000000`
  (the old "NEVER use #000000" rule is removed — it was overridden deliberately).
  Card surfaces `#15131F`, elevated `#1E1A2C`.
- **Color Accents**: replace with the current set —
  - Gold `#ECBB7E` (`AppColors.teal`) — primary actions, available balance, active nav
  - Coral `#F26D3D` — expenses, negative amounts, delete
  - Green `#34D89C` — income, positive amounts
  - Purple `#9B8BFF` — savings, goal progress
  - Amber `#ECB877` — warnings, deadlines, dollar ring
  - Violet `#7A46E0` (`AppColors.blue`) — charts, secondary highlights
- **Typography**: Google Fonts **Manrope** (not Inter).
- **Cards & Components**: bottom nav is a frosted saturation-blur pill, radius 28,
  no border, `#16121F` tint; content scrolls behind it (`AppSpacing.navClearance`).
- **Navigation Structure**: note tab indices — dashboard 0, transactions 1,
  add 2 (sheet, no route), monthly 3, goals 4.
- **Database Schema**: 5 tables at this point — `transactions_table`,
  `categories_table`, `savings_goals_table`, `dollar_expenses_table`,
  `transaction_templates_table`. SharedPreferences adds `monthly_expense_budget`
  and `recap_dismissed_month`. (`category_budgets_table` and the template columns
  land in Group 2 and are documented in the 3.5 final pass.)
- **What NOT to Implement**: remove "Export to CSV/PDF" and "Home screen widgets"
  (both shipped). Keep: cloud sync, multiple accounts, currency conversion, light
  mode, onboarding tutorial, push notifications/reminders. Note that recurring
  transactions remain unimplemented; the monthly-template checklist is the
  lightweight substitute.
- **When Building UI**: soften rule 1 — the `asset/stitch_*` mockups are
  historical reference; the live design has deliberately moved past them. Keep
  `DESIGN.md` / the guide as directional, not literal.
- Add a **Features** section briefly documenting: runway, balance trend,
  category budgets, goal contributions + projection, month-end recap, JSON
  snapshot backup, template checklist.

### 1.2 Layout fixes (no color/theme change)

| # | File | Change |
|---|------|--------|
| a | `dashboard/widgets/monthly_snapshot_row.dart` | Replace the horizontal `ListView` of fixed-width 136 cards with a `Row` of three `Expanded` cards (`INCOME` / `SPENT` / `SAVED`), gap 12. Card content unchanged; drop the fixed `SizedBox(width:136)` and the outer `SizedBox(height:126)` becomes an `IntrinsicHeight` row or a fixed height that fits all three. Nothing clips at 360dp width. |
| b | `monthly/screens/monthly_screen.dart` + `monthly/widgets/monthly_budget_card.dart` | When `settings.monthlyExpenseBudget == 0`, render a single-line prompt row ("Set a monthly budget" + chevron, tappable → opens the existing budget editor) instead of the full `MonthlyBudgetCard`. Full card renders only when a budget is set. |
| c | `goals/screens/goals_screen.dart` | The "Completed Goals" `ExpansionTile` gets `initiallyExpanded: false`. |
| d | `goals/widgets/total_savings_banner.dart` | Pluralize: `Across N active goal${N == 1 ? '' : 's'}`. |
| e | `dashboard/widgets/balance_card.dart` | In the AVAILABLE / SAVINGS segment row (`_BalanceSegment`), AVAILABLE's amount goes to ~26sp bold gold (from the current `headlineMedium` ~24); SAVINGS stays at its current size. The runway line (1.3) renders directly beneath the AVAILABLE amount, inside the same column. Total Balance stays the card's top hero — no restructure of the card body. |

### 1.3 Runway / burn rate

- **Calculator** — add to `FinanceCalculators`:
  ```
  SpendingRunway spendingRunway({
    required List<TransactionsTableData> transactions,
    required double availableBalance,
    DateTime? asOf,          // defaults to now
    int windowDays = 30,
  })
  ```
  `avgDailyBurn` = sum of `expense`-type amounts dated within the trailing
  `windowDays` ÷ `windowDays`. Savings deposits/withdrawals and income are
  excluded (they don't drain Available through spending). `daysRemaining` =
  `availableBalance / avgDailyBurn`, or `null` when `avgDailyBurn <= epsilon`.
- **Model** — `class SpendingRunway { double avgDailyBurn; int? daysRemaining; int windowDays; }`
  in `financial_summaries.dart`.
- **Provider** — `spendingRunwayProvider` (`Provider<AsyncValue<SpendingRunway>>`),
  derived from `transactionsProvider` + `balanceSummaryProvider`.
- **UI** — one line under the AVAILABLE amount in `balance_card.dart`:
  - has burn + balance: `~34 days left · ৳2,270/day`
  - `daysRemaining == null`: `No recent spending` (muted)
  - `daysRemaining != null && < 14`: same text, coral.
  - Uses `formatCompactBdt` / existing formatters. No animation beyond the
    card's existing fade.

### 1.4 Dollar-tracker pacing

- **Model** — extend `DollarTrackerSummary` with:
  `double pacePerDay`, `double projectedYearEnd`, `double projectedVsLimit`
  (positive = projected over the annual limit).
- **Calculator** — in `FinanceCalculators.dollarSummary`, given `asOf`:
  `dayOfYear = asOf.difference(Jan 1).inDays + 1`;
  `pacePerDay = spentYtd / dayOfYear`;
  `projectedYearEnd = pacePerDay * daysInYear`;
  `projectedVsLimit = projectedYearEnd - annualLimit`.
- **UI**:
  - Dollar Tracker header card (`dollar_tracker/widgets/dollar_header_card.dart`):
    add a pacing line — `On pace for $X by Dec` + `· $Y over limit` (amber/coral)
    or `· $Z under` (green).
  - Dashboard `dollar_summary_card.dart`: same one-liner under the existing
    spent/remaining figures.
- Still fully isolated — reads only dollar data.

---

## Group 2

### 2.1 Schema migration v7

`app_database.dart`: `schemaVersion => 7`, add `onUpgrade` `if (from < 7)` block:

- `await m.createTable(categoryBudgetsTable);`
- `await m.addColumn(transactionTemplatesTable, transactionTemplatesTable.useCount);`
- `await m.addColumn(transactionTemplatesTable, transactionTemplatesTable.isMonthly);`

New table `data/database/tables/category_budgets_table.dart`:
```
class CategoryBudgetsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get categoryId => integer().unique()();
  RealColumn get monthlyLimit => real()();
}
```
(No FK constraint — matches the existing tables' style. Orphan rows for deleted
categories are ignored by the join and cleaned on category delete.)

`transaction_templates_table.dart` adds:
```
IntColumn get useCount => integer().withDefault(const Constant(0))();
BoolColumn get isMonthly => boolean().withDefault(const Constant(false))();
```

**Test** — `test/migration_test.dart` gains a v6→v7 case: seed a v6 DB with a
template and a transaction, upgrade, assert the template survives with
`useCount == 0` / `isMonthly == false`, the new table exists and is queryable,
and existing amounts/links are unchanged. Regenerate `drift` code
(`dart run build_runner build`).

### 2.2 Balance trend chart

- **Calculator** — `FinanceCalculators.balanceTrend({transactions, initialBalance, int months = 6, DateTime? asOf})`
  → `List<BalancePoint>` where
  `class BalancePoint { DateTime month; double total; double savings; double available; }`.
  Algorithm: sort transactions ascending by date; walk forward accumulating
  `total` (`+income −expense`) and `savings` (`+deposit −withdrawal`); at each
  month boundary within the trailing `months` window, snapshot
  `(total, savings, total − savings)` as the end-of-that-month value; carry the
  last known value forward for months with no transactions.
- **Widget** — `dashboard/widgets/balance_trend_chart.dart`: `fl_chart`
  `LineChart` with two stacked filled areas — Available (gold, `AppColors.teal`)
  on the bottom, Savings (purple, `AppColors.purple`) stacked on top so the top
  line reads as Total. X labels = month abbreviations, current month highlighted.
  Wrapped in a `GlassCard`, same header pattern as `SpendingChart`
  ("Balance Trend" / "6-month history" / no DETAILS link).
- **Provider** — `balanceTrendProvider` from `transactionsProvider` +
  `appSettingsProvider.initialBalance`.
- **Placement** — new card on the dashboard directly above `SpendingChart`.

### 2.3 Spending Velocity → rolling 12 months + income

- `spending_chart.dart` `_buildMonthSeries`: build 12 buckets ending with the
  current month (each keyed by year+month), not calendar Jan–Dec. Fixes the
  "blank chart on Jan 1" bug. `_MonthSpend` gains `double income`.
- Rendering: keep the single-color expense bar (gold). Add income per month as a
  second `BarChartRodData` in the same group — a thin 4px green rod at the
  income value, drawn beside (not stacked with) the expense rod so both are
  readable. Bottom labels show month abbreviations; when the window spans two
  years, December/January get a year tick.
- Tooltip shows both: `Spent ৳X · Earned ৳Y`.

### 2.4 Category icon + color + rename

- **Icon catalog** — replace the `switch` in `iconForCategoryKey` with a
  `CategoryIcons` catalog (`List<CategoryIconOption>` of ~16 lucide icons with
  keys), mirroring `GoalIcons`. `iconForCategoryKey` resolves through it and
  keeps the legacy keys (`restaurant`, `directions_car`, …) mapped for back-compat.
- **Color palette** — a fixed list of ~8 accent swatches drawn from `AppColors`
  (coral, green, purple, blue, amber, teal/gold, catHealth pink, a neutral).
- **DAO** — `CategoryDao.updateCategory(int id, {String? name, String? icon, int? color})`.
  On `deleteCategory`, also delete any `category_budgets` row for that id
  (add to the same method or the repository).
- **Manage Categories screen**:
  - Tapping a **custom** category row opens `_CategoryEditorSheet` — name field
    + icon grid + color swatches + Save. Delete stays on the trailing icon.
  - **Predefined** categories stay fully locked — no editor, no row tap (matches
    the current "Built-in" lock).
  - The "New category" dialog is replaced by `_CategoryEditorSheet` in create
    mode (name + icon + color, icon/color default to the first swatch).
- **Consumption**:
  - `transaction_tile.dart`: the icon chip for `expense` rows uses
    `Color(category.color)` instead of the flat `presentation.amountColor`; the
    amount text and left rail node stay type-colored. Income/savings rows
    unchanged.
  - `monthly_screen.dart` Category Details rows already read `category.icon` /
    `colorValue` via `MonthlyCategoryBreakdown` — verify they pick up the new
    values (they should, the breakdown copies from the row).
  - Dollar categories: same editor, reached from the DOLLAR CATEGORIES section.

### 2.5 Per-category budgets

- **DAO** — `data/database/daos/category_budget_dao.dart`:
  `watchAll()` → `Stream<List<CategoryBudgetsTableData>>`,
  `setBudget(int categoryId, double monthlyLimit)` (upsert on the unique
  `categoryId`), `clearBudget(int categoryId)`.
- **Repository/provider** — `categoryBudgetsProvider`
  (`StreamProvider<Map<int, double>>` keyed by categoryId).
- **Model** — `MonthlyCategoryBreakdown` gains `double? monthlyLimit`.
  `FinanceCalculators.monthlyAnalytics` joins the budget map when building the
  breakdown list.
- **UI** — `monthly/screens/monthly_screen.dart` Category Details row: when
  `monthlyLimit != null`, show `৳spent / ৳limit` and a 3px progress bar
  (gradient fill on a dark track, coral when `spent > limit`). Tapping the row
  opens a small amount sheet to set/edit/clear the budget. When no budget:
  a subtle "Set budget" affordance on the row (icon button, appears on the row,
  not a separate screen).
- The global `monthlyExpenseBudget` is unchanged and still shown as the overall
  cap at the top of the screen.

---

## Group 3

### 3.1 Goal contributions + Goal Detail + projection

- **Add contribution** — `goals/widgets/goal_card.dart` popup menu gains
  `GoalMenuAction.contribute`. Handler in `goals_screen.dart` opens a small
  amount sheet, then creates a `savings_deposit` transaction with
  `savingsGoalId = goal.id` **and** bumps `goal.currentAmount`, reusing the
  existing goal-linked-save path (`SavingsRepository` / the logic already in
  `add_transaction_sheet._saveTransaction`). If a contribution would exceed the
  target, clamp `currentAmount` to target and offer "mark complete".
- **Goal Detail screen** — new pushed route `AppRoute.goalDetail` (`/goal/:id`),
  `features/goals/screens/goal_detail_screen.dart`:
  - progress ring (reuse the goals-screen ring widget),
  - contribution history: `transactions` where `savingsGoalId == id`, newest
    first, each row = amount + date + note; withdrawals shown as negative.
  - projection card (see below).
  - Reached by tapping the goal card body (menu stays on the ⋮).
- **Projection** — `FinanceCalculators.goalProjection({goal, linkedTransactions, asOf})`
  → `class GoalProjection { double weeklyRate; DateTime? estimatedCompletion; double? requiredWeeklyForDeadline; }`.
  `weeklyRate` = net linked contributions ÷ weeks since first contribution
  (min 1 week). `estimatedCompletion` = `asOf + remaining / weeklyRate` weeks,
  `null` if `weeklyRate <= epsilon`. If `goal.deadline != null`:
  `requiredWeeklyForDeadline` = `remaining / weeksUntilDeadline`.
  Copy: "At ৳X/week, done ~Mar 2026" and/or "Add ৳Y/week to hit your deadline".

### 3.2 Templates — most-used chips + monthly checklist

- **Usage tracking** — `TransactionTemplateDao.markUsed(int id)` increments
  `useCount`. Called from `add_transaction_sheet._applyTemplate`.
- **Most-used chips** — `add_transaction_sheet.dart`: above the type selector, a
  horizontal wrap of up to 3 chips for the templates with the highest `useCount`
  (`useCount > 0`). Tapping applies the template (same as picking from the list).
  The existing "From Template" button stays for the full list. Hidden when there
  are no used templates.
- **Monthly flag** — `manage_templates_screen.dart`: each template row gets an
  "Expected monthly" switch → `TransactionTemplateDao.setMonthly(id, bool)`.
- **Expected this month card** — `dashboard/widgets/expected_this_month_card.dart`:
  - `expectedThisMonthProvider` returns monthly templates (`isMonthly == true`)
    that have **no** matching transaction in the current calendar month, where
    "matching" = same `type` **and** (same `categoryId` for expense/savings
    templates, or same `source` for income templates). Amount is not compared.
  - Card lists each: template name + expected amount (`— ` if the template has
    no amount) + a "Log" button. "Log" opens the Add sheet pre-filled from the
    template (does not auto-save — user confirms date/amount).
  - Card hidden when the list is empty or there are no monthly templates.
  - Placed on the dashboard below the balance card, above THIS MONTH.

### 3.3 Month-end recap

- **Calculator** — `FinanceCalculators.monthRecap({month, transactions, categoryBudgets, monthlyExpenseBudget, asOf})`
  → `class MonthRecap { DateTime month; double income; double expenses; double netSaved; double savingsRate; List<MonthlyCategoryBreakdown> topCategories; double? budgetDelta; double expenseVsPrevMonth; }`.
  Reuses `monthlyAnalytics` internally; `budgetDelta` = `monthlyExpenseBudget - expenses`
  when a budget is set (positive = under).
- **UI** — `dashboard/widgets/month_recap_card.dart`:
  - `monthRecapProvider` produces the recap for the **previous** month.
  - Shown only when `now.day <= 5` **and**
    `prefs.getString('recap_dismissed_month') != '<prevMonthKey>'`.
  - Content: "September recap" · "Saved ৳X (Y% of income)" · top 3 category
    chips · budget result line. A ✕ dismiss writes the month key to prefs.
  - Placed at the very top of the dashboard list (above the balance card) when
    visible.

### 3.4 Full JSON snapshot backup / restore

- **Service** — `data/repositories/snapshot_service.dart`:
  - `Future<String> exportJson()` — reads every table + the `AppSettings` and
    returns a JSON string:
    ```
    { "version": 1, "app": "spendsplit", "exportedAt": "<iso8601>",
      "settings": { biometricEnabled, dollarAnnualLimit, dollarLimitYear,
                    initialBalance, monthlyExpenseBudget, cardNumber },
      "categories": [...], "transactions": [...], "savingsGoals": [...],
      "dollarExpenses": [...], "transactionTemplates": [...],
      "categoryBudgets": [...] }
    ```
    Rows serialized via drift `toJson()`. Dates as ISO-8601.
  - `Future<SnapshotImportResult> importJson(String content)` — parse; reject if
    `version != 1` or `app != "spendsplit"`; then in **one** `db.transaction`:
    `delete` all rows from all six tables, re-insert every row from the JSON
    (preserving ids), and write settings back through `SettingsRepository`.
    Returns counts per table. Any failure rolls the transaction back.
- **UI** — `export/screens/export_data_screen.dart` gains a "FULL BACKUP"
  section below the CSV/PDF block:
  - "Export Backup (.json)" — writes to a temp file and shares via the existing
    share mechanism, then cleans up (same pattern as CSV export).
  - "Restore Backup" — file picker (`.json`) → confirmation dialog with a
    **hold-to-confirm** button ("Hold to replace everything") → `importJson` →
    success snackbar with counts, then `ref.invalidate` the data providers.
- Existing CSV export/import code is untouched.

### 3.5 CLAUDE.md — final pass

Add the Group 2/3 features to the **Features** section and update the schema
table count if anything shifted.

---

## Testing

- **Unit** (`test/finance_regression_test.dart` or new files):
  - `spendingRunway`: zero-spend → `daysRemaining == null`; known window → exact
    burn and days.
  - `balanceTrend`: reconstructs a known ledger to the right month-end values;
    carries forward empty months.
  - `dollarSummary` pacing: mid-year `spentYtd` → correct projection.
  - `goalProjection`: known contribution cadence → expected completion week;
    no contributions → `null`.
  - `monthRecap`: net saved, savings rate, top categories, budget delta.
  - rolling-12-month series: December→January rollover keeps 12 buckets.
- **Migration** — v6→v7 upgrade test (see 2.1).
- **Widget** — `MonthlySnapshotRow` fits 3 cards at 320dp with no overflow;
  `ExpectedThisMonthCard` hides when empty; snapshot import replaces data.
- **Device** — after each group: build the ARM64 debug APK, install on the
  connected phone, verify the changed screens visually, screenshot for the user.

## Non-goals

- No dashboard per-category budget widget (budgets live on Monthly only).
- No recurring-transaction engine, no notifications, no auto-logging of monthly
  templates.
- No merge-mode restore.
- No changes to the CSV/PDF export or the existing biometric/lock flow.
- No color, font, spacing-scale, or navbar changes.
