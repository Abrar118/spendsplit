import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendsplit/data/database/app_database.dart';
import 'package:spendsplit/features/sms_import/providers/sms_providers.dart';
import 'package:spendsplit/features/sms_import/reconciliation.dart';
import 'package:spendsplit/providers/providers.dart';

TransactionsTableData txn(String type, double amount, DateTime date) =>
    TransactionsTableData(
      id: 0,
      type: type,
      amount: amount,
      date: date,
      createdAt: date,
      needsReview: false,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final at = DateTime(2026, 9, 21, 17, 28);

  test('appTotalAsOf counts income/expense up to asOf, ignores savings', () {
    final total = appTotalAsOf(
      [
        txn('income', 500, at),
        txn('expense', 70, at.subtract(const Duration(days: 1))),
        txn('expense', 999, at.add(const Duration(minutes: 1))), // after
        txn('savings_deposit', 300, at), // same bank account
      ],
      initialBalance: 1000,
      asOf: at,
    );
    expect(total, 1430);
  });

  Future<ProviderContainer> setup(Map<String, Object> prefs) async {
    SharedPreferences.setMockInitialValues(prefs);
    final p = await SharedPreferences.getInstance();
    final db = AppDatabase(executor: NativeDatabase.memory());
    final c = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(p),
        appDatabaseProvider.overrideWithValue(db),
        secureInitialBalanceProvider.overrideWithValue(1000),
      ],
    );
    addTearDown(() async {
      c.dispose();
      await db.close();
    });
    await c.read(transactionsProvider.future);
    return c;
  }

  Map<String, Object> bank(double balance) => {
    'sms_import_since': 1,
    'bank_balance': balance,
    'bank_balance_at': at.toIso8601String(),
  };

  test('reports a mismatch of at least one taka', () async {
    final c = await setup(bank(1478.45));
    final r = c.read(bankReconciliationProvider)!;
    expect((r.bank, r.app), (1478.45, 1000.0));
    expect(r.diff, closeTo(478.45, 1e-9));
  });

  test('hidden under one taka, when off, or with no bank balance', () async {
    expect(
      (await setup(bank(1000.5))).read(bankReconciliationProvider),
      isNull,
    );
    expect(
      (await setup(
        {...bank(5000)}..remove('sms_import_since'),
      )).read(bankReconciliationProvider),
      isNull,
    );
    expect(
      (await setup({'sms_import_since': 1})).read(bankReconciliationProvider),
      isNull,
    );
  });
}
