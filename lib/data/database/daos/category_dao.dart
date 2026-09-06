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
    await (update(categoriesTable)..where((t) => t.id.equals(id)))
        .write(companion);
  }

  Future<int> deleteCategory(int id) {
    return (delete(categoriesTable)..where((t) => t.id.equals(id))).go();
  }
}
