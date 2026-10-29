import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A budget bar: [used] (spent ÷ limit) filled, plus a tick at [pace] — the
/// share of the month already gone — so spending ahead of pace shows before
/// the limit is hit.
class BudgetProgressBar extends StatelessWidget {
  const BudgetProgressBar({
    required this.used,
    required this.color,
    this.pace,
    this.height = 8,
    this.backgroundColor = AppColors.surfaceContainerHighest,
    this.semanticsLabel,
    super.key,
  });

  final double used;
  final double? pace;
  final Color color;
  final double height;
  final Color backgroundColor;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final pace = this.pace;
    return SizedBox(
      height: height + 6,
      child: LayoutBuilder(
        builder: (context, box) => Stack(
          alignment: Alignment.centerLeft,
          children: [
            LinearProgressIndicator(
              value: used.clamp(0.0, 1.0),
              minHeight: height,
              borderRadius: BorderRadius.zero,
              color: color,
              backgroundColor: backgroundColor,
              semanticsLabel: semanticsLabel,
            ),
            if (pace != null)
              Positioned(
                left: (box.maxWidth * pace.clamp(0.0, 1.0)) - 1,
                top: 0,
                bottom: 0,
                child: Container(width: 2, color: AppColors.textPrimary),
              ),
          ],
        ),
      ),
    );
  }
}
