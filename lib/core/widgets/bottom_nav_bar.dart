import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.onAddPressed,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 12 + bottomInset),
      child: SizedBox(
        height: 78,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Positioned.fill(
              top: 12,
              child: DecoratedBox(
                decoration: AppDecorations.navBar(),
                child: Row(
                  children: [
                    Expanded(
                      child: _NavItem(
                        icon: LucideIcons.home,
                        label: 'HOME',
                        active: currentIndex == 0,
                        onTap: () => onDestinationSelected(0),
                      ),
                    ),
                    Expanded(
                      child: _NavItem(
                        icon: LucideIcons.receipt,
                        label: 'HISTORY',
                        active: currentIndex == 1,
                        onTap: () => onDestinationSelected(1),
                      ),
                    ),
                    const SizedBox(width: 72),
                    Expanded(
                      child: _NavItem(
                        icon: LucideIcons.calendarDays,
                        label: 'MONTHLY',
                        active: currentIndex == 3,
                        onTap: () => onDestinationSelected(3),
                      ),
                    ),
                    Expanded(
                      child: _NavItem(
                        icon: LucideIcons.flag,
                        label: 'GOALS',
                        active: currentIndex == 4,
                        onTap: () => onDestinationSelected(4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 0,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onAddPressed,
                  customBorder: const CircleBorder(),
                  child: Ink(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.primaryActionGradient,
                    ),
                    child: const Icon(
                      LucideIcons.plus,
                      color: AppColors.onPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = active ? AppColors.teal : AppColors.textSecondary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: foreground, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(color: foreground),
              ),
              const SizedBox(height: 5),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: active ? 1 : 0,
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: AppColors.teal,
                    shape: BoxShape.circle,
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
