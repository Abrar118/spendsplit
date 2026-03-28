import 'package:flutter/material.dart';

import '../../../core/utils/date_utils.dart';

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
            Text(
              formatMonthYear(DateTime.now()),
              style: theme.textTheme.headlineMedium,
            ),
            const Expanded(child: SizedBox.shrink()),
          ],
        ),
      ),
    );
  }
}
