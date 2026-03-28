import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

abstract final class AppTheme {
  static ThemeData dark() {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.teal,
      onPrimary: AppColors.onPrimary,
      secondary: AppColors.purple,
      onSecondary: AppColors.textPrimary,
      error: AppColors.coral,
      onError: AppColors.textPrimary,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      primaryContainer: AppColors.tealBright,
      onPrimaryContainer: AppColors.onPrimary,
      secondaryContainer: AppColors.softPurple,
      onSecondaryContainer: AppColors.surface,
      tertiary: AppColors.blue,
      onTertiary: AppColors.textPrimary,
      tertiaryContainer: AppColors.surfaceLight,
      onTertiaryContainer: AppColors.textPrimary,
      surfaceDim: AppColors.surfaceDim,
      surfaceBright: AppColors.surfaceLight,
      surfaceContainerLowest: AppColors.background,
      surfaceContainerLow: AppColors.surfaceContainerLow,
      surfaceContainer: AppColors.surfaceContainer,
      surfaceContainerHigh: AppColors.surfaceLight,
      surfaceContainerHighest: AppColors.surfaceContainerHighest,
      onSurfaceVariant: AppColors.onSurfaceVariant,
      outline: AppColors.border,
      outlineVariant: AppColors.outlineVariant,
      shadow: Colors.transparent,
      scrim: Colors.black54,
      inverseSurface: AppColors.textPrimary,
      onInverseSurface: AppColors.background,
      inversePrimary: AppColors.tealBright,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Colors.transparent,
      textTheme: AppTypography.textTheme(),
      canvasColor: AppColors.surface,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surfaceLight.withValues(alpha: 0.96),
        contentTextStyle: AppTypography.textTheme().bodyMedium?.copyWith(
          color: AppColors.textPrimary,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          backgroundColor: AppColors.teal,
          foregroundColor: AppColors.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          textStyle: AppTypography.textTheme().titleMedium,
        ),
      ),
      iconTheme: const IconThemeData(color: AppColors.textSecondary),
      dividerColor: AppColors.divider,
    );
  }
}
