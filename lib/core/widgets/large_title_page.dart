import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// A top-level tab: an iOS large title that collapses to an inline title on
/// scroll, with [slivers] beneath.
class LargeTitlePage extends StatelessWidget {
  const LargeTitlePage({
    required this.title,
    required this.slivers,
    this.trailing,
    super.key,
  });

  final String title;
  final List<Widget> slivers;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    // Inside a CupertinoPageScaffold the bar shows its material and hairline
    // only once content scrolls under the collapsed title, as on iOS.
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: Text(title),
            trailing: trailing,
            automaticallyImplyLeading: false,
            // Tabs swap in place; there is no route transition to animate.
            transitionBetweenRoutes: false,
            backgroundColor: AppColors.navBar,
            border: const Border(
              bottom: BorderSide(color: AppColors.hairline, width: 0.5),
            ),
            padding: const EdgeInsetsDirectional.only(start: 16, end: 4),
          ),
          ...slivers,
        ],
      ),
    );
  }
}

/// The list body of a [LargeTitlePage]: page gutters, room under the tab
/// bar, and [children] in order.
class PageBody extends StatelessWidget {
  const PageBody({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.navClearance,
      ),
      sliver: SliverList.list(children: children),
    );
  }
}

/// A 44pt icon action for a [LargeTitlePage] bar.
class BarIconButton extends StatelessWidget {
  const BarIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 44, height: 44),
      icon: Icon(icon, color: color ?? AppColors.textSecondary, size: 22),
    );
  }
}
