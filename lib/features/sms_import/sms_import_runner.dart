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
  SmsImportRunner(this._ref, {this.retryDelay = const Duration(seconds: 1)});

  final Ref _ref;
  final Duration retryDelay;
  static const _retries = 4;
  Future<int>? _inFlight;

  /// [waitForNew]: an SMS just arrived. The default SMS app may not have
  /// written it to the inbox yet, so re-read for a few seconds.
  Future<int> run({bool waitForNew = false}) async {
    while (_inFlight != null) {
      await _inFlight;
    }
    final current = _inFlight = _runOnce(waitForNew);
    try {
      return await current;
    } finally {
      if (identical(_inFlight, current)) _inFlight = null;
    }
  }

  Future<int> _runOnce(bool waitForNew) async {
    try {
      final since = _ref.read(appSettingsProvider).smsImportSince;
      if (since == null) return 0;
      final gateway = _ref.read(smsGatewayProvider);
      if (!(await gateway.hasPermission()).read) return 0;

      var messages = await gateway.readInbox(sinceMillis: since);
      for (var i = 0; waitForNew && messages.isEmpty && i < _retries; i++) {
        await Future<void>.delayed(retryDelay);
        messages = await gateway.readInbox(sinceMillis: since);
      }
      if (messages.isEmpty) return 0;

      final result = await importSmsMessages(
        _ref.read(appDatabaseProvider),
        messages,
      );
      // Only after a successful import, so a failure rereads next time.
      await _ref
          .read(appSettingsProvider.notifier)
          .recordSmsImport(
            newestReceivedMillis: result.newestReceivedMillis!,
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
