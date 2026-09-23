import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../sms_gateway.dart';

final smsGatewayProvider = Provider<SmsGateway>((ref) => const SmsGateway());

final smsPermissionsProvider = FutureProvider.autoDispose<SmsPermissions>(
  (ref) => ref.watch(smsGatewayProvider).hasPermission(),
);
