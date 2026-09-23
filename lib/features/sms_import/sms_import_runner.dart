import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';
import 'providers/sms_providers.dart';
import 'sms_importer.dart';

final smsImportRunnerProvider = Provider<SmsImportRunner>(
  (ref) => SmsImportRunner(ref),
);

/// Imports Trust Bank SMS newer than the watermark, one run at a time.
/// Never throws; returns the number of transactions inserted.
class SmsImportRunner {
  SmsImportRunner(
    this._ref, {
    this.retryDelay = const Duration(seconds: 1),
    this.lookback = const Duration(minutes: 10),
  });

  final Ref _ref;
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
      await _ref
          .read(appSettingsProvider.notifier)
          .recordSmsImport(
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
}
