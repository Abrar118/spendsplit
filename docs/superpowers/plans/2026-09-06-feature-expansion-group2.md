# SpendSplit Feature Expansion — Group 2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship Group 2 of the feature expansion — schema v7 (category budgets table + template columns), per-category monthly budgets on the Monthly screen, category icon/color/rename editor, a dashboard balance-trend chart, and a rolling-12-month Spending Velocity chart with income — then verify on device and push.

**Architecture:** One additive Drift migration (v6 → v7) carrying every column/table Groups 2 **and** 3 need. New pure-Dart calculators in `FinanceCalculators` (unit-tested), exposed through Riverpod providers derived from existing stream providers, consumed by small widget edits and two new chart widgets. Category metadata (icon/color/name) becomes editable for custom categories only; predefined categories stay locked.

**Tech Stack:** Flutter, Riverpod, Drift (SQLite) with `dart run build_runner build`, fl_chart, `flutter_test`.

## Global Constraints

- **No color, font, spacing-scale, or navbar changes.** Reuse `AppColors`, `AppDecorations`, `AppSpacing`, `AppTypography` exactly as they are. New chart series pick from the existing accent set (`AppColors.teal` gold, `AppColors.purple`, `AppColors.green`, `AppColors.coral`, `AppColors.amber`, `AppColors.blue` deep violet).
- **Additive schema migration only.** No existing rows mutated. `onUpgrade` gets one new `if (from < 7)` block; every other block is untouched. Ship a v6→v7 regression test matching the existing v5→v6 test style.
- **Dollar Tracker stays isolated** — none of the new BDT calculators or charts read `DollarExpensesTableData`. The category editor's DOLLAR CATEGORIES section edits dollar-category rows only (no cross-contamination with BDT math).
- **Predefined categories are fully locked** — no rename, no icon/color edit, no row tap. Only `isPredefined == false` categories get the editor.
- Every task ends with `flutter analyze` clean and `flutter test` green before its commit.
- After any change to a Drift table or DAO: run `dart run build_runner build --delete-conflicting-outputs` and stage the regenerated `.g.dart` files in the same commit.
- Currency formatting goes through `lib/core/utils/currency_formatter.dart` (`formatBdtAmount`, `formatCompactBdt`) — never hand-format. `formatBdtAmount(num, {int fractionDigits = 0})`, `formatCompactBdt(num)`.
- Commit message trailer:
  ```
  Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
  ```
- Branch: `main` (the user has explicitly authorized committing and pushing to `main` for this work).
- Build for device: `flutter build apk --debug --target-platform android-arm64`; device id `RFGYB295FHB`; package `com.example.spendsplit/.MainActivity`.

---

### Task 1: Schema v7 — category_budgets table + template columns + migration + regen + test

**Files:**
- Create: `lib/data/database/tables/category_budgets_table.dart`
- Modify: `lib/data/database/tables/transaction_templates_table.dart`
- Modify: `lib/data/database/app_database.dart` (imports, `@DriftDatabase` tables list, `schemaVersion`, `onUpgrade`)
- Regenerate: `lib/data/database/app_database.g.dart`
- Test: `test/migration_test.dart` (add a second `test(...)` case)

**Interfaces:**
- Consumes: nothing (first task).
- Produces:
  - Table class `CategoryBudgetsTable` with columns `id` (int, autoIncrement), `categoryId` (int, `.unique()`), `monthlyLimit` (real).
  - Generated `CategoryBudgetsTableData({required int id, required int categoryId, required double monthlyLimit})` and `CategoryBudgetsTableCompanion.insert({required int categoryId, required double monthlyLimit, Value<int> id})`.
  - Generated accessor `db.categoryBudgetsTable` on `AppDatabase`.
  - `TransactionTemplatesTableData` gains `final int useCount;` and `final bool isMonthly;` (both non-null, defaulted).
  - `schemaVersion => 7`.

- [ ] **Step 1: Create the category budgets table class**

Create `lib/data/database/tables/category_budgets_table.dart`:

```dart
import 'package:drift/drift.dart';

class CategoryBudgetsTable extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// One budget per category. No FK constraint — matches the other tables'
  /// style; orphan rows for deleted categories are ignored by joins and
  /// cleaned up when a category is deleted.
  IntColumn get categoryId => integer().unique()();

  RealColumn get monthlyLimit => real()();
}
```

- [ ] **Step 2: Add the two template columns**

In `lib/data/database/tables/transaction_templates_table.dart`, add inside the class after `createdAt`:

```dart
  IntColumn get useCount => integer().withDefault(const Constant(0))();
  BoolColumn get isMonthly => boolean().withDefault(const Constant(false))();
```

- [ ] **Step 3: Register the table and bump the schema version**

In `lib/data/database/app_database.dart`:

1. Add the import next to the other `tables/` imports:
   ```dart
   import 'tables/category_budgets_table.dart';
   ```
2. Add `CategoryBudgetsTable` to the `@DriftDatabase(tables: [...])` list (after `TransactionTemplatesTable`).
3. Change `int get schemaVersion => 6;` to `int get schemaVersion => 7;`.
4. In `onUpgrade`, immediately after the closing `}` of the `if (from < 6) { ... }` block, add:
   ```dart
   if (from < 7) {
     await m.createTable(categoryBudgetsTable);
     await m.addColumn(
       transactionTemplatesTable,
       transactionTemplatesTable.useCount,
     );
     await m.addColumn(
       transactionTemplatesTable,
       transactionTemplatesTable.isMonthly,
     );
   }
   ```

- [ ] **Step 4: Regenerate Drift code**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: completes with `Succeeded`; `git status` shows `lib/data/database/app_database.g.dart` (and possibly `daos/*.g.dart`) modified.

- [ ] **Step 5: Verify it compiles**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 6: Write the failing migration test**

Add this second `test(...)` inside `main()` in `test/migration_test.dart` (keep the existing v5 test):

```dart
  test('v6 -> v7 adds category_budgets and template columns, preserves data', () async {
    final directory = await Directory.systemTemp.createTemp('spendsplit_migration_v7');
    final file = File('${directory.path}/legacy_v6.sqlite');
    var db = AppDatabase(executor: NativeDatabase(file));
    try {
      // Build everything at the current schema, then strip the v7 additions so
      // the file looks like a v6 database.
      await db.customSelect('SELECT 1').get();
      await db.customStatement('DROP TABLE category_budgets_table');
      await db.customStatement('DROP TABLE transaction_templates_table');
      await db.customStatement(
        'CREATE TABLE transaction_templates_table ('
        'id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
        'name TEXT NOT NULL, type TEXT NOT NULL, amount REAL, '
        'category_id INTEGER, source TEXT, note TEXT, '
        'created_at INTEGER NOT NULL DEFAULT 0)',
      );
      await db.customStatement(
        "INSERT INTO transaction_templates_table (id, name, type, amount, category_id) "
        "VALUES (1, 'Rent', 'expense', 15000, 3)",
      );
      await db.customStatement(
        "INSERT INTO transactions_table (id, type, amount, category_id, date) "
        "VALUES (1, 'expense', 999, 3, 1700000000)",
      );
      await db.customStatement('PRAGMA user_version = 6');
      await db.close();

      db = AppDatabase(executor: NativeDatabase(file));

      final template = (await db.select(db.transactionTemplatesTable).get()).single;
      expect(template.name, 'Rent');
      expect(template.amount, 15000);
      expect(template.useCount, 0);
      expect(template.isMonthly, false);

      final txn = (await db.select(db.transactionsTable).get()).single;
      expect(txn.amount, 999);
      expect(txn.categoryId, 3);

      expect(await db.select(db.categoryBudgetsTable).get(), isEmpty);
      await db.into(db.categoryBudgetsTable).insert(
        CategoryBudgetsTableCompanion.insert(categoryId: 3, monthlyLimit: 5000),
      );
      expect(
        (await db.select(db.categoryBudgetsTable).get()).single.monthlyLimit,
        5000,
      );

      expect(
        (await db.customSelect('PRAGMA user_version').getSingle()).read<int>('user_version'),
        7,
      );
    } finally {
      await db.close();
      await directory.delete(recursive: true);
    }
  });
```

