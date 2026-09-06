# SpendSplit Feature Expansion — Group 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship Group 1 of the feature expansion — CLAUDE.md reconciliation, five layout fixes, dashboard runway/burn-rate, and dollar-tracker pacing — then verify on device and push.

**Architecture:** Pure-Dart calculators in `FinanceCalculators` (unit-tested), exposed through Riverpod `Provider`s derived from existing stream providers, consumed by small widget edits. No schema changes in Group 1. No color/theme/spacing changes.

**Tech Stack:** Flutter, Riverpod, Drift (read-only here), fl_chart (untouched here), `flutter_test`.

## Global Constraints

- No color, font, spacing-scale, or navbar changes. Reuse `AppColors`, `AppDecorations`, `AppSpacing`, `AppTypography` exactly as they are.
- Dollar Tracker stays isolated — pacing code reads only `DollarExpensesTableData` + dollar settings, never BDT transactions.
- Every task ends with `flutter analyze` clean and `flutter test` green before its commit.
- Commit message trailer: `Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>`
- Currency formatting goes through `lib/core/utils/currency_formatter.dart` (`formatBdtAmount`, `formatCompactBdt`, `formatUsdAmount`) — never hand-format.
- Branch: `main` (the user has explicitly authorized committing and pushing to `main` for this work).
- Build for device: `flutter build apk --debug --target-platform android-arm64`; device id `RFGYB295FHB`.

---

### Task 1: CLAUDE.md reconciliation

**Files:**
- Modify: `CLAUDE.md`

**Interfaces:**
- Consumes: nothing
- Produces: nothing (docs only)

- [ ] **Step 1: Rewrite the "Design System Rules" section**

Replace the `### Dark Theme Only` bullet list with:

```markdown
### Dark Theme Only
- Base void: pure black `#000000` (`AppColors.background`). The earlier
  "never use #000000" rule was deliberately overridden — the app is OLED black.
- Card surfaces: `#15131F` (`AppColors.surface`), elevated `#1E1A2C`
  (`AppColors.surfaceLight`). Faintly purple-tinted charcoal.
- All UI is dark theme. No light mode toggle.
```

Replace the `### Color Accents` list with:

```markdown
### Color Accents (see `lib/core/theme/app_colors.dart`)
- **Gold** `#ECBB7E` (`AppColors.teal`) — primary actions, available balance, active nav, chart bars
- **Coral** `#F26D3D` (`AppColors.coral`) — expenses, negative amounts, delete
- **Green** `#34D89C` (`AppColors.green`) — income, positive amounts
- **Purple** `#9B8BFF` (`AppColors.purple`) — savings, goal progress
- **Amber** `#ECB877` (`AppColors.amber`) — warnings, deadlines, dollar ring
- **Violet** `#7A46E0` (`AppColors.blue`) — charts, secondary highlights, links
```

Replace the `### Typography` first bullet:

```markdown
- Use Google Fonts **Manrope** (see `lib/core/theme/app_typography.dart`)
```

Replace the `### Cards & Components` "Pill-shaped bottom nav bar" bullet:

```markdown
- Bottom nav: a floating frosted-glass pill (radius 28), no border — a strong
  backdrop blur with a saturation matrix composed on top, a faint white sheen,
  and a soft outer shadow. Tint `#16121F`. Content scrolls behind it; pages
  reserve `AppSpacing.navClearance` at the bottom.
```

- [ ] **Step 2: Fix the Navigation Structure section**

Under the nav tree add:

```markdown
Tab indices: dashboard 0, transactions 1, add 2 (sheet — no route), monthly 3, goals 4.
```

- [ ] **Step 3: Fix the Database Schema section**

Replace the "Four tables" line with:

```markdown
Five tables: `transactions_table`, `categories_table`, `savings_goals_table`,
`dollar_expenses_table`, `transaction_templates_table`.
Settings via SharedPreferences: `biometric_enabled`, `dollar_annual_limit`,
`dollar_limit_year`, `initial_balance`, `monthly_expense_budget`, `card_number`.
```

- [ ] **Step 4: Fix "What NOT to Implement"**

Remove the lines `- Export to CSV/PDF` and `- Home screen widgets` (both are
shipped). Keep the rest. Append:

```markdown

