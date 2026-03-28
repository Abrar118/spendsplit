import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
                    icon: const Icon(LucideIcons.chevronLeft),
                  ),
                  const SizedBox(width: 4),
                  Text('Dollar Tracker', style: theme.textTheme.titleLarge),
                  const Spacer(),
                  Text('2026', style: theme.textTheme.labelLarge),
                ],
              ),
              const Expanded(child: SizedBox.shrink()),
            ],
          ),
        ),
      ),
    );
  }
}
