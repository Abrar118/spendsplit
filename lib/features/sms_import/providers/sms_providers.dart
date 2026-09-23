import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/providers.dart';
import '../reconciliation.dart';
import '../sms_gateway.dart';

final smsGatewayProvider = Provider<SmsGateway>((ref) => const SmsGateway());

final smsPermissionsProvider = FutureProvider.autoDispose<SmsPermissions>(
  (ref) => ref.watch(smsGatewayProvider).hasPermission(),
);

final needsReviewCountProvider = Provider<int>((ref) {
  final transactions = ref.watch(transactionsProvider).valueOrNull;
  return transactions?.where((t) => t.needsReview).length ?? 0;
});

/// Non-null when the latest bank SMS balance and the app disagree by ≥ ৳1.
final bankReconciliationProvider = Provider<BankReconciliation?>((ref) {
  final settings = ref.watch(appSettingsProvider);
  final transactions = ref.watch(transactionsProvider).valueOrNull;
  final bank = settings.bankBalance;
  final at = settings.bankBalanceAt;
  if (!settings.smsImportEnabled ||
      bank == null ||
      at == null ||
      transactions == null) {
    return null;
  }
  final result = BankReconciliation(
    bank: bank,
    app: appTotalAsOf(
      transactions,
      initialBalance: settings.initialBalance,
      asOf: at,
    ),
  );
  return result.diff.abs() >= 1 ? result : null;
});
