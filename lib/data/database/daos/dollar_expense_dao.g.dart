// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dollar_expense_dao.dart';

// ignore_for_file: type=lint
mixin _$DollarExpenseDaoMixin on DatabaseAccessor<AppDatabase> {
  $DollarExpensesTableTable get dollarExpensesTable =>
      attachedDatabase.dollarExpensesTable;
  DollarExpenseDaoManager get managers => DollarExpenseDaoManager(this);
}

class DollarExpenseDaoManager {
  final _$DollarExpenseDaoMixin _db;
  DollarExpenseDaoManager(this._db);
  $$DollarExpensesTableTableTableManager get dollarExpensesTable =>
      $$DollarExpensesTableTableTableManager(
        _db.attachedDatabase,
        _db.dollarExpensesTable,
      );
}
