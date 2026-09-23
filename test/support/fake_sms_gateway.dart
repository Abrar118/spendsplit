import 'package:spendsplit/features/sms_import/sms_gateway.dart';
import 'package:spendsplit/features/sms_import/sms_importer.dart';

class FakeSmsGateway extends SmsGateway {
  FakeSmsGateway({
    this.permissions = const SmsPermissions(read: true, receive: true),
  });

  SmsPermissions permissions;

  /// What [requestPermission] grants.
  SmsPermissions grantOnRequest = const SmsPermissions(
    read: true,
    receive: true,
  );

  final inbox = <InboxSms>[];
  final sinceCalls = <int>[];
  Object? failWith;

  /// Called with the 1-based read count before each read.
  void Function(int readCount)? onRead;

  @override
  Future<SmsPermissions> hasPermission() async => permissions;

  @override
  Future<SmsPermissions> requestPermission() async =>
      permissions = grantOnRequest;

  @override
  Future<List<InboxSms>> readInbox({required int sinceMillis}) async {
    sinceCalls.add(sinceMillis);
    onRead?.call(sinceCalls.length);
    if (failWith != null) throw failWith!;
    // Mirrors SmsBridge.kt: strictly newer than the watermark, oldest first.
    return inbox.where((m) => m.receivedMillis > sinceMillis).toList()
      ..sort((a, b) => a.receivedMillis.compareTo(b.receivedMillis));
  }
}
