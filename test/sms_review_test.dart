import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendsplit/core/constants/categories.dart';
import 'package:spendsplit/data/database/app_database.dart';
import 'package:spendsplit/features/sms_import/providers/sms_providers.dart';
import 'package:spendsplit/features/transactions/widgets/add_transaction_sheet.dart';
import 'package:spendsplit/providers/providers.dart';

Future<TransactionsTableData> insertSmsEntry(AppDatabase db) async {
  final other = (await db.select(db.categoriesTable).get()).firstWhere(
    (c) => c.name == DefaultCategories.other && !c.isDollarCategory,
  );
  final id = await db.transactionDao.insertTransaction(
    TransactionsTableCompanion.insert(
      type: 'expense',
      amount: 70,
      categoryId: Value(other.id),
      note: const Value('POS Txn'),
      date: DateTime(2026, 9, 21, 17, 28),
      smsRef: const Value('1|x'),
      needsReview: const Value(true),
    ),
  );
  return (await db.transactionDao.getTransactionById(id))!;
}

void main() {
  test('needsReviewCountProvider counts flagged rows', () async {
    final db = AppDatabase(executor: NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(() async {
      container.dispose();
      await db.close();
    });
    await insertSmsEntry(db);
    await db.transactionDao.insertTransaction(
      TransactionsTableCompanion.insert(
        type: 'expense',
        amount: 5,
        date: DateTime(2026, 9, 21),
      ),
    );
    await container.read(transactionsProvider.future);
    expect(container.read(needsReviewCountProvider), 1);
  });

  testWidgets('saving an SMS entry from the edit sheet clears the flag', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase(executor: NativeDatabase.memory());
    final entry = (await tester.runAsync(() => insertSmsEntry(db)))!;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showAddTransactionSheet(
                  context,
                  existingTransaction: entry,
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final finder = find.ancestor(
      of: find.text('UPDATE'),
      matching: find.byType(FilledButton),
    );
    final dynamic save = tester.widget<FilledButton>(finder).onPressed;
    await tester.runAsync(() async => await (save() as Future<void>));
    await tester.pumpAndSettle();

    final saved = await tester.runAsync(
      () => db.transactionDao.getTransactionById(entry.id),
    );
    expect(saved!.needsReview, isFalse);
    expect(saved.smsRef, '1|x');

    await tester.pumpWidget(const SizedBox.shrink());
    final closing = db.close();
    await tester.pump(const Duration(milliseconds: 1));
    await closing;
  });
}
