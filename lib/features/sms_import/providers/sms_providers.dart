import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/providers.dart';
import '../sms_gateway.dart';

final smsGatewayProvider = Provider<SmsGateway>((ref) => const SmsGateway());

final smsPermissionsProvider = FutureProvider.autoDispose<SmsPermissions>(
  (ref) => ref.watch(smsGatewayProvider).hasPermission(),
);

final needsReviewCountProvider = Provider<int>((ref) {
  final transactions = ref.watch(transactionsProvider).valueOrNull;
  return transactions?.where((t) => t.needsReview).length ?? 0;
});
