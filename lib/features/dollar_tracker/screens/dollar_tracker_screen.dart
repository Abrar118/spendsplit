import 'package:flutter/material.dart';

import '../../../core/widgets/empty_state.dart';

class DollarTrackerScreen extends StatelessWidget {
  const DollarTrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  ),
                  const SizedBox(width: 4),
                  Text('Dollar Tracker', style: theme.textTheme.titleLarge),
                  const Spacer(),
                  Text('2026', style: theme.textTheme.labelLarge),
                ],
              ),
              const SizedBox(height: 24),
              const Expanded(
                child: Center(
                  child: EmptyState(
                    icon: Icons.attach_money_rounded,
                    title: 'Dollar Tracker Placeholder',
                    message:
                        'This push route exists now so the dashboard contract is real. The isolated USD workflow lands in Phase 8.',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
