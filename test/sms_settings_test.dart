import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendsplit/providers/providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<(ProviderContainer, SharedPreferences)> setup([
    Map<String, Object> initial = const {},
  ]) async {
    SharedPreferences.setMockInitialValues(initial);
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    return (container, prefs);
  }

  test('enable and disable persist the watermark', () async {
    final (c, prefs) = await setup();
    final ctrl = c.read(appSettingsProvider.notifier);
    expect(c.read(appSettingsProvider).smsImportEnabled, isFalse);

    await ctrl.enableSmsImport(5000);
    expect(prefs.getInt('sms_import_since'), 5000);
    expect(c.read(appSettingsProvider).smsImportSince, 5000);

    await ctrl.disableSmsImport();
    expect(prefs.containsKey('sms_import_since'), isFalse);
    expect(c.read(appSettingsProvider).smsImportEnabled, isFalse);
  });

  test('loads persisted SMS state', () async {
    final (c, _) = await setup({
      'sms_import_since': 7000,
      'bank_balance': 480578.45,
      'bank_balance_at': DateTime(2026, 9, 21, 17, 28).toIso8601String(),
    });
    final s = c.read(appSettingsProvider);
    expect(s.smsImportSince, 7000);
    expect(s.bankBalance, 480578.45);
    expect(s.bankBalanceAt, DateTime(2026, 9, 21, 17, 28));
  });

  test('recordSmsImport only moves the watermark forward', () async {
    final (c, prefs) = await setup({'sms_import_since': 5000});
    final ctrl = c.read(appSettingsProvider.notifier);
    await ctrl.recordSmsImport(watermark: 6000, seenRefs: ['6100|a']);
    expect(prefs.getInt('sms_import_since'), 6000);
    expect(prefs.getStringList('sms_seen_refs'), ['6100|a']);
    await ctrl.recordSmsImport(watermark: 5500, seenRefs: const []);
    expect(prefs.getInt('sms_import_since'), 6000);
  });

  test('recordSmsImport is a no-op once import was switched off', () async {
    final (c, prefs) = await setup();
    await c
        .read(appSettingsProvider.notifier)
        .recordSmsImport(
          watermark: 6000,
          seenRefs: ['6000|a'],
          balance: 10,
          balanceAt: DateTime(2026, 9, 21),
        );
    expect(prefs.containsKey('sms_import_since'), isFalse);
    expect(prefs.containsKey('sms_seen_refs'), isFalse);
    expect(prefs.containsKey('bank_balance'), isFalse);
  });

  test('bank balance keeps the latest transaction time', () async {
    final (c, _) = await setup({'sms_import_since': 1});
    final ctrl = c.read(appSettingsProvider.notifier);
    await ctrl.recordSmsImport(
      watermark: 2,
      seenRefs: const [],
      balance: 200,
      balanceAt: DateTime(2026, 9, 21),
    );
    await ctrl.recordSmsImport(
      watermark: 3,
      seenRefs: const [],
      balance: 100,
      balanceAt: DateTime(2026, 9, 20),
    );
    expect(c.read(appSettingsProvider).bankBalance, 200);
  });

  test('restore keeps the backup watermark only with READ_SMS', () async {
    final (c, prefs) = await setup({
      'sms_import_since': 9000,
      'sms_seen_refs': ['9100|a'],
      'bank_balance': 1.0,
      'bank_balance_at': '2026-09-21T00:00:00.000',
    });
    final ctrl = c.read(appSettingsProvider.notifier);

    await ctrl.restoreSmsImport(since: 4000, readGranted: true);
    expect(prefs.getInt('sms_import_since'), 4000);
    // Restored rows carry their own sms_ref; the unique index dedupes.
    expect(prefs.getStringList('sms_seen_refs'), isEmpty);
    expect(prefs.containsKey('bank_balance'), isFalse);
    expect(c.read(appSettingsProvider).bankBalanceAt, isNull);

    await ctrl.restoreSmsImport(since: 4000, readGranted: false);
    expect(prefs.containsKey('sms_import_since'), isFalse);

    await ctrl.restoreSmsImport(since: null, readGranted: true);
    expect(c.read(appSettingsProvider).smsImportEnabled, isFalse);
  });

  test('restore reports when it switched SMS import off', () async {
    final (c, _) = await setup({'sms_import_since': 9000});
    final ctrl = c.read(appSettingsProvider.notifier);
    expect(await ctrl.restoreSmsImport(since: 4000, readGranted: true), false);
    expect(await ctrl.restoreSmsImport(since: null, readGranted: true), true);
    // Already off: nothing was switched off by this restore.
    expect(await ctrl.restoreSmsImport(since: null, readGranted: true), false);
  });
}
