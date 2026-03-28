import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';

class AmountText extends StatelessWidget {
  const AmountText({
    required this.amount,
    super.key,
    this.prefix = '৳',
    this.color,
    this.glowColor,
    this.textStyle,
    this.glow = false,
    this.alignment = TextAlign.left,
  });

  final String amount;
  final String prefix;
  final Color? color;
  final Color? glowColor;
  final TextStyle? textStyle;
  final bool glow;
  final TextAlign alignment;

  @override
  Widget build(BuildContext context) {
    final resolvedStyle =
        (textStyle ?? Theme.of(context).textTheme.headlineMedium)?.copyWith(
          color: color,
        );

    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: glow
            ? AppDecorations.contextualGlow(
                color: glowColor ?? color ?? AppColors.green,
              )
            : const [],
      ),
      child: Text(
        '$prefix $amount',
        textAlign: alignment,
        style: resolvedStyle,
      ),
    );
  }
}
