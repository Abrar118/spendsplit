import 'package:flutter/material.dart';

import '../../../core/widgets/accent_chip.dart';
import '../../../core/widgets/empty_state.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

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
                Text('Transactions', style: theme.textTheme.titleLarge),
                const Spacer(),
                const Icon(Icons.filter_alt_outlined),
              ],
            ),
            const SizedBox(height: 20),
            const SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  AccentChip(label: 'All', selected: true),
                  SizedBox(width: 10),
                  AccentChip(label: 'Income', selected: false),
                  SizedBox(width: 10),
                  AccentChip(label: 'Expense', selected: false),
                  SizedBox(width: 10),
                  AccentChip(label: 'Savings', selected: false),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Expanded(
              child: Center(
                child: EmptyState(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'No Transactions Yet',
                  message:
                      'Tap the center add button to open the transaction sheet.',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
