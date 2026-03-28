import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../core/constants/categories.dart';
import 'daos/category_dao.dart';
import 'daos/dollar_expense_dao.dart';
import 'daos/savings_goal_dao.dart';
import 'daos/transaction_dao.dart';
import 'tables/categories_table.dart';
import 'tables/dollar_expenses_table.dart';
import 'tables/savings_goals_table.dart';
import 'tables/transactions_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    TransactionsTable,
    CategoriesTable,
    SavingsGoalsTable,
    DollarExpensesTable,
  ],
  daos: [TransactionDao, CategoryDao, SavingsGoalDao, DollarExpenseDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await batch((batch) {
        batch.insertAll(
          categoriesTable,
          DefaultCategories.seeds
              .map(
                (seed) => CategoriesTableCompanion.insert(
                  name: seed.name,
                  icon: seed.icon,
                  color: seed.colorValue,
                  isPredefined: const Value(true),
                  isDollarCategory: const Value(false),
                ),
              )
              .toList(),
        );
      });
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(path.join(directory.path, 'spendsplit.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
