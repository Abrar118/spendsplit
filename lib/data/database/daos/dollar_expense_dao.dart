import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/dollar_expenses_table.dart';

part 'dollar_expense_dao.g.dart';

@DriftAccessor(tables: [DollarExpensesTable])
class DollarExpenseDao extends DatabaseAccessor<AppDatabase>
    with _$DollarExpenseDaoMixin {
  DollarExpenseDao(super.attachedDatabase);

  Stream<List<DollarExpensesTableData>> watchExpenses() {
    return (select(dollarExpensesTable)..orderBy([
          (table) => OrderingTerm.desc(table.date),
          (table) => OrderingTerm.desc(table.createdAt),
        ]))
        .watch();
  }

  Stream<List<DollarExpensesTableData>> watchExpensesForYear(int year) {
    final start = DateTime(year);
    final end = DateTime(year + 1);
    return (select(dollarExpensesTable)
          ..where(
            (table) =>
                table.date.isBiggerOrEqualValue(start) &
                table.date.isSmallerThanValue(end),
          )
          ..orderBy([
            (table) => OrderingTerm.desc(table.date),
            (table) => OrderingTerm.desc(table.createdAt),
          ]))
        .watch();
  }

  Future<int> insertExpense(DollarExpensesTableCompanion entry) {
    return into(dollarExpensesTable).insert(entry);
  }

  Future<bool> updateExpense(DollarExpensesTableData entry) {
    return update(dollarExpensesTable).replace(entry);
  }

  Future<int> deleteExpenseById(int id) {
    return (delete(
      dollarExpensesTable,
    )..where((table) => table.id.equals(id))).go();
  }
}
