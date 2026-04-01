import 'package:flutter/material.dart';

import '../theme/app_decorations.dart';

class GlassCard extends StatelessWidget {
  const GlassCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.glowColor,
    this.radius = 20,
    this.opacity = 1,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? glowColor;
  final double radius;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final card = DecoratedBox(
      decoration: AppDecorations.glassCard(
        glowColor: glowColor,
        radius: radius,
        opacity: opacity,
      ),
      child: Padding(padding: padding, child: child),
    );

    if (margin == null) return card;
    return Padding(padding: margin!, child: card);
  }
}
