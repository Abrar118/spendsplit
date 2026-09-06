import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendsplit/data/database/app_database.dart';
import 'package:spendsplit/data/repositories/snapshot_service.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(executor: NativeDatabase.memory()));
  tearDown(() => db.close());
  CategoriesTableCompanion category(String name, bool dollar) =>
      CategoriesTableCompanion.insert(
        name: name,
        icon: 'category',
        color: 1,
        isDollarCategory: Value(dollar),
      );
  test(
    'same name belongs independently to expense and dollar trackers',
    () async {
      final main = await db.categoryDao.insertCategory(
        category('Board games', false),
      );
      final dollar = await db.categoryDao.insertCategory(
        category('Board games', true),
      );
      expect(main, isNot(dollar));
      expect(
        (await db.categoryDao.watchDollarCategories().first).any(
          (c) => c.id == dollar,
        ),
        isTrue,
      );
      expect(
        (await db.categoryDao.getMainCategories()).any((c) => c.id == dollar),
        isFalse,
      );
    },
  );
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

  test('snapshot export/import round-trips every table', () async {
    final catId = await db.categoryDao.insertCategory(
      CategoriesTableCompanion.insert(
        name: 'Groceries',
        icon: 'food',
        color: 0xFF34D89C,
      ),
    );
    await db.transactionDao.insertTransaction(
      TransactionsTableCompanion.insert(
        type: 'expense',
        amount: 123.45,
        date: DateTime(2026, 9, 3),
        categoryId: Value(catId),
      ),
    );
    await db.categoryBudgetDao.setBudget(catId, 5000);
    await db.into(db.savingsGoalsTable).insert(
      SavingsGoalsTableCompanion.insert(name: 'Trip', targetAmount: 20000),
    );

    final service = SnapshotService(db);
    final exported = await service.exportTables();

    // Wipe and restore.
    final catCountBefore = (await db.categoryDao.getMainCategories()).length;
    final counts = await service.importTables(exported);
    expect(counts.transactions, 1);
    expect(counts.savingsGoals, 1);
    expect(counts.categoryBudgets, 1);
    expect(counts.categories, greaterThanOrEqualTo(1));

    // No duplication of the default categories on restore.
    expect(
      (await db.categoryDao.getMainCategories()).length,
      catCountBefore,
    );

    final txns = await db.transactionDao.getTransactions();
    expect(txns.single.amount, 123.45);
    expect(txns.single.categoryId, catId);
    expect(
      (await db.categoryBudgetDao.watchAll().first).single.monthlyLimit,
      5000,
    );
  });

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

  test(
    'concurrent case variants produce one category within a tracker',
    () async {
      final results = await Future.wait(
        ['Board games', 'board games'].map((name) async {
          try {
            await db.categoryDao.insertCategory(category(name, false));
            return true;
          } catch (_) {
            return false;
          }
        }),
      );
      expect(results.where((success) => success).length, 1);
    },
  );
  test('concurrent savings adjustments do not lose a deposit', () async {
    final id = await db.savingsGoalDao.insertGoal(
      SavingsGoalsTableCompanion.insert(name: 'Travel', targetAmount: 1000),
    );
    await Future.wait(
      List.generate(10, (_) => db.savingsGoalDao.adjustCurrentAmountBy(id, 10)),
    );
    expect((await db.savingsGoalDao.getGoalById(id))!.currentAmount, 100);
    expect(await db.savingsGoalDao.adjustCurrentAmountBy(id, -101), isFalse);
    expect((await db.savingsGoalDao.getGoalById(id))!.currentAmount, 100);
  });
}