> Recurring transactions remain unimplemented; the monthly-template checklist
> (see Features) is the lightweight substitute. CSV/PDF export, CSV import, and
> the Android home-screen widget are already built.
```

- [ ] **Step 5: Soften the "When Building UI" section**

Replace rule 1 with:

```markdown
1. The `asset/stitch_*` PNGs and `asset/DESIGN.md` are **historical** reference —
   the live design (pure-black, frosted glass, Manrope) has deliberately moved
   past them. Match the current in-app style; treat the mockups as directional.
```

- [ ] **Step 6: Add a Features section**

After "Critical Implementation Rules", add:

```markdown
---

## Features

- **Runway** — dashboard shows how many days Available lasts at the trailing
  30-day expense burn rate.
- **Balance trend** — 6-month reconstructed Available/Savings area chart.
- **Spending Velocity** — rolling 12-month expense bars with an income overlay.
- **Category budgets** — optional per-category monthly limits, shown on Monthly.
- **Goal contributions** — log a deposit against a goal; goal detail screen with
  contribution history and a completion projection.
- **Dollar pacing** — projected year-end USD spend vs. the annual limit.
- **Month-end recap** — dismissible dashboard card (days 1–5) summarising the
  prior month.
- **Template checklist** — templates flagged "monthly" that haven't been logged
  yet this month surface on the dashboard.
- **JSON snapshot backup** — full export/restore of all data (Export screen).
```

- [ ] **Step 7: Verify and commit**

Run: `git diff --stat CLAUDE.md`
Expected: only `CLAUDE.md` changed.

```bash
git add CLAUDE.md
git commit -m "docs: reconcile CLAUDE.md with shipped theme and features

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

### Task 2: Layout — THIS MONTH row fits three cards

**Files:**
- Modify: `lib/features/dashboard/widgets/monthly_snapshot_row.dart`
- Test: `test/widget_test.dart` (add a case)

**Interfaces:**
- Consumes: `MonthlyFinanceSummary` (unchanged)
- Produces: `MonthlySnapshotRow({required MonthlyFinanceSummary summary})` — unchanged public API

- [ ] **Step 1: Write the failing widget test**

Add to `test/widget_test.dart`:

```dart
  testWidgets('MonthlySnapshotRow shows all three cards with no overflow at 320dp', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MonthlySnapshotRow(
            summary: MonthlyFinanceSummary(
              month: DateTime(2026, 9),
              income: 77000,
              expenses: 12345,
              saved: 5000,
            ),
          ),
        ),
      ),
    );
    expect(find.text('INCOME'), findsOneWidget);
    expect(find.text('SPENT'), findsOneWidget);
    expect(find.text('SAVED'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
```

Add imports at the top of the test file if missing:
`import 'package:spendsplit/features/dashboard/widgets/monthly_snapshot_row.dart';`
`import 'package:spendsplit/data/models/financial_summaries.dart';`

- [ ] **Step 2: Run the test, confirm it fails**

Run: `flutter test test/widget_test.dart -p vm --plain-name "MonthlySnapshotRow shows all three"`
Expected: FAIL — a `RenderFlex` overflow exception from the horizontal `ListView` cards, or the row renders off-screen.

- [ ] **Step 3: Replace the horizontal ListView with a fixed 3-up Row**

In `monthly_snapshot_row.dart`, replace the `SizedBox(height: 126, child: ListView(...))` block with:

```dart
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _SnapshotCard(
                  label: 'INCOME',
                  rawAmount: summary.income,
                  icon: LucideIcons.trendingUp,
                  color: AppColors.green,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SnapshotCard(
                  label: 'SPENT',
                  rawAmount: summary.expenses,
                  icon: LucideIcons.trendingDown,
                  color: AppColors.coral,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SnapshotCard(
                  label: 'SAVED',
                  rawAmount: summary.saved,
                  icon: LucideIcons.piggyBank,
                  color: AppColors.purple,
                ),
              ),
            ],
          ),
        ),
```

In `_SnapshotCard.build`, remove the outer `SizedBox(width: 136, child: ...)` wrapper so the card fills its `Expanded` slot — return the `GlassCard(...)` directly. Reduce its inner horizontal padding from `16` to `12` and the icon container from `38` to `34` so three fit at 320dp. Change the amount `AnimatedAmountText` `textStyle` from `titleMedium` to `titleSmall` and add `maxLines: 1` on it if not present.

