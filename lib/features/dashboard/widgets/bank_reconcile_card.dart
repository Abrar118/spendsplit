import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spendsplit/core/icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../providers/providers.dart';
import '../../sms_import/providers/sms_providers.dart';

/// Shown when the latest Trust Bank SMS balance disagrees with the app.
class BankReconcileCard extends ConsumerWidget {
  const BankReconcileCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = ref.watch(bankReconciliationProvider);
    if (r == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    String bdt(double v) => formatBdtAmount(v, fractionDigits: 0);

    return GlassCard(
      glowColor: AppColors.coral,
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.scale, color: AppColors.coral, size: 18),
              const SizedBox(width: 10),
              Text('Balance check', style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Bank ${bdt(r.bank)} · App ${bdt(r.app)} · off by ${bdt(r.diff.abs())}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Missing an entry? Add it and this clears. Otherwise, adjust the start balance.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final controller = ref.read(appSettingsProvider.notifier);
                final previous = ref.read(appSettingsProvider).initialBalance;
                await controller.setInitialBalance(previous + r.diff);
                messenger.showSnackBar(
                  SnackBar(
                    content: const Text('Start balance adjusted'),
                    duration: const Duration(seconds: 3),
                    action: SnackBarAction(
                      label: 'Undo',
                      onPressed: () => controller.setInitialBalance(previous),
                    ),
                  ),
                );
              },
              child: const Text('Adjust start balance'),
            ),
          ),
        ],
      ),
    );
  }
}
