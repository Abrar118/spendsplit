import 'dart:ui';

import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppDecorations {
  /// Corner radius of every module: square. The coupon notches and the
  /// review stamp carry the only softness in the world.
  static const radius = 0.0;

  /// A module: a fill one value step above the ground. Layering carries the
  /// edge; no stroke, no glow, no shadow.
  static BoxDecoration module({Color color = AppColors.surface}) =>
      BoxDecoration(color: color, borderRadius: BorderRadius.circular(radius));

  /// An outlined module for states drawn as form (needs review, upcoming).
  static BoxDecoration outlined(Color color) => BoxDecoration(
    border: Border.all(color: color, width: 1.5),
    borderRadius: BorderRadius.circular(radius),
  );

  /// Material behind the title bar and sheets: the platform-style blur.
  static ImageFilter barBlur() => ImageFilter.blur(sigmaX: 24, sigmaY: 24);

  /// The floating tab bar's lighter frost: shapes and colour behind it stay
  /// legible as soft forms.
  static ImageFilter glassBlur() => ImageFilter.blur(sigmaX: 10, sigmaY: 10);
}
