import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendsplit/data/database/app_database.dart';
import 'package:spendsplit/features/sms_import/sms_import_runner.dart';
import 'package:spendsplit/providers/providers.dart';

String debit(int amount) =>
    'POS Txn\nTK $amount.00 DEBIT\nAC No 031***492\n21/09/2026 05:28 PM\n'
    'Balance TK 1000.00';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // iOS: a Shortcuts automation drops one file per bank SMS into a folder.
  Future<(ProviderContainer, AppDatabase, Directory)> setup({
    Future<String> Function(File file)? readText,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase(executor: NativeDatabase.memory());
    final dir = Directory.systemTemp.createTempSync('sms_inbox');
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appDatabaseProvider.overrideWithValue(db),
        smsImportRunnerProvider.overrideWith(
          (ref) => SmsImportRunner(
            ref,
            inboxDirectory: () async => dir,
            readInboxFile: readText ?? (file) => file.readAsString(),
          ),
        ),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await db.close();
      dir.deleteSync(recursive: true);
    });
    return (container, db, dir);
  }

  File drop(Directory dir, String name, String body, {int millis = 1000}) {
    final file = File('${dir.path}/$name')..writeAsStringSync(body);
    file.setLastModifiedSync(DateTime.fromMillisecondsSinceEpoch(millis));
    return file;
  }

  test(
    'imports each dropped file as a needs-review row, then deletes it',
    () async {
      final (container, db, dir) = await setup();
      final a = drop(dir, 'a.txt', debit(70), millis: 1000);
      final b = drop(dir, 'b.txt', debit(30), millis: 2000);

      expect(await container.read(smsImportRunnerProvider).run(), 2);

      final rows = await db.select(db.transactionsTable).get();
      expect(rows.map((r) => r.amount).toSet(), {70, 30});
      expect(rows.every((r) => r.needsReview), isTrue);
      expect(a.existsSync() || b.existsSync(), isFalse);
    },
  );

  test('a re-dropped identical file is not imported twice', () async {
    final (container, db, dir) = await setup();
    final runner = container.read(smsImportRunnerProvider);
    drop(dir, 'a.txt', debit(70));
    expect(await runner.run(), 1);
    drop(dir, 'a.txt', debit(70));
    expect(await runner.run(), 0);
    expect(await db.select(db.transactionsTable).get(), hasLength(1));
    expect(dir.listSync(), isEmpty);
  });

  test(
    'non-bank files are discarded; transaction-like ones are counted',
    () async {
      final (container, db, dir) = await setup();
      drop(dir, 'otp.txt', 'Your code is 123456');
      drop(dir, 'odd.txt', 'New format: DEBIT of something');

      expect(await container.read(smsImportRunnerProvider).run(), 0);

      expect(await db.select(db.transactionsTable).get(), isEmpty);
      expect(dir.listSync(), isEmpty);
      expect(container.read(appSettingsProvider).smsUnparsedCount, 1);
    },
  );

  test('records the bank balance for reconciliation', () async {
    final (container, _, dir) = await setup();
    drop(dir, 'a.txt', debit(70));
    await container.read(smsImportRunnerProvider).run();
    expect(container.read(appSettingsProvider).bankBalance, 1000);
  });

  // Copied from Messages, Shortcuts saves rich text (RTFD); the native reader
  // hands back this plain text, trailing promo line included.
  test('imports the real Trust Bank alert text', () async {
    final (container, db, dir) = await setup();
    drop(
      dir,
      'Oct 28, 2026 at 10:46 PM',
      'POS Txn\nTK 699.00 DEBIT\nAC No 031***492\n28/10/2026 10:47 AM\n'
          'Balance TK 371096.22\n'
          'Call Center at your fingertips: t.tblbd.com/SIVR',
    );
    expect(await container.read(smsImportRunnerProvider).run(), 1);
    expect((await db.select(db.transactionsTable).get()).single.amount, 699);
  });

  test('an unreadable file is kept and does not block the others', () async {
    final (container, db, dir) = await setup(
      readText: (file) async => file.path.endsWith('bad')
          ? throw const FormatException('not text')
          : file.readAsString(),
    );
    final bad = drop(dir, 'bad', 'whatever');
    drop(dir, 'good.txt', debit(70));

    expect(await container.read(smsImportRunnerProvider).run(), 1);
    expect(bad.existsSync(), isTrue);
    expect(await db.select(db.transactionsTable).get(), hasLength(1));
  });
}
