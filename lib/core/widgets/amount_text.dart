import 'package:flutter/material.dart';

import '../theme/app_decorations.dart';

class AmountText extends StatelessWidget {
  const AmountText({
    required this.amount,
    super.key,
    this.prefix = '৳',
    this.color,
    this.textStyle,
    this.glow = false,
    this.alignment = TextAlign.left,
  });

  final String amount;
  final String prefix;
  final Color? color;
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
        boxShadow: glow ? AppDecorations.contextualGlow() : const [],
      ),
      child: Text(
        '$prefix $amount',
        textAlign: alignment,
        style: resolvedStyle,
      ),
    );
  }
}
