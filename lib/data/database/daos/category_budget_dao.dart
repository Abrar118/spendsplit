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
