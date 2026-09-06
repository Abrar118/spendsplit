import 'package:drift/drift.dart';

import '../database/app_database.dart';

class SnapshotImportCounts {
  int categories = 0;
  int transactions = 0;
  int savingsGoals = 0;
  int dollarExpenses = 0;
  int transactionTemplates = 0;
  int categoryBudgets = 0;

  int get total =>
      categories +
      transactions +
      savingsGoals +
      dollarExpenses +
      transactionTemplates +
      categoryBudgets;
}

/// Full-database export/restore. Only touches the six Drift tables; the
/// caller layers `AppSettings` on top for a complete backup.
class SnapshotService {
  const SnapshotService(this._db);

  final AppDatabase _db;

  Future<Map<String, dynamic>> exportTables() async {
    return {
      'categories': (await _db.select(_db.categoriesTable).get())
          .map((e) => e.toJson())
          .toList(),
      'transactions': (await _db.select(_db.transactionsTable).get())
          .map((e) => e.toJson())
          .toList(),
      'savingsGoals': (await _db.select(_db.savingsGoalsTable).get())
          .map((e) => e.toJson())
          .toList(),
      'dollarExpenses': (await _db.select(_db.dollarExpensesTable).get())
          .map((e) => e.toJson())
          .toList(),
      'transactionTemplates':
          (await _db.select(_db.transactionTemplatesTable).get())
              .map((e) => e.toJson())
              .toList(),
      'categoryBudgets': (await _db.select(_db.categoryBudgetsTable).get())
          .map((e) => e.toJson())
          .toList(),
    };
  }

  /// Replaces every row in every table with the contents of [tables] in a
  /// single transaction. Any failure rolls the whole thing back.
  Future<SnapshotImportCounts> importTables(Map<String, dynamic> tables) {
    final counts = SnapshotImportCounts();

    List<Map<String, dynamic>> rows(String key) =>
        ((tables[key] as List?) ?? const [])
            .cast<Map<String, dynamic>>()
            .toList();

    return _db.transaction(() async {
      await _db.delete(_db.transactionsTable).go();
      await _db.delete(_db.dollarExpensesTable).go();
      await _db.delete(_db.transactionTemplatesTable).go();
      await _db.delete(_db.categoryBudgetsTable).go();
      await _db.delete(_db.savingsGoalsTable).go();
      await _db.delete(_db.categoriesTable).go();

      for (final j in rows('categories')) {
        await _db
            .into(_db.categoriesTable)
            .insert(
              CategoriesTableData.fromJson(j),
              mode: InsertMode.insertOrReplace,
            );
        counts.categories++;
      }
      for (final j in rows('savingsGoals')) {
        await _db
            .into(_db.savingsGoalsTable)
            .insert(
              SavingsGoalsTableData.fromJson(j),
              mode: InsertMode.insertOrReplace,
            );
        counts.savingsGoals++;
      }
      for (final j in rows('transactions')) {
        await _db
            .into(_db.transactionsTable)
            .insert(
              TransactionsTableData.fromJson(j),
              mode: InsertMode.insertOrReplace,
            );
        counts.transactions++;
      }
      for (final j in rows('dollarExpenses')) {
        await _db
            .into(_db.dollarExpensesTable)
            .insert(
              DollarExpensesTableData.fromJson(j),
              mode: InsertMode.insertOrReplace,
            );
        counts.dollarExpenses++;
      }
      for (final j in rows('transactionTemplates')) {
        await _db
            .into(_db.transactionTemplatesTable)
            .insert(
              TransactionTemplatesTableData.fromJson(j),
              mode: InsertMode.insertOrReplace,
            );
        counts.transactionTemplates++;
      }
      for (final j in rows('categoryBudgets')) {
        await _db
            .into(_db.categoryBudgetsTable)
            .insert(
              CategoryBudgetsTableData.fromJson(j),
              mode: InsertMode.insertOrReplace,
            );
        counts.categoryBudgets++;
      }

      return counts;
    });
  }
}