- [ ] **Step 4: Run the test, confirm it passes**

Run: `flutter test test/widget_test.dart -p vm --plain-name "MonthlySnapshotRow shows all three"`
Expected: PASS.

- [ ] **Step 5: Full test + analyze**

Run: `flutter test && flutter analyze`
Expected: all green, no issues.

- [ ] **Step 6: Commit**

```bash
git add lib/features/dashboard/widgets/monthly_snapshot_row.dart test/widget_test.dart
git commit -m "fix(dashboard): THIS MONTH row fits three cards, no horizontal scroll

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

### Task 3: Layout — Monthly budget empty-state prompt

**Files:**
- Modify: `lib/features/monthly/widgets/monthly_budget_card.dart`

**Interfaces:**
- Consumes: `appSettingsProvider` (unchanged), `MonthlyBudgetCard({required double spent})`
- Produces: unchanged public API

- [ ] **Step 1: Return a compact prompt when no budget is set**

In `monthly_budget_card.dart` `build`, immediately after computing
`final enabled = budget > 0;`, add:

```dart
    if (!enabled) {
      return GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => showDialog<void>(
            context: context,
            builder: (_) => _BudgetDialog(initialBudget: budget),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.target, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Set a monthly spending limit',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const Icon(LucideIcons.chevronRight, size: 18, color: AppColors.textSecondary),
            ],
          ),
        ),
      );
    }
```

Add the import `import 'package:spendsplit/core/icons/lucide_icons.dart';` if not
already present. The existing full-card body below stays for the `enabled` case.

- [ ] **Step 2: Analyze + test**

Run: `flutter analyze && flutter test`
Expected: no issues; `test/widget_test.dart` "budget reports overspending and persists an edit" still passes (it sets an initial budget, so it hits the `enabled` path).

- [ ] **Step 3: Commit**

```bash
git add lib/features/monthly/widgets/monthly_budget_card.dart
git commit -m "fix(monthly): collapse unset budget card to a one-line prompt

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

### Task 4: Layout — Completed Goals collapsed + banner pluralization

**Files:**
- Modify: `lib/features/goals/screens/goals_screen.dart`
- Modify: `lib/features/goals/widgets/total_savings_banner.dart:150`

**Interfaces:**
- Consumes / Produces: unchanged

- [ ] **Step 1: Collapse the Completed Goals section by default**

In `goals_screen.dart` around line 186–260 the completed-goals section is a
custom expand/collapse driven by an `onTap` and a boolean. Find the state field
backing it (a `bool _showCompleted` / `_completedExpanded` in
`_GoalsScreenState`) and set its initializer to `false`. If it is an
`ExpansionTile`, add `initiallyExpanded: false`. If the section is always-shown
with no collapse, wrap the completed list (the `for (var i = 0; ...)` loop at
line 251) in an `AnimatedCrossFade` / simple `if (_completedExpanded)` gated by
a new `bool _completedExpanded = false;` field, with the header row (line ~220)
toggling it via `setState`.

- [ ] **Step 2: Pluralize the active-goal count**

`total_savings_banner.dart:150` — replace:

```dart
                'Across $activeGoalCount active goals',
```
with:
```dart
                'Across $activeGoalCount active goal${activeGoalCount == 1 ? '' : 's'}',
```

- [ ] **Step 3: Analyze + test**

Run: `flutter analyze && flutter test`
Expected: green.

- [ ] **Step 4: Commit**