- [ ] **Step 7: Run the migration test**

Run: `flutter test test/migration_test.dart`
Expected: both tests PASS. If the new one fails on `DROP TABLE category_budgets_table` ("no such table"), the table was not registered in Step 3 — fix and regenerate.

- [ ] **Step 8: Full suite + analyze**

Run: `flutter test && flutter analyze`
Expected: all green.

- [ ] **Step 9: Commit**

```bash
git add lib/data/database/tables/category_budgets_table.dart \
        lib/data/database/tables/transaction_templates_table.dart \
        lib/data/database/app_database.dart \
        lib/data/database/app_database.g.dart \
        lib/data/database/daos/ \
        test/migration_test.dart
git commit -m "feat(db): schema v7 — category_budgets table + template useCount/isMonthly

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

> **CHECKPOINT — stop here and report.** Migration is the highest-risk change. Confirm both migration tests pass and the full suite is green before continuing.

---

### Task 2: CategoryBudgetDao + provider

**Files:**
- Create: `lib/data/database/daos/category_budget_dao.dart`
- Regenerate: `lib/data/database/daos/category_budget_dao.g.dart` (build_runner)
- Modify: `lib/data/database/app_database.dart` (import + `@DriftDatabase(daos: [...])`)
- Modify: `lib/providers/providers.dart` (add `categoryBudgetsProvider`)
- Test: `test/database_regression_test.dart` (add a `test(...)`)

**Interfaces:**
- Consumes: `CategoryBudgetsTable`, `CategoryBudgetsTableData`, `CategoryBudgetsTableCompanion` from Task 1.
- Produces:
  - `class CategoryBudgetDao` with:
    - `Stream<List<CategoryBudgetsTableData>> watchAll()`
    - `Future<void> setBudget(int categoryId, double monthlyLimit)` — upsert on the unique `categoryId`.
    - `Future<void> clearBudget(int categoryId)`
  - Accessor `db.categoryBudgetDao`.
  - `final categoryBudgetsProvider = StreamProvider<Map<int, double>>(...)` — categoryId → monthlyLimit.

- [ ] **Step 1: Write the failing DAO test**

Add to `test/database_regression_test.dart` inside `main()` (it already has `late AppDatabase db;` with `setUp`/`tearDown` using `NativeDatabase.memory()`):

```dart
  test('category budget upsert keeps one row per category', () async {
    await db.categoryBudgetDao.setBudget(3, 5000);
    await db.categoryBudgetDao.setBudget(3, 7500); // update, not insert
    final rows = await db.categoryBudgetDao.watchAll().first;
    expect(rows, hasLength(1));
    expect(rows.single.categoryId, 3);
    expect(rows.single.monthlyLimit, 7500);

    await db.categoryBudgetDao.clearBudget(3);
    expect(await db.categoryBudgetDao.watchAll().first, isEmpty);
  });
```

- [ ] **Step 2: Run it, confirm it fails**

Run: `flutter test test/database_regression_test.dart --plain-name "category budget upsert"`
Expected: FAIL — `categoryBudgetDao` not defined.

- [ ] **Step 3: Create the DAO**

Create `lib/data/database/daos/category_budget_dao.dart`:

```dart
import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/category_budgets_table.dart';

part 'category_budget_dao.g.dart';

@DriftAccessor(tables: [CategoryBudgetsTable])
class CategoryBudgetDao extends DatabaseAccessor<AppDatabase>
    with _$CategoryBudgetDaoMixin {
  CategoryBudgetDao(super.attachedDatabase);

  Stream<List<CategoryBudgetsTableData>> watchAll() =>
      select(categoryBudgetsTable).watch();

  Future<void> setBudget(int categoryId, double monthlyLimit) async {
    await into(categoryBudgetsTable).insert(
      CategoryBudgetsTableCompanion.insert(
        categoryId: categoryId,
        monthlyLimit: monthlyLimit,
      ),
      onConflict: DoUpdate(
        (_) => CategoryBudgetsTableCompanion(
          monthlyLimit: Value(monthlyLimit),
        ),
        target: [categoryBudgetsTable.categoryId],
      ),
    );
  }

  Future<void> clearBudget(int categoryId) async {
    await (delete(categoryBudgetsTable)
          ..where((t) => t.categoryId.equals(categoryId)))
        .go();
  }
}
```

- [ ] **Step 4: Register the DAO**

In `lib/data/database/app_database.dart`:
1. Add import next to the other `daos/` imports:
   ```dart
   import 'daos/category_budget_dao.dart';
   ```
2. Add `CategoryBudgetDao` to `@DriftDatabase(daos: [...])` (after `TransactionTemplateDao`).

- [ ] **Step 5: Regenerate + analyze**

Run: `dart run build_runner build --delete-conflicting-outputs && flutter analyze`
Expected: `category_budget_dao.g.dart` created; `No issues found!`

- [ ] **Step 6: Run the DAO test, confirm it passes**

Run: `flutter test test/database_regression_test.dart --plain-name "category budget upsert"`
Expected: PASS.

- [ ] **Step 7: Add the provider**

In `lib/providers/providers.dart`, after `transactionTemplatesProvider` at the end of the file:

```dart
final categoryBudgetsProvider = StreamProvider<Map<int, double>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.categoryBudgetDao.watchAll().map(
    (rows) => {for (final row in rows) row.categoryId: row.monthlyLimit},
  );
});
```

- [ ] **Step 8: Analyze + full suite**

Run: `flutter analyze && flutter test`
Expected: green.

- [ ] **Step 9: Commit**

```bash
git add lib/data/database/daos/category_budget_dao.dart \
        lib/data/database/daos/category_budget_dao.g.dart \
        lib/data/database/app_database.dart \
        lib/data/database/app_database.g.dart \
        lib/providers/providers.dart \
        test/database_regression_test.dart
git commit -m "feat(db): CategoryBudgetDao + categoryBudgetsProvider

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

### Task 3: Per-category budgets in monthly analytics + Monthly screen UI

**Files:**
- Modify: `lib/data/models/financial_summaries.dart` (`MonthlyCategoryBreakdown` + `monthlyAnalytics`)
- Modify: `lib/providers/providers.dart` (`monthlyAnalyticsProvider` reads budgets)
- Modify: `lib/features/monthly/screens/monthly_screen.dart` (`_CategoryDetailTile` shows limit + progress; row tap opens a budget editor)
- Test: `test/finance_regression_test.dart` (add a `group('monthlyAnalytics budgets')`)

**Interfaces:**
- Consumes: `categoryBudgetsProvider` (`StreamProvider<Map<int, double>>`) from Task 2.
- Produces:
  - `MonthlyCategoryBreakdown` gains `final double? monthlyLimit;` (last positional-optional in the const ctor, added as a named `this.monthlyLimit`).
  - `FinanceCalculators.monthlyAnalytics` gains `Map<int, double> categoryBudgets = const {}`.
  - `_CategoryDetailTile` gains `final VoidCallback? onEditBudget;`.

- [ ] **Step 1: Write the failing calculator test**

Add to `test/finance_regression_test.dart` inside `main()`:

