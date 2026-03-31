import '../database/app_database.dart';
import '../database/daos/savings_goal_dao.dart';

class SavingsRepository {
  const SavingsRepository(this._savingsGoalDao);

  final SavingsGoalDao _savingsGoalDao;

  Stream<List<SavingsGoalsTableData>> watchGoals({
    bool includeCompleted = true,
  }) {
    return _savingsGoalDao.watchGoals(includeCompleted: includeCompleted);
  }

  Future<List<SavingsGoalsTableData>> getGoals({bool includeCompleted = true}) {
    return _savingsGoalDao.getGoals(includeCompleted: includeCompleted);
  }

  Future<SavingsGoalsTableData?> getGoalById(int id) {
    return _savingsGoalDao.getGoalById(id);
  }

  Future<int> createGoal(SavingsGoalsTableCompanion entry) {
    return _savingsGoalDao.insertGoal(entry);
  }

  Future<bool> updateGoal(SavingsGoalsTableData entry) {
    return _savingsGoalDao.updateGoal(entry);
  }

  /// Clears savingsGoalId on all linked transactions, then deletes the goal.
  Future<int> deleteGoalById(int id) async {
    await _savingsGoalDao.clearGoalReferencesOnTransactions(id);
    return _savingsGoalDao.deleteGoalById(id);
  }

  Future<bool> adjustGoalAmountBy(int id, double delta) {
    return _savingsGoalDao.adjustCurrentAmountBy(id, delta);
  }
}
