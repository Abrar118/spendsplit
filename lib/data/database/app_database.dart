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
import 'daos/transaction_template_dao.dart';
import 'tables/categories_table.dart';
import 'tables/category_budgets_table.dart';
import 'tables/dollar_expenses_table.dart';
import 'tables/savings_goals_table.dart';
import 'tables/transaction_templates_table.dart';
import 'tables/transactions_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    TransactionsTable,
    CategoriesTable,
    SavingsGoalsTable,
    DollarExpensesTable,
    TransactionTemplatesTable,
    CategoryBudgetsTable,
  ],
  daos: [
    TransactionDao,
    CategoryDao,
    SavingsGoalDao,
    DollarExpenseDao,
    TransactionTemplateDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase({QueryExecutor? executor}) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _ensureDefaultCategories();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(savingsGoalsTable, savingsGoalsTable.currentAmount);
        await m.addColumn(savingsGoalsTable, savingsGoalsTable.icon);
        await m.addColumn(savingsGoalsTable, savingsGoalsTable.isCompleted);
        await m.addColumn(savingsGoalsTable, savingsGoalsTable.completedAt);
      }

      if (from < 3) {
        final existingNames = (await select(
          categoriesTable,
        ).get()).map((row) => row.name).toSet();
        final missingDollarSeeds = DefaultDollarCategories.seeds.where(
          (seed) => !existingNames.contains(seed.name),
        );
        if (missingDollarSeeds.isNotEmpty) {
          await batch((batch) {
            batch.insertAll(
              categoriesTable,
              missingDollarSeeds
                  .map(
                    (seed) => CategoriesTableCompanion.insert(
                      name: seed.name,
                      icon: seed.icon,
                      color: seed.colorValue,
                      isPredefined: const Value(true),
                      isDollarCategory: const Value(true),
                    ),
                  )
                  .toList(),
            );
          });
        }
      }

      if (from < 4) {
        await m.addColumn(transactionsTable, transactionsTable.savingsGoalId);
      }

      if (from < 5) {
        await m.createTable(transactionTemplatesTable);
      }
      if (from < 6) {
        await transaction(() async {
          // Older versions allowed case-only duplicates. Merge references before
          // rebuilding the table, preserving the canonical category ID.
          final sequence = await customSelect(
            "SELECT seq FROM sqlite_sequence WHERE name = 'categories_table'",
          ).getSingleOrNull();
          final previousSequence = sequence?.read<int>('seq') ?? 0;
          final rows = await (select(
            categoriesTable,
          )..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
          final canonical = <String, int>{};
          for (final row in rows) {
            final key =
                '${row.isDollarCategory}:${row.name.trim().toLowerCase()}';
            final keep = canonical[key];
            if (keep == null) {
              canonical[key] = row.id;
              continue;
            }
            await (update(transactionsTable)
                  ..where((t) => t.categoryId.equals(row.id)))
                .write(TransactionsTableCompanion(categoryId: Value(keep)));
            await (update(dollarExpensesTable)
                  ..where((t) => t.categoryId.equals(row.id)))
                .write(DollarExpensesTableCompanion(categoryId: Value(keep)));
            await (update(
              transactionTemplatesTable,
            )..where((t) => t.categoryId.equals(row.id))).write(
              TransactionTemplatesTableCompanion(categoryId: Value(keep)),
            );
            await (delete(
              categoriesTable,
            )..where((t) => t.id.equals(row.id))).go();
          }
          await m.alterTable(TableMigration(categoriesTable));
          // Table rebuilds otherwise reuse deleted IDs, which could reattach
          // older uncategorized transactions to an unrelated new category.
          await customStatement(
            "UPDATE sqlite_sequence SET seq = MAX(seq, ?) WHERE name = 'categories_table'",
            [previousSequence],
          );
        });
      }
      if (from < 7) {
        await m.createTable(categoryBudgetsTable);
        await m.addColumn(
          transactionTemplatesTable,
          transactionTemplatesTable.useCount,
        );
        await m.addColumn(
          transactionTemplatesTable,
          transactionTemplatesTable.isMonthly,
        );
      }
    },
    beforeOpen: (_) async {
      await _ensureDefaultCategories();
    },
  );

  Future<void> _ensureDefaultCategories() async {
    final existingNames = (await select(categoriesTable).get())
        .map((row) => '${row.isDollarCategory}:${row.name.toLowerCase()}')
        .toSet();

    final entries = [
      ...DefaultCategories.seeds
          .where(
            (seed) =>
                !existingNames.contains('false:${seed.name.toLowerCase()}'),
          )
          .map(
            (seed) => CategoriesTableCompanion.insert(
              name: seed.name,
              icon: seed.icon,
              color: seed.colorValue,
              isPredefined: const Value(true),
              isDollarCategory: const Value(false),
            ),
          ),
      ...DefaultDollarCategories.seeds
          .where(
            (seed) =>
                !existingNames.contains('true:${seed.name.toLowerCase()}'),
          )
          .map(
            (seed) => CategoriesTableCompanion.insert(
              name: seed.name,
              icon: seed.icon,
              color: seed.colorValue,
              isPredefined: const Value(true),
              isDollarCategory: const Value(true),
            ),
          ),
    ];

    if (entries.isEmpty) {
      return;
    }

    await batch((batch) {
      batch.insertAll(categoriesTable, entries);
    });
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    // Store the database in Application Support on iOS and private app
    // storage on Android. Backup exclusion is handled natively.
    final directory = Platform.isIOS
        ? await getApplicationSupportDirectory()
        : await getApplicationDocumentsDirectory();

    // Ensure the directory exists (applicationSupport may not on first run)
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }

    final file = File(path.join(directory.path, 'spendsplit.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
