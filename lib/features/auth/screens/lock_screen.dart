import 'package:flutter/material.dart';

import '../../../core/widgets/empty_state.dart';

class LockScreen extends StatelessWidget {
  const LockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: EmptyState(
              icon: Icons.fingerprint_rounded,
              title: 'Lock Screen Placeholder',
              message:
                  'Biometric routing and unlock flow are scheduled for Phase 9.',
            ),
          ),
        ),
      ),
    );
  }
}
