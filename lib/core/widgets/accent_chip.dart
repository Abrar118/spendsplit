import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AccentChip extends StatelessWidget {
  const AccentChip({
    required this.label,
    required this.selected,
    super.key,
    this.color = AppColors.teal,
    this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color : theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? color.withValues(alpha: 0.12)
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.26),
            ),
          ),
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: selected ? AppColors.onPrimary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
