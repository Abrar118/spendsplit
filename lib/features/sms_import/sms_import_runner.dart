import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../providers/providers.dart';
import 'providers/sms_providers.dart';
import 'sms_importer.dart';

final smsImportRunnerProvider = Provider<SmsImportRunner>(
  (ref) => SmsImportRunner(ref),
);

/// iOS can't read the SMS inbox. A Shortcuts automation instead saves each
/// bank SMS as a file in this folder (shown in Files > SpendSplit). Null off
/// iOS.
Future<Directory?> smsInboxDirectory() async {
  if (!Platform.isIOS) return null;
  final documents = await getApplicationDocumentsDirectory();
  return Directory(p.join(documents.path, 'SMS Inbox')).create(recursive: true);
}

/// Text copied from Messages is saved by Shortcuts as rich text (RTFD), not
/// UTF-8, so iOS decodes it natively (AppDelegate.swift). Plain text too.
Future<String> readInboxText(File file) async {
  if (!Platform.isIOS) return file.readAsString();
  final text = await const MethodChannel(
    'spendsplit/text',
  ).invokeMethod<String>('plainText', file.path);
  if (text == null) throw FormatException('Unreadable file', file.path);
  return text;
}

/// Imports Trust Bank SMS newer than the watermark, one run at a time.
/// Never throws; returns the number of transactions inserted.
class SmsImportRunner {
  SmsImportRunner(
    this._ref, {
    this.retryDelay = const Duration(seconds: 1),
    this.lookback = const Duration(minutes: 10),
    this.inboxDirectory = smsInboxDirectory,
    this.readInboxFile = readInboxText,
  });

  final Ref _ref;
  final Future<Directory?> Function() inboxDirectory;
  final Future<String> Function(File file) readInboxFile;
  final Duration retryDelay;

  /// How far behind the newest SMS the watermark trails. The SMS app can
  /// write a message to the inbox after a later-dated one; this window is
  /// re-read every run and already-processed refs are skipped.
  // ponytail: fixed 10 min window; widen if late inbox writes ever lag more.
  final Duration lookback;

  static const _retries = 4;
  Future<Object?>? _inFlight;

  /// [waitForNew]: an SMS just arrived. The default SMS app may not have
  /// written it to the inbox yet, so re-read for a few seconds.
  Future<int> run({bool waitForNew = false}) =>
      _serialized(() => _runOnce(waitForNew));

  /// Runs [action] with no import in flight and none starting until it
  /// ends. Backup restore uses this so an import can't straddle the swap.
  Future<T> whilePaused<T>(Future<T> Function() action) => _serialized(action);

  Future<T> _serialized<T>(Future<T> Function() body) async {
    while (_inFlight != null) {
      try {
        await _inFlight;
      } catch (_) {
        // The owner of that future reports its own failure.
      }
    }
    final current = body();
    _inFlight = current;
    try {
      return await current;
    } finally {
      if (identical(_inFlight, current)) _inFlight = null;
    }
  }

  Future<int> _runOnce(bool waitForNew) async {
    try {
      final inbox = await inboxDirectory();
      if (inbox != null) return await _runInboxFolder(inbox);
      // The other engine may have advanced the watermark or seen refs.
      await _ref.read(appSettingsProvider.notifier).reloadFromDisk();
      final settings = _ref.read(appSettingsProvider);
      final since = settings.smsImportSince;
      if (since == null) return 0;
      final gateway = _ref.read(smsGatewayProvider);
      if (!(await gateway.hasPermission()).read) return 0;

      final seen = settings.smsSeenRefs.toSet();
      var messages = await gateway.readInbox(sinceMillis: since);
      List<InboxSms> fresh() =>
          messages.where((m) => !seen.contains(m.ref)).toList();
      for (var i = 0; waitForNew && fresh().isEmpty && i < _retries; i++) {
        await Future<void>.delayed(retryDelay);
        messages = await gateway.readInbox(sinceMillis: since);
      }
      if (messages.isEmpty) return 0;

      final result = await importSmsMessages(
        _ref.read(appDatabaseProvider),
        fresh(),
      );
      final newest = messages.map((m) => m.receivedMillis).reduce(max);
      final watermark = max(since, newest - lookback.inMilliseconds);
      final seenRefs = {
        ...seen,
        ...messages.map((m) => m.ref),
      }.where((ref) => receivedMillisOfRef(ref) > watermark).toList();
      // Only after a successful import, so a failure rereads next time.
      // Seen refs keep these from being counted twice.
      final settingsController = _ref.read(appSettingsProvider.notifier);
      await settingsController.recordSmsUnparsed(result.unparsed);
      await settingsController.recordSmsImport(
        watermark: watermark,
        seenRefs: seenRefs,
        balance: result.latest?.balance,
        balanceAt: result.latest?.dateTime,
      );
      return result.inserted;
    } catch (error, stack) {
      debugPrint('SMS import failed: $error\n$stack');
      return 0;
    }
  }

  /// iOS: imports every file in [inbox], then deletes it. Files are removed
  /// only after the insert commits; a file left behind by a crash re-imports
  /// to the same `sms_ref` (receive time = file mtime) and is dropped.
  Future<int> _runInboxFolder(Directory inbox) async {
    final files = <File>[];
    final messages = <InboxSms>[];
    for (final entity in inbox.listSync()) {
      if (entity is! File || p.basename(entity.path).startsWith('.')) continue;
      try {
        messages.add(
          InboxSms(
            body: (await readInboxFile(entity)).trim(),
            receivedMillis:
                (await entity.lastModified()).millisecondsSinceEpoch,
          ),
        );
        files.add(entity);
      } catch (error) {
        // Kept for a later run (or the user) rather than lost; never blocks
        // the rest.
        debugPrint('SMS inbox: skipped ${entity.path}: $error');
      }
    }
    if (files.isEmpty) return 0;
    final result = await importSmsMessages(
      _ref.read(appDatabaseProvider),
      messages,
    );
    for (final file in files) {
      await file.delete();
    }

    final settings = _ref.read(appSettingsProvider.notifier);
    // recordSmsImport is a no-op until "enabled"; the bank balance needs it.
    if (!_ref.read(appSettingsProvider).smsImportEnabled) {
      await settings.enableSmsImport(DateTime.now().millisecondsSinceEpoch);
    }
    await settings.recordSmsUnparsed(result.unparsed);
    await settings.recordSmsImport(
      watermark: 0,
      seenRefs: const [],
      balance: result.latest?.balance,
      balanceAt: result.latest?.dateTime,
    );
    return result.inserted;
  }
}
