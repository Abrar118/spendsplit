import 'package:flutter/material.dart';

import '../../../core/widgets/empty_state.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

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
                Text('Savings Goals', style: theme.textTheme.titleLarge),
                const Spacer(),
                TextButton(onPressed: null, child: const Text('+ New Goal')),
              ],
            ),
            const SizedBox(height: 24),
            const Expanded(
              child: Center(
                child: EmptyState(
                  icon: Icons.flag_outlined,
                  title: 'Goals Route Ready',
                  message:
                      'The structure is in place for goals, progress rings, and the create-goal flow in Phase 7.',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