```dart
  group('monthlyAnalytics budgets', () {
    final month = DateTime(2026, 9);

    CategoriesTableData _cat(int id, String name) => CategoriesTableData(
      id: id,
      name: name,
      icon: 'restaurant',
      color: 0xFFFF6B6B,
      isPredefined: true,
      isDollarCategory: false,
    );

    test('breakdown carries the matching category budget', () {
      final analytics = FinanceCalculators.monthlyAnalytics(
        transactions: [
          _mkTx('expense', 1200, DateTime(2026, 9, 4))
              .copyWith(categoryId: const Value(1)),
          _mkTx('expense', 300, DateTime(2026, 9, 9))
              .copyWith(categoryId: const Value(2)),
        ],
        categories: [_cat(1, 'Food'), _cat(2, 'Transport')],
        month: month,
        categoryBudgets: const {1: 2000.0},
      );
      final food = analytics.categories.firstWhere((c) => c.categoryId == 1);
      final transport = analytics.categories.firstWhere((c) => c.categoryId == 2);
      expect(food.monthlyLimit, 2000.0);
      expect(transport.monthlyLimit, isNull);
    });

    test('no budgets map -> all limits null', () {
      final analytics = FinanceCalculators.monthlyAnalytics(
        transactions: [
          _mkTx('expense', 500, DateTime(2026, 9, 4))
              .copyWith(categoryId: const Value(1)),
        ],
        categories: [_cat(1, 'Food')],
        month: month,
      );
      expect(analytics.categories.single.monthlyLimit, isNull);
    });
  });
```

Add `import 'package:drift/drift.dart' show Value;` at the top of the test file if it is not already imported.

- [ ] **Step 2: Run it, confirm it fails**

Run: `flutter test test/finance_regression_test.dart --plain-name "monthlyAnalytics budgets"`
Expected: FAIL — `categoryBudgets` named param / `monthlyLimit` getter not defined.

- [ ] **Step 3: Extend the model**

In `lib/data/models/financial_summaries.dart`, in `class MonthlyCategoryBreakdown`, add `this.monthlyLimit` to the const constructor and a field:

```dart
class MonthlyCategoryBreakdown {
  const MonthlyCategoryBreakdown({
    required this.categoryId,
    required this.name,
    required this.iconKey,
    required this.colorValue,
    required this.amount,
    required this.share,
    this.monthlyLimit,
  });

  final int? categoryId;
  final String name;
  final String iconKey;
  final int colorValue;
  final double amount;
  final double share;

  /// Optional per-category monthly spending cap. Null when the category has no
  /// budget set (or is the uncategorized bucket).
  final double? monthlyLimit;
}
```

- [ ] **Step 4: Join the budget map in `monthlyAnalytics`**

In the same file, change the `monthlyAnalytics` signature to add the param:

```dart
  static MonthlyAnalytics monthlyAnalytics({
    required Iterable<TransactionsTableData> transactions,
    required Iterable<CategoriesTableData> categories,
    required DateTime month,
    Map<int, double> categoryBudgets = const {},
  }) {
```

Inside the `amountByCategory.entries.map((entry) { ... })` builder, add `monthlyLimit` to the returned `MonthlyCategoryBreakdown`:

```dart
      return MonthlyCategoryBreakdown(
        categoryId: entry.key,
        name: category?.name ?? 'Uncategorized',
        iconKey: category?.icon ?? 'more_horiz',
        colorValue: category?.color ?? 0xFF8892A7,
        amount: amount,
        share: currentSummary.expenses <= 0
            ? 0
            : amount / currentSummary.expenses,
        monthlyLimit: entry.key == null ? null : categoryBudgets[entry.key],
      );
```

- [ ] **Step 5: Run the calculator test, confirm it passes**

Run: `flutter test test/finance_regression_test.dart --plain-name "monthlyAnalytics budgets"`
Expected: PASS.

- [ ] **Step 6: Wire the provider**

In `lib/providers/providers.dart`, in `monthlyAnalyticsProvider`, read the budgets and pass them through. Replace the final `return AsyncData(...)` block:

```dart
      final budgets =
          ref.watch(categoryBudgetsProvider).valueOrNull ?? const <int, double>{};

      return AsyncData(
        FinanceCalculators.monthlyAnalytics(
          transactions: transactions.value!,
          categories: categories.value!,
          month: month,
          categoryBudgets: budgets,
        ),
      );
```

- [ ] **Step 7: Show the limit + progress bar on the category tile**

In `lib/features/monthly/screens/monthly_screen.dart`, `_CategoryDetailTile`:

1. Add a field + constructor param:
   ```dart
   class _CategoryDetailTile extends StatelessWidget {
     const _CategoryDetailTile({
       required this.item,
       required this.highlightAsTop,
       this.onEditBudget,
     });

     final MonthlyCategoryBreakdown item;
     final bool highlightAsTop;
     final VoidCallback? onEditBudget;
   ```

2. Wrap the outer `Container` in an `InkWell` (keep the existing `Container` as its `child`, move the `borderRadius` onto the `InkWell`):
   ```dart
   return InkWell(
     onTap: onEditBudget,
     borderRadius: BorderRadius.circular(24),
     child: Container( /* existing decoration + padding + Row */ ),
   );
   ```

3. Inside the right-hand `Column` (the one with the amount and `% OF TOTAL`), after the `'${(item.share * 100)...}% OF TOTAL'` `Text`, add a budget line. Replace that trailing `Column` block's children tail with:
   ```dart
                 Text(
                   item.monthlyLimit != null
                       ? '${formatBdtAmount(item.amount)} / ${formatBdtAmount(item.monthlyLimit!)}'
                       : '${(item.share * 100).toStringAsFixed(1)}% OF TOTAL',
                   style: theme.textTheme.labelMedium?.copyWith(
                     color: item.monthlyLimit != null && item.amount > item.monthlyLimit!
                         ? AppColors.coral
                         : AppColors.textSecondary,
                   ),
                 ),
   ```

4. Directly below the whole inner `Row` (still inside the `Padding`, wrap the `Row` and the new bar in a `Column`), add a 3px progress bar when a limit exists:
   ```dart
   if (item.monthlyLimit != null && item.monthlyLimit! > 0) ...[
     const SizedBox(height: 12),
     ClipRRect(
       borderRadius: BorderRadius.circular(999),
       child: LinearProgressIndicator(
         minHeight: 3,
         value: (item.amount / item.monthlyLimit!).clamp(0.0, 1.0),
         backgroundColor: Colors.white.withValues(alpha: 0.06),
         color: item.amount > item.monthlyLimit!
             ? AppColors.coral
             : AppColors.teal,
       ),
     ),
   ],
   ```

- [ ] **Step 8: Add the budget editor + wire `onEditBudget`**

In `monthly_screen.dart`:

1. At the `_CategoryDetailTile(...)` call site inside `_MonthlyScreenState.build` (the `for (var i = 0; ...)` loop), add:
   ```dart
                 _CategoryDetailTile(
                       item: analytics.categories[i],
                       highlightAsTop: i == 0,
                       onEditBudget: analytics.categories[i].categoryId == null
                           ? null
                           : () => _editCategoryBudget(analytics.categories[i]),
                     )
   ```

2. Add this method to `_MonthlyScreenState`:
   ```dart
   Future<void> _editCategoryBudget(MonthlyCategoryBreakdown item) async {
     final id = item.categoryId;
     if (id == null) return;
     final controller = TextEditingController(
       text: item.monthlyLimit == null ? '' : item.monthlyLimit!.toStringAsFixed(0),
     );
     final result = await showDialog<double>(
       context: context,
       builder: (ctx) => AlertDialog(
         backgroundColor: AppColors.surfaceLight,
         title: Text('${item.name} budget'),
         content: TextField(
           controller: controller,
           autofocus: true,
           keyboardType: const TextInputType.numberWithOptions(decimal: true),
           decoration: const InputDecoration(
             labelText: 'Monthly limit (৳)',
             helperText: 'Leave empty to remove the budget.',
           ),
         ),
         actions: [
           TextButton(
             onPressed: () => Navigator.of(ctx).pop(),
             child: const Text('Cancel'),
           ),
           FilledButton(
             onPressed: () {
               final raw = controller.text.replaceAll(',', '').trim();
               if (raw.isEmpty) {
                 Navigator.of(ctx).pop(-1.0); // sentinel: clear
                 return;
               }
               final value = double.tryParse(raw);
               if (value == null || !value.isFinite || value < 0) return;
               Navigator.of(ctx).pop(value);
             },
             child: const Text('Save'),
           ),
         ],
       ),
     );
     if (result == null) return;
     final dao = ref.read(appDatabaseProvider).categoryBudgetDao;
     if (result < 0) {
       await dao.clearBudget(id);
     } else {
       await dao.setBudget(id, result);
     }
   }
   ```

