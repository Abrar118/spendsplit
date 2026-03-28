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

  Future<int> createGoal(SavingsGoalsTableCompanion entry) {
    return _savingsGoalDao.insertGoal(entry);
  }

  Future<bool> updateGoal(SavingsGoalsTableData entry) {
    return _savingsGoalDao.updateGoal(entry);
  }

  Future<int> deleteGoalById(int id) {
    return _savingsGoalDao.deleteGoalById(id);
  }
}
