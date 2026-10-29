import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/flat_bar.dart';
import '../../../core/widgets/panel.dart';

/// How far all active goals are funded together, with a plain-language
/// forecast for the next one.
class OverallProgressCard extends StatelessWidget {
  const OverallProgressCard({
    required this.progress,
    required this.title,
    required this.body,
    this.showProgress = true,
    this.late = false,
    super.key,
  });

  final double progress;
  final String title;
  final String body;

  /// Off with a single goal, whose own card already shows its progress.
  final bool showProgress;

  /// The forecast lands after the goal's deadline.
  final bool late;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = (progress.clamp(0.0, 1.0) * 100).round();
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: late ? AppColors.warning : null,
                  ),
                ),
              ),
              if (showProgress)
                Text(
                  '$pct%',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.savings,
                  ),
                ),
            ],
          ),
          if (showProgress) ...[
            const SizedBox(height: 10),
            FlatBar(value: progress, color: AppColors.savings),
          ],
          const SizedBox(height: 10),
          Text(body, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
