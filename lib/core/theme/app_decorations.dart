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

  /// A card surface defined by fill + shadow + a whisper-thin top highlight —
  /// no 1px stroke. Layering and the soft drop shadow carry the edge. When a
  /// [glowColor] is given the fill picks up a faint wash of it and the shadow
  /// glows in that hue, so accent cards read as tinted rather than flat.
  static BoxDecoration glassCard({
    Color color = AppColors.glassCardFill,
    Color? glowColor,
    double opacity = 1,
    double radius = 20,
  }) {
    final base = glowColor == null
        ? color.withValues(alpha: opacity)
        : Color.alphaBlend(
            glowColor.withValues(alpha: 0.12),
            color.withValues(alpha: opacity),
          );
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.alphaBlend(
            Colors.white.withValues(alpha: glowColor == null ? 0.04 : 0.06),
            base,
          ),
          base,
        ],
      ),
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: (glowColor ?? Colors.black).withValues(
            alpha: glowColor == null ? 0.28 : 0.22,
          ),
          blurRadius: glowColor == null ? 24 : 34,
          offset: const Offset(0, 14),
          spreadRadius: -6,
        ),
      ],
    );
  }

  static BoxDecoration heroCard({double radius = 24}) {
    return BoxDecoration(
      gradient: AppColors.balanceCardGradient,
      borderRadius: BorderRadius.circular(radius),
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

  // --- Frosted glass bottom nav ---------------------------------------------

  /// Saturation boost (~1.7x) composed into the nav's backdrop blur. A plain
  /// blur greys the backdrop out — over near-black that reads as a hazy slab,
  /// not glass. Real frosted glass *saturates* what's behind it so the blurred
  /// colour glows through. Rows sum to 1, preserving luminance.
  static const List<double> _navSaturation = [
    1.52992, -0.47216, -0.05776, 0, 0, //
    -0.14008, 1.19784, -0.05776, 0, 0, //
    -0.14008, -0.47216, 1.61224, 0, 0, //
    0, 0, 0, 1, 0, //
  ];

  /// Backdrop filter for the floating nav pill: strong blur with the saturation
  /// matrix composed on top, so what scrolls behind reads as frosted glass.
  static ImageFilter navFrost() => ImageFilter.compose(
    outer: const ColorFilter.matrix(_navSaturation),
    inner: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
  );

  /// Faint white sheen laid over the frosted blur — brighter at the top edge,
  /// fading down, like light catching the pane. Kept low: heavier reads as grey
  /// haze rather than glass.
  static const navSheen = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x12FFFFFF), Color(0x05FFFFFF)],
  );

  /// Soft shadow that lifts the pill off the content. Lives on an outer box so
  /// it falls outside the blur's clip.
  static const navShadow = [
    BoxShadow(
      color: Color(0x66000000),
      blurRadius: 28,
      offset: Offset(0, 10),
      spreadRadius: -4,
    ),
  ];
}
