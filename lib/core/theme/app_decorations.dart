import 'dart:ui';

import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppDecorations {
  static Border ghostBorder({double opacity = 0.2}) {
    return Border.all(
      color: AppColors.outlineVariant.withValues(alpha: opacity),
    );
  }

  static List<BoxShadow> ambientGlow(Color color) {
    return [
      BoxShadow(
        color: color.withValues(alpha: 0.05),
        blurRadius: 40,
        offset: const Offset(0, 18),
      ),
    ];
  }

  static List<BoxShadow> contextualGlow({Color color = AppColors.green}) {
    return [
      BoxShadow(
        color: color.withValues(alpha: 0.24),
        blurRadius: 18,
        spreadRadius: 0,
      ),
    ];
  }

  static List<BoxShadow> heroInnerGlow() {
    return const [
      BoxShadow(
        color: Color(0x1AFFFFFF),
        blurRadius: 1,
        offset: Offset(0, 1),
        blurStyle: BlurStyle.inner,
      ),
    ];
  }

  static BoxDecoration glassCard({
    Color color = AppColors.glassCardFill,
    Color? glowColor,
    double opacity = 1,
    double radius = 20,
  }) {
    return BoxDecoration(
      color: color.withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppColors.glassCardBorder),
      boxShadow: [
        BoxShadow(
          color: (glowColor ?? Colors.black).withValues(
            alpha: glowColor == null ? 0.16 : 0.08,
          ),
          blurRadius: glowColor == null ? 18 : 32,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  static BoxDecoration navBar() {
    return BoxDecoration(
      color: AppColors.navBar,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x4D000000),
          blurRadius: 20,
          offset: Offset(0, -4),
        ),
      ],
    );
  }

  static BoxDecoration heroCard({double radius = 24}) {
    return BoxDecoration(
      gradient: AppColors.balanceCardGradient,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      boxShadow: [
        ...heroInnerGlow(),
        const BoxShadow(
          color: Color(0xB3000000),
          blurRadius: 60,
          spreadRadius: -15,
          offset: Offset(0, 30),
        ),
      ],
    );
  }

  static ImageFilter glassBlur() => ImageFilter.blur(sigmaX: 12, sigmaY: 12);
}
