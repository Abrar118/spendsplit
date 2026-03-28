import '../../data/database/app_database.dart';

List<SavingsGoalsTableData> sortGoalsByPriority(
  Iterable<SavingsGoalsTableData> goals,
) {
  final sorted = goals.toList()
    ..sort((a, b) {
      if (a.deadline != null && b.deadline != null) {
        return a.deadline!.compareTo(b.deadline!);
      }
      if (a.deadline != null) {
        return -1;
      }
      if (b.deadline != null) {
        return 1;
      }
      return b.createdAt.compareTo(a.createdAt);
    });

  return sorted;
}
