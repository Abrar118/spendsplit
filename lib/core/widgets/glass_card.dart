import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';

class GlassCard extends StatelessWidget {
  const GlassCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.glowColor,
    this.color = AppColors.glassCardFill,
    this.radius = 20,
    this.opacity = 1,
    this.shadow = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? glowColor;
  final Color color;
  final double radius;
  final double opacity;

  /// The soft drop shadow under the card. Off on Home, Monthly and Goals.
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final card = DecoratedBox(
      decoration: AppDecorations.glassCard(
        color: color,
        glowColor: glowColor,
        radius: radius,
        opacity: opacity,
        shadow: shadow,
      ),
      child: Padding(padding: padding, child: child),
    );

    if (margin == null) return card;
    return Padding(padding: margin!, child: card);
  }
}
