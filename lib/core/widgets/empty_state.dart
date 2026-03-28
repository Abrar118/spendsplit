import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_colors.dart';
import 'glass_card.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
          glowColor: AppColors.blue,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.24,
                    ),
                  ),
                ),
                child: Icon(icon, color: AppColors.teal, size: 28),
              ),
              const SizedBox(height: 18),
              Text(title, style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 280.ms)
        .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic);
  }
}
