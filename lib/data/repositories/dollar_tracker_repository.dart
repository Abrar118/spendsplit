import '../database/app_database.dart';
import '../database/daos/dollar_expense_dao.dart';

class DollarTrackerRepository {
  const DollarTrackerRepository(this._dollarExpenseDao);

  final DollarExpenseDao _dollarExpenseDao;

  Stream<List<DollarExpensesTableData>> watchExpenses() {
    return _dollarExpenseDao.watchExpenses();
  }

  Stream<List<DollarExpensesTableData>> watchExpensesForYear(int year) {
    return _dollarExpenseDao.watchExpensesForYear(year);
  }

  Future<int> createExpense(DollarExpensesTableCompanion entry) {
    return _dollarExpenseDao.insertExpense(entry);
  }

  Future<void> createExpenseWithId(DollarExpensesTableData entry) {
    return _dollarExpenseDao.insertExpenseWithId(entry);
  }

  Future<bool> updateExpense(DollarExpensesTableData entry) {
    return _dollarExpenseDao.updateExpense(entry);
  }

  Future<int> deleteExpenseById(int id) {
    return _dollarExpenseDao.deleteExpenseById(id);
  }
}
