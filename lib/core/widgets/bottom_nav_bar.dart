import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spendsplit/core/icons/lucide_icons.dart';

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
      padding: EdgeInsets.fromLTRB(16, 0, 16, 10 + bottomInset),
      child: DecoratedBox(
        // Shadow on an outer box so it isn't clipped by the blur below.
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(28)),
          boxShadow: AppDecorations.navShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: AppDecorations.navFrost(),
            child: Container(
              height: 62 + MediaQuery.textScalerOf(context).scale(10),
              decoration: const BoxDecoration(gradient: AppDecorations.navSheen),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                children: [
                  Expanded(
                    child: _NavItem(
                      icon: LucideIcons.home,
                      label: 'Home',
                      active: currentIndex == 0,
                      onTap: () => onDestinationSelected(0),
                    ),
                  ),
                  Expanded(
                    child: _NavItem(
                      icon: LucideIcons.receipt,
                      label: 'History',
                      active: currentIndex == 1,
                      onTap: () => onDestinationSelected(1),
                    ),
                  ),
                  Expanded(child: _AddNavItem(onTap: onAddPressed)),
                  Expanded(
                    child: _NavItem(
                      icon: LucideIcons.calendarDays,
                      label: 'Monthly',
                      active: currentIndex == 3,
                      onTap: () => onDestinationSelected(3),
                    ),
                  ),
                  Expanded(
                    child: _NavItem(
                      icon: LucideIcons.flag,
                      label: 'Goals',
                      active: currentIndex == 4,
                      onTap: () => onDestinationSelected(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
    return Semantics(
      selected: active,
      button: true,
      label: label,
      child: GestureDetector(
        onTap: () {
          if (active) return;
          HapticFeedback.selectionClick();
          onTap();
        },
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: active
                  ? AppColors.teal.withValues(alpha: 0.14)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: foreground, size: 21),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: foreground,
                    fontSize: 10.5,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddNavItem extends StatelessWidget {
  const _AddNavItem({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.primaryActionGradient,
            boxShadow: [
              BoxShadow(
                color: Color(0x59ECBB7E),
                blurRadius: 16,
                spreadRadius: -2,
              ),
            ],
          ),
          child: const Icon(
            LucideIcons.plus,
            semanticLabel: 'Add transaction',
            color: AppColors.onPrimary,
            size: 24,
          ),
        ),
      ),
    );
  }
}
