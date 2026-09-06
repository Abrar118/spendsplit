// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_budget_dao.dart';

// ignore_for_file: type=lint
mixin _$CategoryBudgetDaoMixin on DatabaseAccessor<AppDatabase> {
  $CategoryBudgetsTableTable get categoryBudgetsTable =>
      attachedDatabase.categoryBudgetsTable;
  CategoryBudgetDaoManager get managers => CategoryBudgetDaoManager(this);
}

class CategoryBudgetDaoManager {
  final _$CategoryBudgetDaoMixin _db;
  CategoryBudgetDaoManager(this._db);
  $$CategoryBudgetsTableTableTableManager get categoryBudgetsTable =>
      $$CategoryBudgetsTableTableTableManager(
        _db.attachedDatabase,
        _db.categoryBudgetsTable,
      );
}
