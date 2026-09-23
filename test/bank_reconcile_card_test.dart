import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendsplit/data/database/app_database.dart';
import 'package:spendsplit/data/repositories/secure_storage_repository.dart';
import 'package:spendsplit/features/dashboard/widgets/bank_reconcile_card.dart';
import 'package:spendsplit/providers/providers.dart';

void main() {
  testWidgets('Adjust start balance can be undone', (tester) async {
    SharedPreferences.setMockInitialValues({
      'sms_import_since': 1,
      'bank_balance': 1478.0,
      'bank_balance_at': DateTime(2026, 9, 21, 17, 28).toIso8601String(),
    });
    FlutterSecureStorage.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase(executor: NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appDatabaseProvider.overrideWithValue(db),
        secureStorageProvider.overrideWithValue(
          SecureStorageRepository(const FlutterSecureStorage()),
        ),
        secureInitialBalanceProvider.overrideWithValue(1000),
      ],
    );
    await tester.runAsync(() => container.read(transactionsProvider.future));

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: BankReconcileCard())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Adjust start balance'));
    await tester.pumpAndSettle();
    expect(container.read(appSettingsProvider).initialBalance, 1478);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(container.read(appSettingsProvider).initialBalance, 1000);

    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
    final closing = db.close();
    await tester.pump(const Duration(milliseconds: 1));
    await closing;
  });
}
