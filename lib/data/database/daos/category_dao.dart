import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/categories_table.dart';

part 'category_dao.g.dart';

@DriftAccessor(tables: [CategoriesTable])
class CategoryDao extends DatabaseAccessor<AppDatabase>
    with _$CategoryDaoMixin {
  CategoryDao(super.attachedDatabase);

  Stream<List<CategoriesTableData>> watchMainCategories() {
    return (select(categoriesTable)
          ..where((table) => table.isDollarCategory.equals(false))
          ..orderBy([
            (table) => OrderingTerm.desc(table.isPredefined),
            (table) => OrderingTerm.asc(table.name),
          ]))
        .watch();
  }

  Stream<List<CategoriesTableData>> watchDollarCategories() {
    return (select(categoriesTable)
          ..where((table) => table.isDollarCategory.equals(true))
          ..orderBy([(table) => OrderingTerm.asc(table.name)]))
        .watch();
  }

  Future<List<CategoriesTableData>> getMainCategories() {
    return (select(categoriesTable)
          ..where((table) => table.isDollarCategory.equals(false))
          ..orderBy([
            (table) => OrderingTerm.desc(table.isPredefined),
            (table) => OrderingTerm.asc(table.name),
          ]))
        .get();
  }

  Future<CategoriesTableData?> getCategoryById(int id) {
    return (select(
      categoriesTable,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertCategory(CategoriesTableCompanion entry) {
    final name = entry.name.value.trim();
    if (name.isEmpty) throw ArgumentError('Category name cannot be empty');
    return into(categoriesTable).insert(entry.copyWith(name: Value(name)));
  }

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
    await (update(
      categoriesTable,
    )..where((t) => t.id.equals(id))).write(companion);
  }

  /// How many transactions, templates and dollar expenses use [id].
  Future<int> usageCount(int id) async {
    final row = await customSelect(
      'SELECT '
      '(SELECT COUNT(*) FROM transactions_table WHERE category_id = ?1) + '
      '(SELECT COUNT(*) FROM transaction_templates_table WHERE category_id = ?1) + '
      '(SELECT COUNT(*) FROM dollar_expenses_table WHERE category_id = ?1) AS n',
      variables: [Variable<int>(id)],
    ).getSingle();
    return row.read<int>('n');
  }

  /// Deletes the category and its budget. Rows that used it move to
  /// [moveTo] when given; otherwise transactions and templates become
  /// uncategorized and dollar expenses (non-null column) keep the dead ID,
  /// shown as uncategorized. IDs are never reused (AUTOINCREMENT, kept past
  /// restores by SnapshotService).
  Future<void> deleteCategory(int id, {int? moveTo}) {
    final db = attachedDatabase;
    return transaction(() async {
      await (db.update(db.transactionsTable)
            ..where((t) => t.categoryId.equals(id)))
          .write(TransactionsTableCompanion(categoryId: Value(moveTo)));
      await (db.update(db.transactionTemplatesTable)
            ..where((t) => t.categoryId.equals(id)))
          .write(TransactionTemplatesTableCompanion(categoryId: Value(moveTo)));
      if (moveTo != null) {
        await (db.update(db.dollarExpensesTable)
              ..where((t) => t.categoryId.equals(id)))
            .write(DollarExpensesTableCompanion(categoryId: Value(moveTo)));
      }
      await (db.delete(
        db.categoryBudgetsTable,
      )..where((t) => t.categoryId.equals(id))).go();
      await (delete(categoriesTable)..where((t) => t.id.equals(id))).go();
    });
  }
}