```bash
git add lib/features/goals/screens/goals_screen.dart lib/features/goals/widgets/total_savings_banner.dart
git commit -m "fix(goals): collapse completed goals by default, pluralize active count

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

### Task 5: Runway calculator + model + unit tests

**Files:**
- Modify: `lib/data/models/financial_summaries.dart`
- Test: `test/finance_regression_test.dart`

**Interfaces:**
- Consumes: `List<TransactionsTableData>` (drift row, has `.type` String, `.amount` double, `.date` DateTime)
- Produces:
  - `class SpendingRunway { final double avgDailyBurn; final int? daysRemaining; final int windowDays; const SpendingRunway({required this.avgDailyBurn, required this.daysRemaining, required this.windowDays}); }`
  - `static SpendingRunway FinanceCalculators.spendingRunway({required Iterable<TransactionsTableData> transactions, required double availableBalance, DateTime? asOf, int windowDays = 30})`

- [ ] **Step 1: Write the failing tests**

Add to `test/finance_regression_test.dart` (it already imports the drift DB and
`FinanceCalculators`; follow the existing pattern for building
`TransactionsTableData` rows — check the top of the file for a helper like
`_tx(...)` and reuse it, otherwise construct `TransactionsTableData(...)`
directly with `id`, `type`, `amount`, `categoryId: null`, `savingsGoalId: null`,
`source: null`, `note: null`, `date`, `createdAt: date`):

```dart
  group('spendingRunway', () {
    final asOf = DateTime(2026, 9, 30);

    test('no expenses in window -> daysRemaining is null', () {
      final runway = FinanceCalculators.spendingRunway(
        transactions: [
          _expense(amount: 500, date: DateTime(2026, 1, 1)), // outside 30d window
          _income(amount: 9000, date: DateTime(2026, 9, 10)),
        ],
        availableBalance: 20000,
        asOf: asOf,
      );
      expect(runway.avgDailyBurn, 0);
      expect(runway.daysRemaining, isNull);
    });

    test('computes burn and days from trailing 30 days of expenses only', () {
      final runway = FinanceCalculators.spendingRunway(
        transactions: [
          _expense(amount: 3000, date: DateTime(2026, 9, 5)),
          _expense(amount: 3000, date: DateTime(2026, 9, 20)),
          _income(amount: 50000, date: DateTime(2026, 9, 15)), // ignored
          _savingsDeposit(amount: 10000, date: DateTime(2026, 9, 15)), // ignored
        ],
        availableBalance: 30000,
        asOf: asOf,
        windowDays: 30,
      );
      // 6000 / 30 = 200/day ; 30000 / 200 = 150 days
      expect(runway.avgDailyBurn, closeTo(200, 1e-6));
      expect(runway.daysRemaining, 150);
    });

    test('negative available balance -> daysRemaining 0', () {
      final runway = FinanceCalculators.spendingRunway(
        transactions: [_expense(amount: 3000, date: DateTime(2026, 9, 10))],
        availableBalance: -100,
        asOf: asOf,
      );
      expect(runway.daysRemaining, 0);
    });
  });
```

If the file has no `_expense` / `_income` / `_savingsDeposit` helpers, add them
near the top:

```dart
TransactionsTableData _mkTx(String type, double amount, DateTime date) =>
    TransactionsTableData(
      id: date.microsecondsSinceEpoch % 100000000,
      type: type,
      amount: amount,
      categoryId: null,
      savingsGoalId: null,
      source: null,
      note: null,
      date: date,
      createdAt: date,
    );
TransactionsTableData _expense({required double amount, required DateTime date}) =>
    _mkTx('expense', amount, date);
TransactionsTableData _income({required double amount, required DateTime date}) =>
    _mkTx('income', amount, date);
TransactionsTableData _savingsDeposit({required double amount, required DateTime date}) =>
    _mkTx('savings_deposit', amount, date);
```

- [ ] **Step 2: Run the tests, confirm they fail**

Run: `flutter test test/finance_regression_test.dart --plain-name spendingRunway`
Expected: FAIL — `spendingRunway` / `SpendingRunway` not defined.

- [ ] **Step 3: Add the model and calculator**

In `financial_summaries.dart`, add after the `SavingsInsights` class:

```dart
class SpendingRunway {
  const SpendingRunway({
    required this.avgDailyBurn,
    required this.daysRemaining,
    required this.windowDays,
  });

  final double avgDailyBurn;

