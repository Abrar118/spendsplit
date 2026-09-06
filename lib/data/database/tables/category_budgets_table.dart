import 'package:drift/drift.dart';

class CategoryBudgetsTable extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// One budget per category. No FK constraint — matches the other tables'
  /// style; orphan rows for deleted categories are ignored by joins and
  /// cleaned up when a category is deleted.
  IntColumn get categoryId => integer().unique()();

  RealColumn get monthlyLimit => real()();
}
