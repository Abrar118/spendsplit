import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/transactions_table.dart';

part 'transaction_dao.g.dart';

@DriftAccessor(tables: [TransactionsTable])
class TransactionDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionDaoMixin {
  TransactionDao(super.attachedDatabase);

  Stream<List<TransactionsTableData>> watchTransactions() {
    return (select(transactionsTable)..orderBy([
          (table) => OrderingTerm.desc(table.date),
          (table) => OrderingTerm.desc(table.createdAt),
        ]))
        .watch();
  }

  Stream<List<TransactionsTableData>> watchTransactionsForMonth(
    DateTime month,
  ) {
    final start = DateTime(month.year, month.month);
    final end = DateTime(month.year, month.month + 1);
    return (select(transactionsTable)
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

  Future<List<TransactionsTableData>> getTransactions() {
    return (select(transactionsTable)..orderBy([
          (table) => OrderingTerm.desc(table.date),
          (table) => OrderingTerm.desc(table.createdAt),
        ]))
        .get();
  }

  Future<TransactionsTableData?> getTransactionById(int id) {
    return (select(
      transactionsTable,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertTransaction(TransactionsTableCompanion entry) {
    return into(transactionsTable).insert(entry);
  }

  /// Re-inserts a complete row preserving its original ID.
  /// Used for undo-delete to maintain identity.
  Future<void> insertTransactionWithId(TransactionsTableData entry) {
    return into(transactionsTable).insert(
      entry.toCompanion(true),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<bool> updateTransaction(TransactionsTableData entry) {
    return update(transactionsTable).replace(entry);
  }

  Future<int> deleteTransactionById(int id) {
    return (delete(
      transactionsTable,
    )..where((table) => table.id.equals(id))).go();
  }
}