  /// Whole days of Available left at [avgDailyBurn]. Null when there is no
  /// recent spending to project from.
  final int? daysRemaining;
  final int windowDays;
}
```

In `FinanceCalculators`, add:

```dart
  static SpendingRunway spendingRunway({
    required Iterable<TransactionsTableData> transactions,
    required double availableBalance,
    DateTime? asOf,
    int windowDays = 30,
  }) {
    final now = asOf ?? DateTime.now();
    final windowStart = now.subtract(Duration(days: windowDays));
    final recentExpense = transactions
        .where(
          (t) =>
              t.type == 'expense' &&
              t.date.isAfter(windowStart) &&
              !t.date.isAfter(now),
        )
        .fold<double>(0, (sum, t) => sum + t.amount);

    final avgDailyBurn = recentExpense / windowDays;
    if (avgDailyBurn <= _epsilon) {
      return SpendingRunway(
        avgDailyBurn: 0,
        daysRemaining: null,
        windowDays: windowDays,
      );
    }
    final days = availableBalance <= 0
        ? 0
        : (availableBalance / avgDailyBurn).floor();
    return SpendingRunway(
      avgDailyBurn: avgDailyBurn,
      daysRemaining: days,
      windowDays: windowDays,
    );
  }
```

- [ ] **Step 4: Run the tests, confirm they pass**

Run: `flutter test test/finance_regression_test.dart --plain-name spendingRunway`
Expected: PASS (3 tests).

- [ ] **Step 5: Full suite + analyze**

Run: `flutter test && flutter analyze`
Expected: green.

- [ ] **Step 6: Commit**

```bash
git add lib/data/models/financial_summaries.dart test/finance_regression_test.dart
git commit -m "feat(dashboard): spendingRunway calculator (trailing-30d burn rate)

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

### Task 6: Runway provider

**Files:**
- Modify: `lib/providers/providers.dart`

**Interfaces:**
- Consumes: `transactionsProvider` (`StreamProvider<List<TransactionsTableData>>`), `balanceSummaryProvider` (`Provider<AsyncValue<BalanceSummary>>`), `FinanceCalculators.spendingRunway`
- Produces: `final spendingRunwayProvider = Provider<AsyncValue<SpendingRunway>>((ref) {...})`

- [ ] **Step 1: Add the provider**

In `providers.dart`, near `savingsInsightsProvider`, add:

```dart
final spendingRunwayProvider = Provider<AsyncValue<SpendingRunway>>((ref) {
  final transactions = ref.watch(transactionsProvider);
  final balance = ref.watch(balanceSummaryProvider);

  return transactions.when(
    loading: () => const AsyncValue.loading(),
    error: AsyncValue.error,
    data: (entries) => balance.whenData(
      (summary) => FinanceCalculators.spendingRunway(
        transactions: entries,
        availableBalance: summary.availableBalance,
      ),
    ),
  );
});
```

Confirm `SpendingRunway` is exported via the existing
`import '../data/models/financial_summaries.dart';` in that file (it is — same
file as `SavingsInsights`).

- [ ] **Step 2: Analyze**

Run: `flutter analyze`
Expected: no issues.

- [ ] **Step 3: Commit**

```bash
git add lib/providers/providers.dart
git commit -m "feat(dashboard): spendingRunwayProvider

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

### Task 7: Runway line + AVAILABLE emphasis on the balance card

**Files:**
- Modify: `lib/features/dashboard/widgets/balance_card.dart`

**Interfaces:**
- Consumes: `spendingRunwayProvider`
- Produces: unchanged public API — `BalanceCard` becomes a `ConsumerWidget` (it is currently `StatelessWidget`)

- [ ] **Step 1: Convert BalanceCard to ConsumerWidget**

Add `import 'package:flutter_riverpod/flutter_riverpod.dart';` and
`import '../../../providers/providers.dart';`. Change
`class BalanceCard extends StatelessWidget` → `extends ConsumerWidget`, and
`Widget build(BuildContext context)` → `Widget build(BuildContext context, WidgetRef ref)`.

- [ ] **Step 2: Enlarge the AVAILABLE amount and add the runway line**

In `_BalanceSegment` (the widget rendering AVAILABLE / SAVINGS), it currently
uses `theme.textTheme.headlineMedium` for the amount. Add a `bool emphasize`
field (default `false`); when `true`, use
`headlineMedium?.copyWith(fontSize: 26)`. Pass `emphasize: true` from the
AVAILABLE `_BalanceSegment(...)` call only.

Below the AVAILABLE segment's `AnimatedAmountText`, when `emphasize` is true,
render a runway line. To keep `_BalanceSegment` a plain widget, instead do this
in `BalanceCard.build`: wrap the existing AVAILABLE `Expanded(...)` column so a
`_RunwayLine(ref)` sits under it:

```dart
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 12, right: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _BalanceSegment(
                        label: 'AVAILABLE',
                        amount: summary.availableBalance,
                        color: AppColors.teal,
                        alignEnd: false,
                        emphasize: true,
                      ),
                      const SizedBox(height: 4),
                      _RunwayLine(runway: ref.watch(spendingRunwayProvider)),
                    ],
                  ),
                ),
              ),