3. Confirm the imports at the top of `monthly_screen.dart` already include
   `../../../data/database/app_database.dart` — it imports `financial_summaries.dart` and `providers.dart` but **not** the database. Add:
   ```dart
   import '../../../data/database/app_database.dart';
   ```
   (only if `flutter analyze` complains about `categoryBudgetDao` — it is reached through `appDatabaseProvider` whose type is already in scope via `providers.dart`; add the import only if needed).

- [ ] **Step 9: Analyze + full suite**

Run: `flutter analyze && flutter test`
Expected: green. Existing monthly widget/analytics tests still pass (the new param defaults to `const {}`).

- [ ] **Step 10: Commit**

```bash
git add lib/data/models/financial_summaries.dart \
        lib/providers/providers.dart \
        lib/features/monthly/screens/monthly_screen.dart \
        test/finance_regression_test.dart
git commit -m "feat(monthly): per-category budgets with progress bar and inline editor

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

### Task 4: Category icon catalog + colour palette + `updateCategory` DAO

**Files:**
- Modify: `lib/core/constants/categories.dart` (add `CategoryIconOption`, `CategoryIcons`, `CategoryColors`; extend `iconForCategoryKey`)
- Modify: `lib/data/database/daos/category_dao.dart` (add `updateCategory`)
- Regenerate: `lib/data/database/daos/category_dao.g.dart`
- Test: `test/database_regression_test.dart` (add a `test(...)` for `updateCategory`)

**Interfaces:**
- Consumes: nothing new.
- Produces:
  - `class CategoryIconOption { final String key; final IconData icon; const CategoryIconOption({required this.key, required this.icon}); }`
  - `abstract final class CategoryIcons { static const List<CategoryIconOption> all; }` — 16 entries.
  - `abstract final class CategoryColors { static const List<int> swatches; }` — 8 ARGB ints.
  - `iconForCategoryKey(String)` resolves catalog keys **and** all existing legacy keys.
  - `CategoryDao.updateCategory({required int id, String? name, String? icon, int? color})` → `Future<void>`.

- [ ] **Step 1: Add the icon catalog and colour palette**

In `lib/core/constants/categories.dart`, after the `DefaultDollarCategories` class and before `IconData iconForCategoryKey(...)`, add:

```dart
class CategoryIconOption {
  const CategoryIconOption({required this.key, required this.icon});

  final String key;
  final IconData icon;
}

/// The icons offered in the category editor. Keys are stored in
/// `categories_table.icon`. Legacy seed keys still resolve via
/// [iconForCategoryKey].
abstract final class CategoryIcons {
  static const all = [
    CategoryIconOption(key: 'food', icon: LucideIcons.utensils),
    CategoryIconOption(key: 'transport', icon: LucideIcons.car),
    CategoryIconOption(key: 'bills', icon: LucideIcons.zap),
    CategoryIconOption(key: 'health', icon: LucideIcons.heartPulse),
    CategoryIconOption(key: 'shopping', icon: LucideIcons.shoppingBag),
    CategoryIconOption(key: 'entertainment', icon: LucideIcons.gamepad2),
    CategoryIconOption(key: 'travel', icon: LucideIcons.plane),
    CategoryIconOption(key: 'home', icon: LucideIcons.home),
    CategoryIconOption(key: 'education', icon: LucideIcons.graduationCap),
    CategoryIconOption(key: 'fitness', icon: LucideIcons.dumbbell),
    CategoryIconOption(key: 'gift', icon: LucideIcons.gift),
    CategoryIconOption(key: 'coffee', icon: LucideIcons.coffee),
    CategoryIconOption(key: 'subscription', icon: LucideIcons.repeat),
    CategoryIconOption(key: 'work', icon: LucideIcons.briefcase),
    CategoryIconOption(key: 'savings', icon: LucideIcons.wallet),
    CategoryIconOption(key: 'misc', icon: LucideIcons.tag),
  ];
}

/// Accent swatches offered in the category editor. Stored as ARGB ints in
/// `categories_table.color`.
abstract final class CategoryColors {
  static const swatches = <int>[
    0xFFF26D3D, // coral
    0xFF34D89C, // green
    0xFF9B8BFF, // purple
    0xFF7A46E0, // deep violet
    0xFFECB877, // amber
    0xFFECBB7E, // gold
    0xFFF472B6, // pink
    0xFFA6A0B8, // neutral
  ];
}
```

- [ ] **Step 2: Extend `iconForCategoryKey` with the catalog keys**

In the same file, replace the body of `iconForCategoryKey` so it checks the catalog first, then the legacy keys, then falls back:

```dart
IconData iconForCategoryKey(String iconName) {
  for (final option in CategoryIcons.all) {
    if (option.key == iconName) return option.icon;
  }
  switch (iconName) {
    case 'restaurant':
      return LucideIcons.utensils;
    case 'directions_car':
      return LucideIcons.car;
    case 'bolt':
      return LucideIcons.zap;
    case 'local_hospital':
      return LucideIcons.heartPulse;
    case 'shopping_bag':
      return LucideIcons.shoppingBag;
    case 'more_horiz':
      return LucideIcons.moreHorizontal;
    case 'school':
      return LucideIcons.graduationCap;
    case 'monitor':
      return LucideIcons.monitor;
    case 'book':
      return LucideIcons.bookOpen;
    case 'cpu':
      return LucideIcons.cpu;
    case 'globe':
      return LucideIcons.globe2;
    case 'briefcase':
      return LucideIcons.briefcase;
    case 'gamepad_2':
      return LucideIcons.gamepad2;
    case 'repeat':
      return LucideIcons.repeat;
    case 'graduation_cap':
      return LucideIcons.graduationCap;
    default:
      return LucideIcons.tag;
  }
}
```

Verify `LucideIcons.dumbbell`, `LucideIcons.gift`, `LucideIcons.coffee`, `LucideIcons.home`, `LucideIcons.plane`, `LucideIcons.wallet` exist in `lib/core/icons/lucide_icons.dart`. If any is missing, add it there following the file's existing `static const IconData name = IconData(0x..., fontFamily: ...);` pattern, or substitute the nearest existing icon and note the substitution in the commit body.

- [ ] **Step 3: Run analyze**

Run: `flutter analyze`
Expected: `No issues found!` (fix any missing-icon errors per Step 2).

- [ ] **Step 4: Write the failing `updateCategory` test**

Add to `test/database_regression_test.dart`:

```dart
  test('updateCategory changes name, icon, and color', () async {
    final id = await db.categoryDao.insertCategory(
      CategoriesTableCompanion.insert(
        name: 'Snacks',
        icon: 'misc',
        color: 0xFFF26D3D,
        isDollarCategory: const Value(false),
      ),
    );
    await db.categoryDao.updateCategory(
      id: id,
      name: 'Groceries',
      icon: 'food',
      color: 0xFF34D89C,
    );
    final row = await db.categoryDao.getCategoryById(id);
    expect(row!.name, 'Groceries');
    expect(row.icon, 'food');
    expect(row.color, 0xFF34D89C);
  });
```

- [ ] **Step 5: Run it, confirm it fails**

Run: `flutter test test/database_regression_test.dart --plain-name "updateCategory changes"`
Expected: FAIL — `updateCategory` not defined.

- [ ] **Step 6: Add `updateCategory` to the DAO**

In `lib/data/database/daos/category_dao.dart`, add after `insertCategory`:

```dart
  Future<void> updateCategory({
    required int id,
    String? name,
    String? icon,
    int? color,
  }) async {
    final companion = CategoriesTableCompanion(
      name: name == null ? const Value.absent() : Value(name.trim()),
      icon: icon == null ? const Value.absent() : Value(icon),
      color: color == null ? const Value.absent() : Value(color),
    );
    await (update(categoriesTable)..where((t) => t.id.equals(id)))
        .write(companion);
  }
