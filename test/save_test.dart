import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendsplit/data/database/app_database.dart';
import 'package:spendsplit/features/transactions/widgets/add_transaction_sheet.dart';
import 'package:spendsplit/providers/providers.dart';

void main() {
  testWidgets('rapid repeated save updates linked savings exactly once', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase(executor: NativeDatabase.memory());

    final setup = await tester.runAsync(() async {
      final goal = await db.savingsGoalDao.insertGoal(
        SavingsGoalsTableCompanion.insert(
          name: 'Trip',
          targetAmount: 100,
          currentAmount: const Value(10),
        ),
      );
      final id = await db.transactionDao.insertTransaction(
        TransactionsTableCompanion.insert(
          type: 'savings_deposit',
          amount: 10,
          savingsGoalId: Value(goal),
          date: DateTime.now(),
        ),
      );
      return (goal, (await db.transactionDao.getTransactionById(id))!);
    });
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
                  existingTransaction: setup!.$2,
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
    await tester.enterText(find.byType(TextField).first, '20');
    final finder = find.ancestor(
      of: find.text('UPDATE'),
      matching: find.byType(FilledButton),
    );
    final dynamic save = tester.widget<FilledButton>(finder).onPressed;
    await tester.runAsync(() async {
      await Future.wait<void>([save() as Future<void>, save() as Future<void>]);
    });
    await tester.pumpAndSettle();
    final balance = await tester.runAsync(
      () => db.savingsGoalDao.getGoalById(setup!.$1),
    );
    expect(balance!.currentAmount, 20);
    expect(find.text('Open'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    final closing = db.close();
    await tester.pump(const Duration(milliseconds: 1));
    await closing;
  });
}
