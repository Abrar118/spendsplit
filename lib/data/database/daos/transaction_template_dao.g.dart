// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_template_dao.dart';

// ignore_for_file: type=lint
mixin _$TransactionTemplateDaoMixin on DatabaseAccessor<AppDatabase> {
  $TransactionTemplatesTableTable get transactionTemplatesTable =>
      attachedDatabase.transactionTemplatesTable;
  TransactionTemplateDaoManager get managers =>
      TransactionTemplateDaoManager(this);
}

class TransactionTemplateDaoManager {
  final _$TransactionTemplateDaoMixin _db;
  TransactionTemplateDaoManager(this._db);
  $$TransactionTemplatesTableTableTableManager get transactionTemplatesTable =>
      $$TransactionTemplatesTableTableTableManager(
        _db.attachedDatabase,
        _db.transactionTemplatesTable,
      );
}
