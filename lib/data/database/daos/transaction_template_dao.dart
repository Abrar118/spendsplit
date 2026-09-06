import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/transaction_templates_table.dart';

part 'transaction_template_dao.g.dart';

@DriftAccessor(tables: [TransactionTemplatesTable])
class TransactionTemplateDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionTemplateDaoMixin {
  TransactionTemplateDao(super.attachedDatabase);

  Stream<List<TransactionTemplatesTableData>> watchTemplates() =>
      (select(transactionTemplatesTable)
            ..orderBy([(t) => OrderingTerm.asc(t.name)]))
          .watch();

  Future<int> insertTemplate(TransactionTemplatesTableCompanion entry) =>
      into(transactionTemplatesTable).insert(entry);

  Future<int> deleteTemplateById(int id) =>
      (delete(transactionTemplatesTable)
            ..where((t) => t.id.equals(id)))
          .go();

  Future<void> markUsed(int id) async {
    await customUpdate(
      'UPDATE transaction_templates_table SET use_count = use_count + 1 '
      'WHERE id = ?',
      variables: [Variable<int>(id)],
      updates: {transactionTemplatesTable},
    );
  }

  Future<void> setMonthly(int id, bool value) async {
    await (update(transactionTemplatesTable)..where((t) => t.id.equals(id)))
        .write(TransactionTemplatesTableCompanion(isMonthly: Value(value)));
  }
}
