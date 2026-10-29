import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spendsplit/core/icons/lucide_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';

/// A floating tab bar: a frosted-glass strip inset from the screen edges,
/// icon-only tabs (labels go to VoiceOver), and the add action as an orange
/// square.
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
      padding: EdgeInsets.fromLTRB(16, 0, 16, math.max(bottomInset, 12)),
      child: ClipRect(
        child: BackdropFilter(
          filter: AppDecorations.glassBlur(),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.navGlass,
              border: Border.all(color: AppColors.navGlassEdge, width: 0.5),
            ),
            child: SizedBox(
              height: 60,
              child: Row(
                children: [
                  _NavItem(
                    icon: LucideIcons.home,
                    label: 'Home',
                    active: currentIndex == 0,
                    onTap: () => onDestinationSelected(0),
                  ),
                  _NavItem(
                    icon: LucideIcons.receipt,
                    label: 'History',
                    active: currentIndex == 1,
                    onTap: () => onDestinationSelected(1),
                  ),
                  Expanded(child: _AddNavItem(onTap: onAddPressed)),
                  _NavItem(
                    icon: LucideIcons.calendarDays,
                    label: 'Monthly',
                    active: currentIndex == 3,
                    onTap: () => onDestinationSelected(3),
                  ),
                  _NavItem(
                    icon: LucideIcons.barChart3,
                    label: 'Graphs',
                    active: currentIndex == 4,
                    onTap: () => onDestinationSelected(4),
                  ),
                  _NavItem(
                    icon: LucideIcons.flag,
                    label: 'Goals',
                    active: currentIndex == 5,
                    onTap: () => onDestinationSelected(5),
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
    final foreground = active ? AppColors.textPrimary : AppColors.textTertiary;
    return Expanded(
      child: Semantics(
        selected: active,
        button: true,
        label: label,
        excludeSemantics: true,
        child: InkResponse(
          onTap: () {
            if (active) return;
            HapticFeedback.selectionClick();
            onTap();
          },
          radius: 32,
          child: SizedBox(
            height: 60,
            child: Center(child: Icon(icon, color: foreground, size: 24)),
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
    return Semantics(
      button: true,
      label: 'Add transaction',
      excludeSemantics: true,
      child: Center(
        child: Material(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(AppDecorations.radius),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppDecorations.radius),
            onTap: () {
              HapticFeedback.lightImpact();
              onTap();
            },
            child: const SizedBox(
              width: 52,
              height: 44,
              child: Icon(
                LucideIcons.plus,
                color: AppColors.onPrimary,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
