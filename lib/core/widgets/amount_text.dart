import 'package:flutter/material.dart';

/// An amount that counts from its previous value to the new one. Snaps
/// straight to the value when the user has Reduce Motion on.
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
    final text = widget.formatter(widget.value);
    if (MediaQuery.disableAnimationsOf(context)) {
      return Text(text, style: widget.textStyle, textAlign: widget.textAlign);
    }
    return Semantics(
      label: text,
      excludeSemantics: true,
      child: TweenAnimationBuilder<double>(
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
      ),
    );
  }
}
