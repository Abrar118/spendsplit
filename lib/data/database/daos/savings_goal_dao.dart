import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/savings_goals_table.dart';

part 'savings_goal_dao.g.dart';

@DriftAccessor(tables: [SavingsGoalsTable])
class SavingsGoalDao extends DatabaseAccessor<AppDatabase>
    with _$SavingsGoalDaoMixin {
  SavingsGoalDao(super.attachedDatabase);

  Stream<List<SavingsGoalsTableData>> watchGoals({
    bool includeCompleted = true,
  }) {
    final query = select(savingsGoalsTable)
      ..orderBy([(table) => OrderingTerm.desc(table.createdAt)]);

    if (!includeCompleted) {
      query.where((table) => table.isCompleted.equals(false));
    }

    return query.watch();
  }

  Future<List<SavingsGoalsTableData>> getGoals({bool includeCompleted = true}) {
    final query = select(savingsGoalsTable)
      ..orderBy([(table) => OrderingTerm.desc(table.createdAt)]);

    if (!includeCompleted) {
      query.where((table) => table.isCompleted.equals(false));
    }

    return query.get();
  }

  Future<int> insertGoal(SavingsGoalsTableCompanion entry) {
    return into(savingsGoalsTable).insert(entry);
  }

  Future<bool> updateGoal(SavingsGoalsTableData entry) {
    return update(savingsGoalsTable).replace(entry);
  }

  Future<int> deleteGoalById(int id) {
    return (delete(
      savingsGoalsTable,
    )..where((table) => table.id.equals(id))).go();
  }
}
