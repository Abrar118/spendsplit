import '../database/app_database.dart';
import '../database/daos/transaction_dao.dart';

class TransactionRepository {
  const TransactionRepository(this._transactionDao);

  final TransactionDao _transactionDao;

  Stream<List<TransactionsTableData>> watchTransactions() {
    return _transactionDao.watchTransactions();
  }

  Stream<List<TransactionsTableData>> watchTransactionsForMonth(
    DateTime month,
  ) {
    return _transactionDao.watchTransactionsForMonth(month);
  }

  Future<List<TransactionsTableData>> getTransactions() {
    return _transactionDao.getTransactions();
  }

  Future<TransactionsTableData?> getTransactionById(int id) {
    return _transactionDao.getTransactionById(id);
  }

  Future<int> createTransaction(TransactionsTableCompanion entry) {
    return _transactionDao.insertTransaction(entry);
  }

  Future<bool> updateTransaction(TransactionsTableData entry) {
    return _transactionDao.updateTransaction(entry);
  }

  Future<int> deleteTransactionById(int id) {
    return _transactionDao.deleteTransactionById(id);
  }
}
