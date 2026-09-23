import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spendsplit/core/icons/lucide_icons.dart';

import '../../../core/constants/enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../sms_import/providers/sms_providers.dart';

/// "N SMS entries to review" — opens Transactions filtered to them.
class SmsReviewCard extends ConsumerWidget {
  const SmsReviewCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(needsReviewCountProvider);
    return GestureDetector(
      onTap: () => context.go('${AppRoute.transactions.path}?review=1'),
      child: GlassCard(
        glowColor: AppColors.amber,
        radius: 20,
        child: Row(
          children: [
            const Icon(
              LucideIcons.messageSquare,
              color: AppColors.amber,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$count SMS ${count == 1 ? 'entry' : 'entries'} to review',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const Icon(
              LucideIcons.chevronRight,
              color: AppColors.textSecondary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
