import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendsplit/data/database/app_database.dart';

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
