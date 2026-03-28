import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract final class AppTypography {
  static TextTheme textTheme() {
    final base = ThemeData.dark().textTheme;
    final manrope = GoogleFonts.manropeTextTheme(base);

    return manrope.copyWith(
      displayLarge: GoogleFonts.manrope(
        fontSize: 56,
        fontWeight: FontWeight.w800,
        height: 0.94,
        letterSpacing: -1.6,
        color: AppColors.textPrimary,
      ),
      headlineLarge: GoogleFonts.manrope(
        fontSize: 30,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.7,
        color: AppColors.textPrimary,
      ),
      headlineMedium: GoogleFonts.manrope(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: AppColors.textPrimary,
      ),
      titleLarge: GoogleFonts.manrope(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: AppColors.textPrimary,
      ),
      titleMedium: GoogleFonts.manrope(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      bodyLarge: GoogleFonts.manrope(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.45,
        color: AppColors.textPrimary,
      ),
      bodyMedium: GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.5,
        color: AppColors.textSecondary,
      ),
      labelLarge: GoogleFonts.manrope(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
        color: AppColors.textSecondary,
      ),
      labelMedium: GoogleFonts.manrope(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.8,
        color: AppColors.textSecondary,
      ),
    );
  }
}
