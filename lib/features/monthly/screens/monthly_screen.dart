import 'package:flutter/material.dart';

import '../../../core/widgets/empty_state.dart';

class MonthlyScreen extends StatelessWidget {
  const MonthlyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 132),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.menu_rounded),
                const SizedBox(width: 12),
                Text('SpendSplit', style: theme.textTheme.titleLarge),
                const Spacer(),
                IconButton(
                  onPressed: null,
                  icon: const Icon(Icons.settings_outlined),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('FISCAL PERIOD', style: theme.textTheme.labelMedium),
            const SizedBox(height: 8),
            Text('March 2026', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 24),
            const Expanded(
              child: Center(
                child: EmptyState(
                  icon: Icons.calendar_month_outlined,
                  title: 'Monthly Analytics Placeholder',
                  message:
                      'Phase 1 only establishes the route and shell. Charts and comparisons land in Phase 6.',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
