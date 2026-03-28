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

class AnimatedAmountText extends StatefulWidget {
  const AnimatedAmountText({
    required this.value,
    required this.formatter,
    super.key,
    this.textStyle,
    this.textAlign = TextAlign.left,
    this.duration = const Duration(milliseconds: 650),
    this.curve = Curves.easeOutCubic,
  });

  final double value;
  final String Function(double value) formatter;
  final TextStyle? textStyle;
  final TextAlign textAlign;
  final Duration duration;
  final Curve curve;

  @override
  State<AnimatedAmountText> createState() => _AnimatedAmountTextState();
}

class _AnimatedAmountTextState extends State<AnimatedAmountText> {
  double _previousValue = 0;

  @override
  void didUpdateWidget(covariant AnimatedAmountText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _previousValue = oldWidget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: _previousValue, end: widget.value),
      duration: widget.duration,
      curve: widget.curve,
      builder: (context, animatedValue, _) {
        return Text(
          widget.formatter(animatedValue),
          style: widget.textStyle,
          textAlign: widget.textAlign,
        );
      },
    );
  }
}