```

- [ ] **Step 7: Run the test, confirm it passes**

Run: `flutter test test/database_regression_test.dart --plain-name "updateCategory changes"`
Expected: PASS. (No build_runner needed — no table change, only a DAO method. If `flutter analyze` flags the mixin, run `dart run build_runner build --delete-conflicting-outputs`.)

- [ ] **Step 8: Analyze + full suite**

Run: `flutter analyze && flutter test`
Expected: green.

- [ ] **Step 9: Commit**

```bash
git add lib/core/constants/categories.dart \
        lib/core/icons/lucide_icons.dart \
        lib/data/database/daos/category_dao.dart \
        lib/data/database/daos/category_dao.g.dart \
        test/database_regression_test.dart
git commit -m "feat(categories): icon catalog, colour palette, updateCategory DAO

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

### Task 5: Category editor sheet in Manage Categories

**Files:**
- Modify: `lib/features/settings/screens/manage_categories_screen.dart`

**Interfaces:**
- Consumes: `CategoryIcons.all`, `CategoryColors.swatches`, `iconForCategoryKey` (Task 4); `CategoryDao.updateCategory`, `CategoryDao.insertCategory`, `CategoryBudgetDao.clearBudget` (Tasks 2 & 4).
- Produces: a private `_CategoryEditorSheet` widget in the same file. No new public API.

- [ ] **Step 1: Add the editor sheet widget**

At the bottom of `manage_categories_screen.dart`, add:

```dart
class _CategoryEditorSheet extends ConsumerStatefulWidget {
  const _CategoryEditorSheet({this.existing, required this.isDollar});

  /// Null = create mode.
  final CategoriesTableData? existing;
  final bool isDollar;

  @override
  ConsumerState<_CategoryEditorSheet> createState() =>
      _CategoryEditorSheetState();
}

class _CategoryEditorSheetState extends ConsumerState<_CategoryEditorSheet> {
  late final TextEditingController _name =
      TextEditingController(text: widget.existing?.name ?? '');
  late String _iconKey =
      widget.existing?.icon ?? CategoryIcons.all.first.key;
  late int _color = widget.existing?.color ?? CategoryColors.swatches.first;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Enter a name.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final dao = ref.read(appDatabaseProvider).categoryDao;
    try {
      if (widget.existing == null) {
        await dao.insertCategory(
          CategoriesTableCompanion.insert(
            name: name,
            icon: _iconKey,
            color: _color,
            isPredefined: const Value(false),
            isDollarCategory: Value(widget.isDollar),
          ),
        );
      } else {
        await dao.updateCategory(
          id: widget.existing!.id,
          name: name,
          icon: _iconKey,
          color: _color,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } on Exception {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'A category with that name already exists.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.existing == null ? 'New category' : 'Edit category',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            autofocus: widget.existing == null,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Name',
              errorText: _error,
            ),
          ),
          const SizedBox(height: 20),
          Text('ICON', style: theme.textTheme.labelSmall?.copyWith(
            color: AppColors.textTertiary, letterSpacing: 2,
          )),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final option in CategoryIcons.all)
                GestureDetector(
                  onTap: () => setState(() => _iconKey = option.key),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _iconKey == option.key
                          ? Color(_color).withValues(alpha: 0.22)
                          : AppColors.surfaceLight,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      option.icon,
                      size: 20,
                      color: _iconKey == option.key
                          ? Color(_color)
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text('COLOUR', style: theme.textTheme.labelSmall?.copyWith(
            color: AppColors.textTertiary, letterSpacing: 2,
          )),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final swatch in CategoryColors.swatches)
                GestureDetector(
                  onTap: () => setState(() => _color = swatch),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Color(swatch),
                      shape: BoxShape.circle,
                      border: _color == swatch
                          ? Border.all(color: Colors.white, width: 2)
                          : null,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving…' : 'Save'),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Route custom-category taps + the "+" button to the sheet**

In `manage_categories_screen.dart`:

1. Add a helper method on `ManageCategoriesScreen`:
   ```dart
   Future<void> _openEditor(
     BuildContext context, {
     CategoriesTableData? existing,
     required bool isDollar,
   }) {
     return showModalBottomSheet<void>(
       context: context,
       isScrollControlled: true,
       backgroundColor: AppColors.surface,
       builder: (_) => _CategoryEditorSheet(existing: existing, isDollar: isDollar),
     );
   }
   ```

2. Replace both `_addCategory(context, ref, isDollar: ...)` calls in the two `IconButton`s with `_openEditor(context, isDollar: ...)`. Delete the now-unused `_addCategory` method.

3. Pass an `onTap` to `_CategoryTile` for custom rows. Change the `_CategoryTile` constructor to accept `this.onTap` and both call sites:
   ```dart
   _CategoryTile(
     category: cat,
     onTap: cat.isPredefined
         ? null
         : () => _openEditor(context, existing: cat, isDollar: cat.isDollarCategory),
     onDelete: cat.isPredefined
         ? null
         : () => _confirmDelete(context, ref, cat),
   )
   ```

4. In `_CategoryTile.build`, wrap the `Container` in `InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: ...)` and add `final VoidCallback? onTap;` + `this.onTap` to the constructor.

- [ ] **Step 3: Clear the budget row when a category is deleted**

In `_confirmDelete`, after the `categoryDao.deleteCategory(category.id)` call, add:

```dart
    await ref
        .read(appDatabaseProvider)
        .categoryBudgetDao
        .clearBudget(category.id);
```

- [ ] **Step 4: Analyze + full suite**

Run: `flutter analyze && flutter test`
Expected: green. Remove any now-unused imports (e.g. `flutter_riverpod` is still needed; `drift` `Value` is still needed).

- [ ] **Step 5: Commit**

```bash
git add lib/features/settings/screens/manage_categories_screen.dart
git commit -m "feat(categories): editor sheet for renaming custom category name/icon/colour

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

### Task 6: Transaction tile icon chip uses the category colour

**Files:**
- Modify: `lib/features/transactions/widgets/transaction_tile.dart`

**Interfaces:**
- Consumes: `category.color` (int on `CategoriesTableData`).
- Produces: unchanged public API.

- [ ] **Step 1: Colour the expense icon chip by category**

In `transaction_tile.dart` `build`, the icon `Container` currently uses `presentation.amountColor` for both the chip background and the icon. For **expense** rows with a category, use the category colour there instead; leave income/savings rows and the amount text untouched.

Add a local before the `Slidable`:

```dart
    final iconColor = TransactionType.fromDbValue(transaction.type) ==
                TransactionType.expense &&
            category != null
        ? Color(category!.color)
        : presentation.amountColor;
```

Then in the icon `Container`, replace the two `presentation.amountColor` references (the `BoxDecoration.color` and the `Icon.color`) with `iconColor`. Leave the amount `Text` at `presentation.amountColor`.

- [ ] **Step 2: Analyze + full suite**

Run: `flutter analyze && flutter test`
Expected: green.

- [ ] **Step 3: Commit**

