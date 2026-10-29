import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A square-ended progress bar on a hairline track. Fills once, easing out.
class FlatBar extends StatelessWidget {
  const FlatBar({
    required this.value,
    required this.color,
    this.height = 6,
    super.key,
  });

  final double value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 700),
          curve: Curves.easeOutExpo,
          builder: (context, v, _) => Stack(
            children: [
              const Positioned.fill(
                child: ColoredBox(color: AppColors.surfaceContainerHighest),
              ),
              FractionallySizedBox(
                widthFactor: v,
                heightFactor: 1,
                child: ColoredBox(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
