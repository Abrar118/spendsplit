import 'dart:io';

import 'package:flutter/services.dart';

import 'sms_importer.dart';

class SmsPermissions {
  const SmsPermissions({required this.read, required this.receive});

  factory SmsPermissions.fromMap(Map<Object?, Object?>? map) => SmsPermissions(
    read: map?['read'] == true,
    receive: map?['receive'] == true,
  );

  static const none = SmsPermissions(read: false, receive: false);

  final bool read;
  final bool receive;
}

/// Dart side of the `spendsplit/sms` channel (see SmsBridge.kt). Android
/// only; everywhere else it reports no permission and an empty inbox.
class SmsGateway {
  const SmsGateway();

  static const channel = MethodChannel('spendsplit/sms');

  Future<SmsPermissions> hasPermission() => _permissions('hasPermission');

  Future<SmsPermissions> requestPermission() =>
      _permissions('requestPermission');

  Future<SmsPermissions> _permissions(String method) async {
    if (!Platform.isAndroid) return SmsPermissions.none;
    return SmsPermissions.fromMap(
      await channel.invokeMapMethod<Object?, Object?>(method),
    );
  }

  /// Trust Bank SMS received strictly after [sinceMillis], oldest first.
  Future<List<InboxSms>> readInbox({required int sinceMillis}) async {
    if (!Platform.isAndroid) return const [];
    final rows =
        await channel.invokeListMethod<Map<Object?, Object?>>('readInbox', {
          'sinceMillis': sinceMillis,
        }) ??
        const [];
    return [
      for (final row in rows)
        InboxSms(
          body: row['body']! as String,
          receivedMillis: row['date']! as int,
        ),
    ];
  }

  /// Headless engine only: tells SmsReceiver the background run finished.
  Future<void> backgroundDone() => channel.invokeMethod<void>('backgroundDone');
}
