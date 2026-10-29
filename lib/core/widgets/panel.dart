import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';

/// The one container: a square-cornered module one value step above the
/// ground. No border, no glow, no shadow.
class Panel extends StatelessWidget {
  const Panel({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.color = AppColors.surface,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final panel = DecoratedBox(
      decoration: AppDecorations.module(color: color),
      child: Padding(padding: padding, child: child),
    );

    if (margin == null) return panel;
    return Padding(padding: margin!, child: panel);
  }
}
