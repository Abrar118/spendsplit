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

  Future<SavingsGoalsTableData?> getGoalById(int id) {
    return (select(
      savingsGoalsTable,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
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

  /// Clears linked transaction references and deletes the goal atomically.
  Future<int> deleteGoalWithReferenceCleanup(int id) {
    return attachedDatabase.transaction(() async {
      await clearGoalReferencesOnTransactions(id);
      return deleteGoalById(id);
    });
  }

  /// Adjusts the goal's currentAmount by [delta].
  /// Returns false if the goal doesn't exist or the result would go negative.
  Future<bool> adjustCurrentAmountBy(int id, double delta) async {
    if (delta.abs() < 1e-9) return true; // skip dust deltas
    final existing = await getGoalById(id);
    if (existing == null) return false;

    final raw = existing.currentAmount + delta;
    if (raw < -1e-9) return false;
    final nextAmount = raw.abs() < 1e-9 ? 0.0 : raw;
    return update(
      savingsGoalsTable,
    ).replace(existing.copyWith(currentAmount: nextAmount));
  }

  /// Nulls out savingsGoalId on all transactions that reference [goalId].
  /// Called before deleting a goal to prevent orphaned references.
  Future<void> clearGoalReferencesOnTransactions(int goalId) async {
    await (attachedDatabase.update(attachedDatabase.transactionsTable)
          ..where((t) => t.savingsGoalId.equals(goalId)))
        .write(const TransactionsTableCompanion(savingsGoalId: Value(null)));
  }
}
