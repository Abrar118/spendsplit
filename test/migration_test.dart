import 'dart:io';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendsplit/data/database/app_database.dart';

/// Rebuilds transactions_table with its exact v7 definition (no sms_ref,
/// needs_review or unique index) so the file matches a pre-v8 database.
Future<void> _stripV8(AppDatabase db) async {
  await db.customStatement('DROP TABLE transactions_table');
  await db.customStatement(
    'CREATE TABLE transactions_table ('
    'id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
    'type TEXT NOT NULL, amount REAL NOT NULL, category_id INTEGER, '
    'savings_goal_id INTEGER, source TEXT, note TEXT, '
    'date INTEGER NOT NULL, '
    "created_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)))",
  );
}

void main() {
  test(
    'v5 upgrade preserves amounts and remaps duplicate category references',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'spendsplit_migration',
      );
      final file = File('${directory.path}/legacy.sqlite');
      var db = AppDatabase(executor: NativeDatabase(file));
      try {
        await db.customSelect('SELECT 1').get();
        await _stripV8(db);
        // Exact v5 category definition: global, case-sensitive name uniqueness.
        await db.customStatement('DROP TABLE categories_table');
        await db.customStatement(
          'CREATE TABLE categories_table (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE, icon TEXT NOT NULL, color INTEGER NOT NULL, is_predefined INTEGER NOT NULL DEFAULT 0 CHECK(is_predefined IN (0, 1)), is_dollar_category INTEGER NOT NULL DEFAULT 0 CHECK(is_dollar_category IN (0, 1)))',
        );
        // Strip the v7 additions so the file matches a real v5 database.
        await db.customStatement('DROP TABLE category_budgets_table');
        await db.customStatement('DROP TABLE transaction_templates_table');
        await db.customStatement(
          'CREATE TABLE transaction_templates_table ('
          'id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
          'name TEXT NOT NULL, type TEXT NOT NULL, amount REAL, '
          'category_id INTEGER, source TEXT, note TEXT, '
          'created_at INTEGER NOT NULL DEFAULT 0)',
        );
        await db.customStatement(
          "INSERT INTO categories_table VALUES (100, 'Board games', 'category', 1, 0, 0), (101, 'board games', 'category', 2, 0, 0)",
        );
        await db.customStatement(
          "INSERT INTO transactions_table (id, type, amount, category_id, date) VALUES (1, 'expense', 42, 101, 1700000000)",
        );
        await db.customStatement(
          "INSERT INTO transaction_templates_table (id, name, type, category_id) VALUES (1, 'Weekend', 'expense', 101)",
        );
        await db.customStatement('PRAGMA user_version = 5');
        await db.close();
        db = AppDatabase(executor: NativeDatabase(file));
        final transactions = await db.select(db.transactionsTable).get();
        expect(transactions.single.amount, 42);
        expect(transactions.single.categoryId, 100);
        expect(
          (await db.select(db.transactionTemplatesTable).get())
              .single
              .categoryId,
          100,
        );
        expect(await db.categoryDao.getCategoryById(101), isNull);
        final dollarId = await db.categoryDao.insertCategory(
          CategoriesTableCompanion.insert(
            name: 'Board games',
            icon: 'category',
            color: 1,
            isDollarCategory: const Value(true),
          ),
        );
        expect(dollarId, greaterThan(100));
        expect(
          (await db.customSelect('PRAGMA user_version').getSingle()).read<int>(
            'user_version',
          ),
          8,
        );
      } finally {
        await db.close();
        await directory.delete(recursive: true);
      }
    },
  );

  test(
    'v6 -> v7 adds category_budgets and template columns, preserves data',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'spendsplit_migration_v7',
      );
      final file = File('${directory.path}/legacy_v6.sqlite');
      var db = AppDatabase(executor: NativeDatabase(file));
      try {
        // Build everything at the current schema, then strip the v7 additions
        // so the file looks like a v6 database.
        await db.customSelect('SELECT 1').get();
        await _stripV8(db);
        await db.customStatement('DROP TABLE category_budgets_table');
        await db.customStatement('DROP TABLE transaction_templates_table');
        await db.customStatement(
          'CREATE TABLE transaction_templates_table ('
          'id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
          'name TEXT NOT NULL, type TEXT NOT NULL, amount REAL, '
          'category_id INTEGER, source TEXT, note TEXT, '
          'created_at INTEGER NOT NULL DEFAULT 0)',
        );
        await db.customStatement(
          "INSERT INTO transaction_templates_table (id, name, type, amount, category_id) "
          "VALUES (1, 'Rent', 'expense', 15000, 3)",
        );
        await db.customStatement(
          "INSERT INTO transactions_table (id, type, amount, category_id, date) "
          "VALUES (1, 'expense', 999, 3, 1700000000)",
        );
        await db.customStatement('PRAGMA user_version = 6');
        await db.close();

        db = AppDatabase(executor: NativeDatabase(file));

        final template = (await db.select(
          db.transactionTemplatesTable,
        ).get()).single;
        expect(template.name, 'Rent');
        expect(template.amount, 15000);
        expect(template.useCount, 0);
        expect(template.isMonthly, false);

        final txn = (await db.select(db.transactionsTable).get()).single;
        expect(txn.amount, 999);
        expect(txn.categoryId, 3);

        expect(await db.select(db.categoryBudgetsTable).get(), isEmpty);
        await db
            .into(db.categoryBudgetsTable)
            .insert(
              CategoryBudgetsTableCompanion.insert(
                categoryId: 3,
                monthlyLimit: 5000,
              ),
            );
        expect(
          (await db.select(db.categoryBudgetsTable).get()).single.monthlyLimit,
          5000,
        );

        expect(
          (await db.customSelect('PRAGMA user_version').getSingle()).read<int>(
            'user_version',
          ),
          8,
        );
      } finally {
        await db.close();
        await directory.delete(recursive: true);
      }
    },
  );

  test('v7 -> v8 keeps every existing transaction unchanged', () async {
    final directory = await Directory.systemTemp.createTemp(
      'spendsplit_migration_v8',
    );
    final file = File('${directory.path}/legacy_v7.sqlite');
    var db = AppDatabase(executor: NativeDatabase(file));
    try {
      await db.customSelect('SELECT 1').get();
      await _stripV8(db);
      await db.customStatement(
        'INSERT INTO transactions_table '
        '(id, type, amount, category_id, savings_goal_id, source, note, date, created_at) VALUES '
        "(1, 'expense', 70.5, 3, NULL, NULL, 'Lunch', 1758450000, 1758450001), "
        "(2, 'income', 14500, NULL, NULL, 'salary', NULL, 1758460000, 1758460001), "
        "(3, 'savings_deposit', 1000, NULL, 1, NULL, 'Trip', 1758470000, 1758470001)",
      );
      await db.customStatement('PRAGMA user_version = 7');
      await db.close();

      db = AppDatabase(executor: NativeDatabase(file));
      final rows = await (db.select(
        db.transactionsTable,
      )..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
      int secs(DateTime d) => d.millisecondsSinceEpoch ~/ 1000;
      expect(
        rows
            .map(
              (r) => (
                r.id,
                r.type,
                r.amount,
                r.categoryId,
                r.savingsGoalId,
                r.source,
                r.note,
                secs(r.date),
                secs(r.createdAt),
              ),
            )
            .toList(),
        [
          (1, 'expense', 70.5, 3, null, null, 'Lunch', 1758450000, 1758450001),
          (2, 'income', 14500.0, null, null, 'salary', null, 1758460000, 1758460001),
          (3, 'savings_deposit', 1000.0, null, 1, null, 'Trip', 1758470000, 1758470001),
        ],
      );
      expect(rows.every((r) => r.smsRef == null && !r.needsReview), isTrue);

      // Any number of NULL refs coexist; a repeated non-null ref is rejected.
      Future<int> insertRef(String? ref) => db
          .into(db.transactionsTable)
          .insert(
            TransactionsTableCompanion.insert(
              type: 'expense',
              amount: 1,
              date: DateTime(2026),
              smsRef: Value(ref),
            ),
          );
      await insertRef(null);
      await insertRef(null);
      await insertRef('1|a');
      await expectLater(insertRef('1|a'), throwsA(isA<SqliteException>()));

      expect(
        (await db.customSelect('PRAGMA user_version').getSingle()).read<int>(
          'user_version',
        ),
        8,
      );
    } finally {
      await db.close();
      await directory.delete(recursive: true);
    }
  });
}
