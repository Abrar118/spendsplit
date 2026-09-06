import 'package:flutter/material.dart';

abstract final class AppColors {
  // --- Surfaces: pure black void with faintly purple-tinted charcoal panels ---
  static const background = Color(0xFF000000);
  static const surface = Color(0xFF15131F);
  static const surfaceLight = Color(0xFF1E1A2C);
  static const navBar = Color(0xFF16121F);
  static const surfaceDim = Color(0xFF0C0A12);
  static const surfaceContainer = Color(0xFF161320);
  static const surfaceContainerLow = Color(0xFF110F19);
  static const surfaceContainerHighest = Color(0xFF383150);
  static const glassCardFill = Color(0xE015131F);
  static const glassCardBorder = Color(0x0FFFFFFF);

  // --- Accents ---
  // `teal` is the app's primary accent slot (warm gold in this theme).
  static const teal = Color(0xFFECBB7E);
  static const tealBright = Color(0xFFF8DCB2);
  static const coral = Color(0xFFF26D3D);
  static const green = Color(0xFF34D89C);
  static const purple = Color(0xFF9B8BFF);
  static const softPurple = Color(0xFFD4C6FF);
  static const amber = Color(0xFFECB877);
  // Deep violet — the app's cool accent (replaces the former cobalt blue).
  static const blue = Color(0xFF7A46E0);

  static const textPrimary = Color(0xFFF5F1E8);
  static const textSecondary = Color(0xFFA6A0B8);
  static const textTertiary = Color(0xFF77728A);
  static const onSurfaceVariant = Color(0xFFC6BFD8);

  static const border = Color(0x0FFFFFFF);
  static const divider = Color(0x0AFFFFFF);
  static const outlineVariant = Color(0xFF48425F);
  static const onPrimary = Color(0xFF3A2410);

  static const catFood = Color(0xFFFF6B6B);
  static const catTransport = Color(0xFF7A46E0);
  static const catUtilities = Color(0xFFECB877);
  static const catHealth = Color(0xFFF472B6);
  static const catShopping = Color(0xFF9B8BFF);
  static const catOther = Color(0xFFA6A0B8);

  static const balanceCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF261C4E), Color(0xFF100D1A), Color(0x663A2494)],
    stops: [0.0, 0.55, 1.0],
  );

  static const primaryActionGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [tealBright, teal],
  );

  static const incomeCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF241E5E), Color(0xFF382C86)],
  );

  static const expenseCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7A3517), Color(0xFFC15C30)],
  );

  static const savingsCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2A2560), Color(0xFF443C9C)],
  );
}