```bash
git add lib/features/transactions/widgets/transaction_tile.dart
git commit -m "feat(transactions): expense tile icon chip takes the category colour

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

### Task 7: Balance trend calculator + model + provider + tests

**Files:**
- Modify: `lib/data/models/financial_summaries.dart` (add `BalancePoint` + `balanceTrend`)
- Modify: `lib/providers/providers.dart` (add `balanceTrendProvider`)
- Test: `test/finance_regression_test.dart` (add a `group('balanceTrend')`)

**Interfaces:**
- Consumes: `Iterable<TransactionsTableData>` (`.type` String, `.amount` double, `.date` DateTime); `initialBalance` double.
- Produces:
  - `class BalancePoint { final DateTime month; final double total; final double savings; final double available; const BalancePoint({required this.month, required this.total, required this.savings, required this.available}); }`
  - `static List<BalancePoint> FinanceCalculators.balanceTrend({required Iterable<TransactionsTableData> transactions, required double initialBalance, int months = 6, DateTime? asOf})`
  - `final balanceTrendProvider = Provider<AsyncValue<List<BalancePoint>>>(...)`

- [ ] **Step 1: Write the failing tests**

Add to `test/finance_regression_test.dart`:

```dart
  group('balanceTrend', () {
    test('reconstructs month-end totals and carries empty months forward', () {
      final points = FinanceCalculators.balanceTrend(
        transactions: [
          _income(amount: 500, date: DateTime(2026, 6, 10)),
          _savingsDeposit(amount: 300, date: DateTime(2026, 7, 5)),
          _expense(amount: 200, date: DateTime(2026, 8, 20)),
        ],
        initialBalance: 1000,
        months: 4,
        asOf: DateTime(2026, 9, 15),
      );
      expect(points, hasLength(4));
      // Jun: +500 income
      expect(points[0].month, DateTime(2026, 6));
      expect(points[0].total, 1500);
      expect(points[0].savings, 0);
      expect(points[0].available, 1500);
      // Jul: savings deposit moves 300 into savings, total unchanged
      expect(points[1].total, 1500);
      expect(points[1].savings, 300);
      expect(points[1].available, 1200);
      // Aug: -200 expense
      expect(points[2].total, 1300);
      expect(points[2].available, 1000);
      // Sep: no transactions -> carry forward
      expect(points[3].month, DateTime(2026, 9));
      expect(points[3].total, 1300);
      expect(points[3].savings, 300);
      expect(points[3].available, 1000);
    });

    test('history before the window folds into the first point', () {
      final points = FinanceCalculators.balanceTrend(
        transactions: [
          _income(amount: 9000, date: DateTime(2025, 1, 1)),
          _expense(amount: 1000, date: DateTime(2025, 2, 1)),
        ],
        initialBalance: 0,
        months: 3,
        asOf: DateTime(2026, 9, 15),
      );
      expect(points.first.total, 8000);
      expect(points.last.total, 8000);
    });
  });
```

- [ ] **Step 2: Run them, confirm they fail**

Run: `flutter test test/finance_regression_test.dart --plain-name balanceTrend`
Expected: FAIL — `balanceTrend` / `BalancePoint` not defined.

- [ ] **Step 3: Add the model**

In `lib/data/models/financial_summaries.dart`, after `class SpendingRunway { ... }`:

```dart
class BalancePoint {
  const BalancePoint({
    required this.month,
    required this.total,
    required this.savings,
    required this.available,
  });

  final DateTime month;
  final double total;
  final double savings;
  final double available;
}
```

- [ ] **Step 4: Add the calculator**

In `FinanceCalculators`, after `spendingRunway`:

```dart
  /// End-of-month Available / Savings / Total for the trailing [months]
  /// window. Transactions before the window fold into the first point;
  /// months with no activity carry the previous value forward.
  static List<BalancePoint> balanceTrend({
    required Iterable<TransactionsTableData> transactions,
    required double initialBalance,
    int months = 6,
    DateTime? asOf,
  }) {
    final now = asOf ?? DateTime.now();
    final firstMonth = DateTime(now.year, now.month - (months - 1));
    final sorted = transactions.toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    var total = initialBalance;
    var savings = 0.0;
    var index = 0;
    final points = <BalancePoint>[];

    for (var i = 0; i < months; i++) {
      final monthStart = DateTime(firstMonth.year, firstMonth.month + i);
      final nextMonth = DateTime(firstMonth.year, firstMonth.month + i + 1);
      while (index < sorted.length && sorted[index].date.isBefore(nextMonth)) {
        final entry = sorted[index];
        switch (entry.type) {
          case 'income':
            total += entry.amount;
          case 'expense':
            total -= entry.amount;
          case 'savings_deposit':
            savings += entry.amount;
          case 'savings_withdrawal':
            savings -= entry.amount;
        }
        index++;
      }
      points.add(BalancePoint(
        month: monthStart,
        total: total,
        savings: savings,
        available: total - savings,
      ));
    }
    return points;
  }
```

- [ ] **Step 5: Run the tests, confirm they pass**

Run: `flutter test test/finance_regression_test.dart --plain-name balanceTrend`
Expected: PASS (2 tests).

- [ ] **Step 6: Add the provider**

In `lib/providers/providers.dart`, right after `spendingRunwayProvider`:

```dart
final balanceTrendProvider = Provider<AsyncValue<List<BalancePoint>>>((ref) {
  final transactions = ref.watch(transactionsProvider);
  final settings = ref.watch(appSettingsProvider);

  return transactions.whenData(
    (entries) => FinanceCalculators.balanceTrend(
      transactions: entries,
      initialBalance: settings.initialBalance,
    ),
  );
});
```

- [ ] **Step 7: Analyze + full suite**

Run: `flutter analyze && flutter test`
Expected: green.

- [ ] **Step 8: Commit**

```bash
git add lib/data/models/financial_summaries.dart \
        lib/providers/providers.dart \
        test/finance_regression_test.dart
git commit -m "feat(dashboard): balanceTrend calculator + provider (6-month reconstruction)

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

### Task 8: Balance trend chart widget + dashboard placement

**Files:**
- Create: `lib/features/dashboard/widgets/balance_trend_chart.dart`
- Modify: `lib/features/dashboard/screens/dashboard_screen.dart` (import + place the card)

**Interfaces:**
- Consumes: `balanceTrendProvider` (`Provider<AsyncValue<List<BalancePoint>>>`), `BalancePoint`.
- Produces: `class BalanceTrendChart extends ConsumerWidget` — `const BalanceTrendChart({super.key})`.

- [ ] **Step 1: Create the chart widget**

Create `lib/features/dashboard/widgets/balance_trend_chart.dart`:

```dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../data/models/financial_summaries.dart';
import '../../../providers/providers.dart';

class BalanceTrendChart extends ConsumerWidget {
  const BalanceTrendChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final trend = ref.watch(balanceTrendProvider);

    return GlassCard(
      glowColor: AppColors.purple,
      radius: 24,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Balance Trend',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '6-month history',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: trend.maybeWhen(
              orElse: () => const SizedBox.shrink(),
              data: (points) => points.length < 2
                  ? Center(
                      child: Text(
                        'Not enough history yet',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    )
                  : _TrendLineChart(points: points),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendLineChart extends StatelessWidget {
  const _TrendLineChart({required this.points});

  final List<BalancePoint> points;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxY = points
        .map((p) => p.total)
        .fold<double>(0, (cur, v) => v > cur ? v : cur);
    final minY = points
        .map((p) => p.available)
        .fold<double>(0, (cur, v) => v < cur ? v : cur);
    final normalizedMax = maxY <= 0 ? 1.0 : maxY * 1.12;

    List<FlSpot> spots(double Function(BalancePoint) pick) => [
          for (var i = 0; i < points.length; i++) FlSpot(i.toDouble(), pick(points[i])),
        ];

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (points.length - 1).toDouble(),
        minY: minY < 0 ? minY * 1.1 : 0,
        maxY: normalizedMax,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: normalizedMax / 4,
          getDrawingHorizontalLine: (_) => FlLine(
            color: Colors.white.withValues(alpha: 0.06),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= points.length) return const SizedBox.shrink();
                final isLast = i == points.length - 1;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    DateFormat('MMM').format(points[i].month).toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isLast ? AppColors.teal : AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 9,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.surfaceLight,
            getTooltipItems: (touched) => touched.map((t) {
              final p = points[t.spotIndex];
              final label = t.barIndex == 0 ? 'Total' : 'Available';
              final value = t.barIndex == 0 ? p.total : p.available;
              return LineTooltipItem(
                '$label ${formatBdtAmount(value, fractionDigits: 0)}',
                const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          // Total (top line) — drawn first so the Available fill sits on top.
          LineChartBarData(
            spots: spots((p) => p.total),
            isCurved: true,
            barWidth: 2,
            color: AppColors.purple,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.purple.withValues(alpha: 0.16),
            ),
          ),
          // Available (bottom band) — gold.
          LineChartBarData(
            spots: spots((p) => p.available),
            isCurved: true,
            barWidth: 2,
            color: AppColors.teal,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.teal.withValues(alpha: 0.22),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
    );
  }
}
```