```

- [ ] **Step 3: Add the _RunwayLine widget**

At the bottom of `balance_card.dart`:

```dart
class _RunwayLine extends StatelessWidget {
  const _RunwayLine({required this.runway});

  final AsyncValue<SpendingRunway> runway;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall;
    return runway.maybeWhen(
      orElse: () => const SizedBox(height: 14),
      data: (r) {
        if (r.daysRemaining == null) {
          return Text(
            'No recent spending',
            style: style?.copyWith(color: AppColors.textTertiary),
          );
        }
        final tight = r.daysRemaining! < 14;
        return Text(
          '~${r.daysRemaining} days left · ${formatCompactBdt(r.avgDailyBurn)}/day',
          style: style?.copyWith(
            color: tight ? AppColors.coral : AppColors.textSecondary,
          ),
        );
      },
    );
  }
}
```

Add `import '../../../data/models/financial_summaries.dart';` if not present
(for `SpendingRunway`). `formatCompactBdt` comes from the already-imported
`currency_formatter.dart`.

- [ ] **Step 4: Analyze + test**

Run: `flutter analyze && flutter test`
Expected: green. If a widget test pumps `BalanceCard` without a `ProviderScope`
it will now throw — search `test/` for `BalanceCard`; there are none at time of
writing, so no fix needed. Confirm with `grep -rn BalanceCard test/`.

- [ ] **Step 5: Commit**

```bash
git add lib/features/dashboard/widgets/balance_card.dart
git commit -m "feat(dashboard): runway line under AVAILABLE, larger AVAILABLE figure

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

### Task 8: Dollar-tracker pacing — model + calculator + tests

**Files:**
- Modify: `lib/data/models/financial_summaries.dart`
- Test: `test/finance_regression_test.dart`

**Interfaces:**
- Consumes: `Iterable<DollarExpensesTableData>` (`.amount` double, `.date` DateTime), `annualLimit`, `year`
- Produces: `DollarTrackerSummary` gains `final double pacePerDay; final double projectedYearEnd; final double projectedVsLimit;` (all required in the const ctor); `dollarSummary` gains an optional `DateTime? asOf` param.

- [ ] **Step 1: Write failing tests**

Add to `test/finance_regression_test.dart`:

```dart
  group('dollarSummary pacing', () {
    test('projects year-end from ytd spend at day-of-year rate', () {
      // 2026 is not a leap year -> 365 days. asOf = day 100 (Apr 10).
      final asOf = DateTime(2026, 4, 10);
      final summary = FinanceCalculators.dollarSummary(
        expenses: [
          _dollar(amount: 300, date: DateTime(2026, 2, 1)),
          _dollar(amount: 200, date: DateTime(2026, 3, 1)),
          _dollar(amount: 100, date: DateTime(2025, 12, 1)), // prior year, ignored
        ],
        annualLimit: 1000,
        year: 2026,
        asOf: asOf,
      );
      // spentYtd 500 over 100 days -> 5/day -> * 365 = 1825 projected
      expect(summary.spentYtd, 500);
      expect(summary.pacePerDay, closeTo(5, 1e-6));
      expect(summary.projectedYearEnd, closeTo(1825, 1e-3));
      expect(summary.projectedVsLimit, closeTo(825, 1e-3)); // over by 825
    });

    test('zero ytd spend -> zero projection', () {
      final summary = FinanceCalculators.dollarSummary(
        expenses: const [],
        annualLimit: 1000,
        year: 2026,
        asOf: DateTime(2026, 6, 1),
      );
      expect(summary.pacePerDay, 0);
      expect(summary.projectedYearEnd, 0);
      expect(summary.projectedVsLimit, -1000);
    });
  });
```

