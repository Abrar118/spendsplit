import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendsplit/data/database/app_database.dart';
import 'package:spendsplit/features/sms_import/providers/sms_providers.dart';
import 'package:spendsplit/features/sms_import/sms_gateway.dart';
import 'package:spendsplit/features/sms_import/sms_import_runner.dart';
import 'package:spendsplit/features/sms_import/sms_importer.dart';
import 'package:spendsplit/providers/providers.dart';

import 'support/fake_sms_gateway.dart';

String debit(int amount) =>
    'POS Txn\nTK $amount.00 DEBIT\nAC No 031***492\n21/09/2026 05:28 PM\n'
    'Balance TK 1000.00';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<(SmsImportRunner, AppDatabase, FakeSmsGateway, SharedPreferences)>
  setup({int? since = 5000}) async {
    SharedPreferences.setMockInitialValues({'sms_import_since': ?since});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase(executor: NativeDatabase.memory());
    final gateway = FakeSmsGateway();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appDatabaseProvider.overrideWithValue(db),
        smsGatewayProvider.overrideWithValue(gateway),
        smsImportRunnerProvider.overrideWith(
          (ref) => SmsImportRunner(ref, retryDelay: Duration.zero),
        ),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await db.close();
    });
    return (container.read(smsImportRunnerProvider), db, gateway, prefs);
  }

  test('does nothing while switched off', () async {
    final (runner, _, gateway, _) = await setup(since: null);
    gateway.inbox.add(InboxSms(body: debit(70), receivedMillis: 6000));
    expect(await runner.run(), 0);
    expect(gateway.sinceCalls, isEmpty);
  });

  test('does nothing without READ_SMS', () async {
    final (runner, _, gateway, _) = await setup();
    gateway.permissions = SmsPermissions.none;
    gateway.inbox.add(InboxSms(body: debit(70), receivedMillis: 6000));
    expect(await runner.run(), 0);
    expect(gateway.sinceCalls, isEmpty);
  });

  test('imports only SMS newer than the watermark, then advances it', () async {
    final (runner, db, gateway, prefs) = await setup();
    gateway.inbox.addAll([
      InboxSms(body: debit(1), receivedMillis: 4000), // before enabling
      InboxSms(body: debit(70), receivedMillis: 6000),
    ]);
    expect(await runner.run(), 1);
    expect((await db.select(db.transactionsTable).get()).single.amount, 70);
    expect(prefs.getInt('sms_import_since'), 6000);
    expect(prefs.getDouble('bank_balance'), 1000);
  });

  test('a deleted imported entry is not imported again', () async {
    final (runner, db, gateway, _) = await setup();
    gateway.inbox.add(InboxSms(body: debit(70), receivedMillis: 6000));
    await runner.run();
    await db.delete(db.transactionsTable).go();
    expect(await runner.run(), 0);
    expect(await db.select(db.transactionsTable).get(), isEmpty);
    expect(gateway.sinceCalls.last, 6000);
  });

  test('a failed read leaves the watermark alone', () async {
    final (runner, _, gateway, prefs) = await setup();
    gateway.failWith = Exception('provider unavailable');
    expect(await runner.run(), 0);
    expect(prefs.getInt('sms_import_since'), 5000);
  });

  test('waitForNew retries until the SMS reaches the inbox', () async {
    final (runner, _, gateway, _) = await setup();
    gateway.onRead = (n) {
      if (n == 3) {
        gateway.inbox.add(InboxSms(body: debit(70), receivedMillis: 6000));
      }
    };
    expect(await runner.run(waitForNew: true), 1);
    expect(gateway.sinceCalls, hasLength(3));
  });

  test('without waitForNew an empty inbox is read once', () async {
    final (runner, _, gateway, _) = await setup();
    expect(await runner.run(), 0);
    expect(gateway.sinceCalls, hasLength(1));
  });

  test('overlapping runs are serialized', () async {
    final (runner, _, gateway, _) = await setup();
    gateway.inbox.add(InboxSms(body: debit(70), receivedMillis: 6000));
    expect(await Future.wait([runner.run(), runner.run()]), [1, 0]);
    expect(gateway.sinceCalls, [5000, 6000]);
  });
}
