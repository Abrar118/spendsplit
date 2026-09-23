import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';
import 'widget_data_service.dart';

/// `WidgetRef.read` and `ProviderContainer.read` both fit this.
typedef ProviderReader = T Function<T>(ProviderListenable<T> provider);

/// Pushes the current Available balance to the home-screen widget.
Future<void> syncHomeWidget(ProviderReader read) async {
  final balance = read(balanceSummaryProvider).valueOrNull;
  if (balance == null) return;

  final savingsPercent =
      (read(savingsInsightsProvider).valueOrNull?.monthOverMonthDelta ?? 0) *
      100;

  await WidgetDataService.updateBalance(
    availableBalance: balance.availableBalance,
    savingsPercent: savingsPercent,
  );
}