Add a `_dollar` helper if none exists:

```dart
DollarExpensesTableData _dollar({required double amount, required DateTime date}) =>
    DollarExpensesTableData(
      id: date.microsecondsSinceEpoch % 100000000,
      amount: amount,
      purpose: 'test',
      categoryId: 0,
      date: date,
      createdAt: date,
    );
```

- [ ] **Step 2: Run tests, confirm fail**

Run: `flutter test test/finance_regression_test.dart --plain-name "dollarSummary pacing"`
Expected: FAIL — named param `asOf` / getters not defined.

- [ ] **Step 3: Extend the model and calculator**

In `financial_summaries.dart` `DollarTrackerSummary`: add the three fields to the
class and the `const` constructor (all `required`).

Replace `dollarSummary` with:

```dart
  static DollarTrackerSummary dollarSummary({
    required Iterable<DollarExpensesTableData> expenses,
    required double annualLimit,
    required int year,
    DateTime? asOf,
  }) {
    final spentYtd = expenses
        .where((expense) => expense.date.year == year)
        .fold<double>(0, (sum, expense) => sum + expense.amount);

    final now = asOf ?? DateTime.now();
    final refInYear = now.year == year
        ? now
        : (now.year > year ? DateTime(year, 12, 31) : DateTime(year, 1, 1));
    final dayOfYear = refInYear.difference(DateTime(year)).inDays + 1;
    final daysInYear = DateTime(year + 1).difference(DateTime(year)).inDays;
    final pacePerDay = dayOfYear <= 0 ? 0.0 : spentYtd / dayOfYear;
    final projectedYearEnd = pacePerDay * daysInYear;

    return DollarTrackerSummary(
      year: year,
      annualLimit: annualLimit,
      spentYtd: spentYtd,
      remaining: annualLimit - spentYtd,
      pacePerDay: pacePerDay,
      projectedYearEnd: projectedYearEnd,
      projectedVsLimit: projectedYearEnd - annualLimit,
    );
  }
```

- [ ] **Step 4: Run tests, confirm pass**

Run: `flutter test test/finance_regression_test.dart --plain-name "dollarSummary pacing"`
Expected: PASS.

- [ ] **Step 5: Full suite + analyze**

Run: `flutter test && flutter analyze`
Expected: green. The two providers calling `dollarSummary`
(`dollarTrackerSummaryProvider`, `dollarTrackerSummaryForYearProvider`) don't
pass `asOf` — fine, it defaults. Any other `DollarTrackerSummary(...)`
construction sites will now fail to compile — `grep -rn "DollarTrackerSummary(" lib`
and add the three fields (there should be none outside the calculator).

- [ ] **Step 6: Commit**

