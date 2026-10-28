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

  /// Clears linked transaction references and deletes the goal atomically.
  /// Returns the IDs of the transactions that were linked to the goal.
  Future<List<int>> deleteGoalById(int id) {
    return _savingsGoalDao.deleteGoalWithReferenceCleanup(id);
  }

  Future<void> restoreGoal(
    SavingsGoalsTableData goal,
    List<int> linkedTransactionIds,
  ) {
    return _savingsGoalDao.restoreGoal(goal, linkedTransactionIds);
  }

  Future<bool> adjustGoalAmountBy(int id, double delta) {
    return _savingsGoalDao.adjustCurrentAmountBy(id, delta);
  }
}
