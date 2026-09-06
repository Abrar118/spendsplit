import '../database/app_database.dart';
import '../database/daos/transaction_template_dao.dart';

class TransactionTemplateRepository {
  const TransactionTemplateRepository(this._dao);

  final TransactionTemplateDao _dao;

  Stream<List<TransactionTemplatesTableData>> watchTemplates() =>
      _dao.watchTemplates();

  Future<int> createTemplate(TransactionTemplatesTableCompanion entry) =>
      _dao.insertTemplate(entry);

  Future<int> deleteTemplateById(int id) => _dao.deleteTemplateById(id);

  Future<void> markUsed(int id) => _dao.markUsed(id);

  Future<void> setMonthly(int id, bool value) => _dao.setMonthly(id, value);
}