```bash
git add lib/data/models/financial_summaries.dart test/finance_regression_test.dart
git commit -m "feat(dollar): year-end pace projection on DollarTrackerSummary

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

### Task 9: Dollar pacing UI

**Files:**
- Modify: `lib/features/dollar_tracker/widgets/dollar_header_card.dart`
- Modify: `lib/features/dashboard/widgets/dollar_summary_card.dart`

**Interfaces:**
- Consumes: `DollarTrackerSummary.projectedYearEnd`, `.projectedVsLimit`
- Produces: unchanged public APIs

- [ ] **Step 1: Add a pacing line to the dollar header card**

In `dollar_header_card.dart`, inside the left `Column`, after the metric row
(`ANNUAL LIMIT` / `SPENT YTD`), add:

```dart
                    const SizedBox(height: 14),
                    Text(
                      _paceText(summary),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: summary.projectedVsLimit > 0
                            ? AppColors.amber
                            : AppColors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
```

Add a top-level helper in the same file:

```dart
String _paceText(DollarTrackerSummary s) {
  if (s.spentYtd <= 0) return 'No spending yet this year';
  final projected = formatUsdAmount(s.projectedYearEnd, fractionDigits: 0);
  final diff = formatUsdAmount(s.projectedVsLimit.abs(), fractionDigits: 0);
  final verb = s.projectedVsLimit > 0 ? 'over' : 'under';
  return 'On pace for $projected by Dec · $diff $verb limit';
}
```

- [ ] **Step 2: Add the same line to the dashboard dollar card**

In `dollar_summary_card.dart`, after the spent/remaining figures Column, add a
`Text` with the same `_paceText(summary)` (duplicate the small helper at the
bottom of this file — the plan permits this; they are one line and the files are
in different features). Style: `textTheme.labelSmall` in
`AppColors.textSecondary`, or amber when `summary.projectedVsLimit > 0`. Only
render when `summary.spentYtd > 0`.

- [ ] **Step 3: Analyze + test**

Run: `flutter analyze && flutter test`
Expected: green.

- [ ] **Step 4: Commit**

```bash
git add lib/features/dollar_tracker/widgets/dollar_header_card.dart lib/features/dashboard/widgets/dollar_summary_card.dart
git commit -m "feat(dollar): show year-end pace on header and dashboard cards

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

### Task 10: Device verification + push Group 1

**Files:** none (verification only)

- [ ] **Step 1: Build the debug APK**

Run: `flutter build apk --debug --target-platform android-arm64`
Expected: `✓ Built build/app/outputs/flutter-apk/app-debug.apk`

- [ ] **Step 2: Install and launch**

```bash
adb -s RFGYB295FHB install -r build/app/outputs/flutter-apk/app-debug.apk
adb -s RFGYB295FHB shell am force-stop com.example.spendsplit
adb -s RFGYB295FHB shell am start -n com.example.spendsplit/.MainActivity
```

If the app is biometric-locked, ask the user to unlock (they may have disabled
the lock — check first with a screenshot).

- [ ] **Step 3: Screenshot and eyeball each changed surface**

- Dashboard: AVAILABLE larger, runway line present and plausible, dollar card
  pace line.
- Dashboard THIS MONTH: three cards, nothing clipped (also check landscape /
  small width if possible).
- Monthly: budget prompt is a single line when unset; full card once set.
- Goals: completed section collapsed on entry; "active goal" singular when count
  is 1.
- Dollar Tracker screen: header pace line.

Capture with `adb -s RFGYB295FHB exec-out screencap -p > <scratch>/g1_<name>.png`
and send the key ones to the user with `SendUserFile`.

- [ ] **Step 4: Final analyze + full test**

Run: `flutter analyze && flutter test`
Expected: `No issues found!`, `All tests passed!`

- [ ] **Step 5: Push**

```bash
git push origin main
```

Report the pushed commit range to the user and confirm Group 1 is live, then
stop — Group 2 gets its own plan.

---

## Self-Review

**Spec coverage (Group 1 portion of the spec):**
- 1.1 CLAUDE.md reconciliation → Task 1 ✓
- 1.2a THIS MONTH row → Task 2 ✓
- 1.2b Monthly budget empty state → Task 3 ✓
- 1.2c Completed goals collapsed → Task 4 ✓
- 1.2d Pluralization → Task 4 ✓
- 1.2e AVAILABLE emphasis → Task 7 ✓
- 1.3 Runway calculator/model/provider/UI → Tasks 5, 6, 7 ✓
- 1.4 Dollar pacing model/calculator/UI → Tasks 8, 9 ✓
- Device verify + push → Task 10 ✓

**Placeholder scan:** Task 4 Step 1 is conditional ("if it is an ExpansionTile… if the section is always-shown…") because the exact widget wasn't read — the executor must read `goals_screen.dart:180-260` first and apply whichever branch matches. This is a read-then-act instruction, not a placeholder. All code steps have concrete code.

**Type consistency:** `SpendingRunway` fields (`avgDailyBurn`, `daysRemaining`, `windowDays`) are consistent across Tasks 5/6/7. `DollarTrackerSummary` new fields (`pacePerDay`, `projectedYearEnd`, `projectedVsLimit`) consistent across Tasks 8/9. `spendingRunwayProvider` type `Provider<AsyncValue<SpendingRunway>>` consistent between Task 6 (definition) and Task 7 (consumption).

**Known risk:** the exact constructor signature of `TransactionsTableData` / `DollarExpensesTableData` in the test helpers (Tasks 5, 8) depends on generated drift code — the executor must open `lib/data/database/app_database.g.dart` and match the actual required/named params before running the test. Flagged in each task's Interfaces block.