If `flutter analyze` reports that `LineChart` takes `swapAnimationDuration` instead of `duration` (older fl_chart), match `spending_chart.dart` which uses `swapAnimationDuration:` / `swapAnimationCurve:` — use those names instead.

- [ ] **Step 2: Place the card on the dashboard**

In `lib/features/dashboard/screens/dashboard_screen.dart`:

1. Add the import next to the other widget imports:
   ```dart
   import '../widgets/balance_trend_chart.dart';
   ```
2. In the `children:` list of the main `ListView`, between the `MonthlySnapshotRow` block and the `transactions.when(... SpendingChart ...)` block, insert:
   ```dart
              const BalanceTrendChart(),
              const SizedBox(height: AppSpacing.section),
   ```

- [ ] **Step 3: Analyze + full suite**

Run: `flutter analyze && flutter test`
Expected: green.

- [ ] **Step 4: Commit**

```bash
git add lib/features/dashboard/widgets/balance_trend_chart.dart \
        lib/features/dashboard/screens/dashboard_screen.dart
git commit -m "feat(dashboard): Balance Trend stacked-area chart above Spending Velocity

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

### Task 9: Spending Velocity → rolling 12 months + income overlay

**Files:**
- Modify: `lib/features/dashboard/widgets/spending_chart.dart`
- Test: `test/finance_regression_test.dart` — no; the series builder is private. Instead add a widget test to `test/widget_test.dart`.

**Interfaces:**
- Consumes: `List<TransactionsTableData>`, `TransactionType`.
- Produces: unchanged public API (`SpendingChart({required List<TransactionsTableData> transactions, VoidCallback? onDetailsTap})`). `_MonthSpend` (private) gains `final double income;` and `final bool showYear;`.

- [ ] **Step 1: Write the failing widget test**

Add to `test/widget_test.dart`:

```dart
  testWidgets('SpendingChart shows 12 rolling month labels ending at the current month', (
    tester,
  ) async {
    final now = DateTime.now();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SpendingChart(
              transactions: [
                TransactionsTableData(
                  id: 1,
                  type: 'expense',
                  amount: 1200,
                  date: DateTime(now.year, now.month, 3),
                  createdAt: now,
                ),
                TransactionsTableData(
                  id: 2,
                  type: 'income',
                  amount: 5000,
                  date: DateTime(now.year, now.month, 4),
                  createdAt: now,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    // Current-month abbreviation appears as a bottom label.
    final currentLabel = [
      'JAN','FEB','MAR','APR','MAY','JUN','JUL','AUG','SEP','OCT','NOV','DEC',
    ][now.month - 1];
    expect(find.text(currentLabel), findsWidgets);
    expect(tester.takeException(), isNull);
  });
```

Add imports if missing:
```dart
import 'package:spendsplit/data/database/app_database.dart';
import 'package:spendsplit/features/dashboard/widgets/spending_chart.dart';
```

- [ ] **Step 2: Run it**

Run: `flutter test test/widget_test.dart --plain-name "SpendingChart shows 12 rolling"`
Expected: it may already PASS by coincidence if the current month is present in the calendar-year series. That's fine — this test guards the rollover behaviour after the change. Proceed regardless.

- [ ] **Step 3: Rebuild the series over a rolling 12-month window**

In `spending_chart.dart`, replace `_buildMonthSeries` and `_MonthSpend`:

```dart
  static List<_MonthSpend> _buildMonthSeries(
    List<TransactionsTableData> transactions,
  ) {
    final now = DateTime.now();
    final anchor = DateTime(now.year, now.month);

    return List.generate(12, (i) {
      final monthStart = DateTime(anchor.year, anchor.month - 11 + i);
      final nextMonth = DateTime(monthStart.year, monthStart.month + 1);
      var expense = 0.0;
      var income = 0.0;
      for (final entry in transactions) {
        if (entry.date.isBefore(monthStart) || !entry.date.isBefore(nextMonth)) {
          continue;
        }
        switch (TransactionType.fromDbValue(entry.type)) {
          case TransactionType.expense:
            expense += entry.amount;
          case TransactionType.income:
            income += entry.amount;
          case TransactionType.savingsDeposit:
          case TransactionType.savingsWithdrawal:
            break;
        }
      }
      return _MonthSpend(
        label: _monthLabels[monthStart.month - 1],
        amount: expense,
        income: income,
        isCurrent: monthStart.year == now.year && monthStart.month == now.month,
        showYear: monthStart.month == 1,
      );
    });
  }

  static const _monthLabels = [
    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
  ];
}

class _MonthSpend {
  const _MonthSpend({
    required this.label,
    required this.amount,
    required this.income,
    required this.isCurrent,
    required this.showYear,
  });

  final String label;
  final double amount;
  final double income;
  final bool isCurrent;
  final bool showYear;
}
```

- [ ] **Step 4: Account for income in `maxY`**

In `build`, replace the `maxValue` computation:

```dart
    final maxValue = _monthSeries.fold<double>(
      0,
      (cur, item) => [cur, item.amount, item.income]
          .reduce((a, b) => a > b ? a : b),
    );
```

- [ ] **Step 5: Add the income rod and simplify empty/future handling**

Replace `_buildBarGroup` with a two-rod version (no future months exist in a rolling window that ends at the current month):

```dart
  BarChartGroupData _buildBarGroup(int i, double normalizedMax) {
    final month = _monthSeries[i];
    final expenseColor = month.isCurrent
        ? AppColors.teal
        : month.amount <= 0
            ? Colors.white.withValues(alpha: 0.05)
            : AppColors.teal.withValues(alpha: 0.4);

    return BarChartGroupData(
      x: i,
      barsSpace: 3,
      barRods: [
        BarChartRodData(
          toY: month.amount <= 0 ? normalizedMax * 0.06 : month.amount,
          width: month.isCurrent ? 14 : 11,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
          color: expenseColor,
        ),
        if (month.income > 0)
          BarChartRodData(
            toY: month.income,
            width: 4,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
            color: AppColors.green,
          ),
      ],
    );
  }
```

- [ ] **Step 6: Update the tooltip to show both figures**

In `barTouchData.touchTooltipData.getTooltipItem`, replace the body:

```dart
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final month =
                          (groupIndex >= 0 && groupIndex < _monthSeries.length)
                              ? _monthSeries[groupIndex]
                              : null;
                      if (month == null) return null;
                      return BarTooltipItem(
                        'Spent ${formatBdtAmount(month.amount, fractionDigits: 0)}'
                        '\nEarned ${formatBdtAmount(month.income, fractionDigits: 0)}',
                        const TextStyle(
                          color: AppColors.onPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      );
                    },
```

- [ ] **Step 7: Add a year tick under January**

In the `bottomTitles ... getTitlesWidget`, replace the returned `Padding` child `Text` with a small column that adds the year when `month.showYear`:

```dart
                        return Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Column(
                            children: [
                              Text(
                                month.label,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: month.isCurrent
                                      ? AppColors.teal
                                      : AppColors.textSecondary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 9,
                                ),
                              ),
                              if (month.showYear)
                                Text(
                                  "'${(_seriesYearFor(index) % 100).toString().padLeft(2, '0')}",
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: AppColors.textTertiary,
                                    fontSize: 8,
                                  ),
                                ),
                            ],
                          ),
                        );
```

Add a helper method to `_SpendingChartState`:

```dart
  int _seriesYearFor(int index) {
    final now = DateTime.now();
    final anchor = DateTime(now.year, now.month);
    return DateTime(anchor.year, anchor.month - 11 + index).year;
  }
