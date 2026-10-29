import 'package:flutter/material.dart';

import 'app_colors.dart';

/// The platform sans (SF Pro on iOS, Roboto on Android) carries the UI, in
/// iOS text-style sizes with tabular figures so amounts line up. Doto, the
/// dot-grid face, is reserved for hero figures via [figure].
abstract final class AppTypography {
  static const _tabular = [FontFeature.tabularFigures()];

  static TextTheme textTheme() {
    // Keep the platform's own font family; only size, weight and colour change.
    final base = ThemeData.dark().textTheme;
    TextStyle style(
      TextStyle? from,
      double size,
      FontWeight weight, {
      Color color = AppColors.textPrimary,
      double? height,
      double letterSpacing = 0,
    }) => (from ?? const TextStyle()).copyWith(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      fontFeatures: _tabular,
    );

    return base.copyWith(
      displayLarge: style(base.displayLarge, 34, FontWeight.w700, height: 1.1),
      displayMedium: style(base.displayMedium, 28, FontWeight.w700),
      displaySmall: style(base.displaySmall, 24, FontWeight.w700),
      headlineLarge: style(base.headlineLarge, 34, FontWeight.w700),
      headlineMedium: style(base.headlineMedium, 22, FontWeight.w700),
      headlineSmall: style(base.headlineSmall, 20, FontWeight.w600),
      titleLarge: style(base.titleLarge, 20, FontWeight.w600),
      titleMedium: style(base.titleMedium, 17, FontWeight.w600),
      titleSmall: style(base.titleSmall, 15, FontWeight.w600),
      bodyLarge: style(base.bodyLarge, 17, FontWeight.w400, height: 1.35),
      bodyMedium: style(
        base.bodyMedium,
        15,
        FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.4,
      ),
      bodySmall: style(
        base.bodySmall,
        13,
        FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.35,
      ),
      labelLarge: style(base.labelLarge, 15, FontWeight.w600),
      labelMedium: style(
        base.labelMedium,
        13,
        FontWeight.w500,
        color: AppColors.textSecondary,
      ),
      labelSmall: style(
        base.labelSmall,
        12,
        FontWeight.w500,
        color: AppColors.textSecondary,
      ),
    );
  }

  /// Dot-grid numerals for the one hero figure on a screen. Doto has no ৳
  /// glyph, so callers set the currency sign in the platform sans beside it.
  /// Even 0.9 leading puts the baseline exactly eight dot cells down and no
  /// letter spacing keeps every glyph on whole cells (see DotFigure).
  static TextStyle figure(double size, {Color color = AppColors.textPrimary}) =>
      TextStyle(
        fontFamily: 'Doto',
        fontSize: size,
        height: 0.9,
        leadingDistribution: TextLeadingDistribution.even,
        color: color,
        fontVariations: const [FontVariation('wght', 900)],
        fontFeatures: _tabular,
      );
}