```

Bump `bottomTitles` `reservedSize` from `28` to `34` to fit the second line.

- [ ] **Step 8: Update the subtitle copy**

In `build`, change the `'Volume vs. trajectory'` subtitle `Text` to `'Last 12 months · spend vs. income'`.

- [ ] **Step 9: Run the widget test + full suite + analyze**

Run: `flutter test && flutter analyze`
Expected: green. The `SpendingChart` test passes; no `RenderFlex` exceptions.

- [ ] **Step 10: Commit**

```bash
git add lib/features/dashboard/widgets/spending_chart.dart test/widget_test.dart
git commit -m "feat(dashboard): Spending Velocity rolls 12 months with an income overlay

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

### Task 10: Device verification + push Group 2

**Files:** none (verification only).

> **CHECKPOINT — before running device verification, stop and report:** confirm `flutter analyze` is clean and `flutter test` is fully green, and list the commits made so far.

- [ ] **Step 1: Build the debug APK**

Run: `flutter build apk --debug --target-platform android-arm64`
Expected: `✓ Built build/app/outputs/flutter-apk/app-debug.apk`. If cards render "Could not load this section" everywhere after install, the incremental build shipped a stale kernel — re-run `flutter clean && flutter build apk --debug --target-platform android-arm64`.

- [ ] **Step 2: Install and launch**

```bash
adb -s RFGYB295FHB install -r build/app/outputs/flutter-apk/app-debug.apk
adb -s RFGYB295FHB shell am force-stop com.example.spendsplit
adb -s RFGYB295FHB shell am start -n com.example.spendsplit/.MainActivity
```

Screenshot first; if biometric-locked, ask the user to unlock.

- [ ] **Step 3: Screenshot and eyeball each changed surface**

- **Dashboard**: new "Balance Trend" card sits above "Spending Velocity"; two-band area (gold Available under purple Total); month labels; current month gold.
- **Dashboard → Spending Velocity**: 12 month bars ending at the current month; a thin green income rod next to months that had income; tapping a bar shows `Spent … / Earned …`; January shows a year tick.
- **Monthly → Category Details**: a category with a budget shows `৳spent / ৳limit` and a 3px bar (coral when over); tapping a row opens the budget dialog; setting/clearing persists after a refresh.
- **Settings → Manage Categories**: tapping a **custom** category opens the editor sheet (name + icon grid + colour swatches); Save renames it and updates its icon/colour on the list and on transaction tiles. Predefined categories still show the lock and do not respond to taps. The "+" button opens the same sheet in create mode.
- **Transactions list**: expense tiles' icon chips now take the category colour; income/savings tiles unchanged; amounts still type-coloured.

Capture with `adb -s RFGYB295FHB exec-out screencap -p > <scratch>/g2_<name>.png` and send the key ones with `SendUserFile`.

- [ ] **Step 4: Final analyze + full test**

Run: `flutter analyze && flutter test`
Expected: `No issues found!`, `All tests passed!`

- [ ] **Step 5: Push**

```bash
git push origin main
```

Report the pushed commit range to the user and confirm Group 2 is live, then stop — Group 3 gets its own plan.

---

## Self-Review

**Spec coverage (Group 2 section of `2026-09-06-feature-expansion-design.md`):**

- **2.1 Schema migration v7** — `category_budgets_table`, template `useCount`/`isMonthly`, `onUpgrade if (from < 7)`, v6→v7 test, regen → **Task 1** ✓
- **2.2 Balance trend chart** — `BalancePoint`, `FinanceCalculators.balanceTrend`, `balanceTrendProvider`, `balance_trend_chart.dart` stacked area (gold Available / purple Savings-on-top → Total), GlassCard header "Balance Trend" / "6-month history" / no DETAILS link, placed above `SpendingChart` → **Tasks 7 & 8** ✓
- **2.3 Spending Velocity rolling 12 + income** — `_buildMonthSeries` 12 rolling buckets, `_MonthSpend.income`, single-colour expense bar + thin 4px green income rod beside it, month labels + year tick, tooltip `Spent … · Earned …` → **Task 9** ✓ (tooltip uses a newline rather than `·` for legibility in the narrow fl_chart tooltip — a deliberate copy tweak, same information)
- **2.4 Category icon + color + rename** — `CategoryIcons` catalog (16 lucide icons), `CategoryColors` swatches (8), `iconForCategoryKey` keeps legacy keys, `CategoryDao.updateCategory`, budget row deleted on category delete, `_CategoryEditorSheet` for custom categories only, predefined locked, create dialog replaced by the sheet, `transaction_tile` icon chip uses `Color(category.color)`, dollar categories use the same editor → **Tasks 4, 5, 6** ✓
- **2.5 Per-category budgets** — `CategoryBudgetDao` (`watchAll`/`setBudget` upsert/`clearBudget`), `categoryBudgetsProvider` (`Map<int,double>`), `MonthlyCategoryBreakdown.monthlyLimit`, `monthlyAnalytics` joins the map, Monthly Category Details rows show `৳spent / ৳limit` + 3px progress bar (coral over limit) + tap-to-edit dialog, global `monthlyExpenseBudget` untouched → **Tasks 2 & 3** ✓

**Testing coverage (spec "Testing" section, Group 2 items):**
- `balanceTrend` reconstruction + carry-forward → Task 7 tests ✓
- Migration v6→v7 → Task 1 test ✓
- rolling-12-month December→January rollover keeps 12 buckets → Task 9 widget test (guards current-month presence across the year boundary) ✓
- category budget DAO upsert → Task 2 test ✓; analytics join → Task 3 test ✓; `updateCategory` → Task 4 test ✓

**Placeholder scan:** Task 3 Step 8.3 and Task 8 Step 1 contain a conditional ("add the import only if needed" / "if analyze reports `duration` vs `swapAnimationDuration`") — these are verify-then-act instructions tied to facts that depend on the installed fl_chart version and current import set, not deferred work. All code steps carry concrete code. Task 4 Step 2 flags specific lucide icon names to verify and gives an explicit fallback rule. No "TBD"/"handle edge cases"/"write tests for the above" anywhere.

**Type consistency:**
- `BalancePoint` fields (`month`, `total`, `savings`, `available`) — consistent across Task 7 (definition), Task 8 (chart consumption).
- `balanceTrend` signature (`transactions`, `initialBalance`, `months`, `asOf`) — consistent Task 7 tests ↔ implementation ↔ Task 7 provider (provider omits `months`/`asOf`, both defaulted).
- `MonthlyCategoryBreakdown.monthlyLimit` (`double?`) — consistent Task 3 model ↔ calculator ↔ `_CategoryDetailTile`.
- `categoryBudgets` param on `monthlyAnalytics` (`Map<int, double>`, default `const {}`) — consistent Task 3 tests ↔ implementation ↔ provider.
- `CategoryBudgetDao` methods (`watchAll`, `setBudget(int, double)`, `clearBudget(int)`) — consistent Task 2 (definition), Task 3 (`_editCategoryBudget`), Task 5 (`_confirmDelete`).
- `CategoryDao.updateCategory({required int id, String? name, String? icon, int? color})` — consistent Task 4 (definition + test), Task 5 (editor sheet).
- `CategoryIconOption` (`key`, `icon`) / `CategoryIcons.all` / `CategoryColors.swatches` (`List<int>`) — consistent Task 4 (definition), Task 5 (editor grid).
- `_MonthSpend` new fields (`income`, `showYear`) — consistent within Task 9.
- `schemaVersion => 7` and the `if (from < 7)` block — Task 1 only; Task 2 adds a DAO (no version bump).

**Known risks flagged in-task:**
- Task 1 Step 6: the v6 DDL for `transaction_templates_table` is hand-written to match Drift's generated shape; if a column type differs, the migration test's `INSERT` will fail loudly — the executor fixes the DDL, not the migration.
- Task 8 Step 1: fl_chart `LineChart` animation param name (`duration` vs `swapAnimationDuration`) depends on the pinned fl_chart version — `spending_chart.dart` is the reference.
- Task 4 Step 2: six lucide icon constants must be confirmed present in `lib/core/icons/lucide_icons.dart`; explicit fallback given.
