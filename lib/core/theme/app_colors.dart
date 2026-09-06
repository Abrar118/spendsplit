import 'package:flutter/material.dart';

abstract final class AppColors {
  // --- Surfaces: deep navy void with cool charcoal panels ---
  static const background = Color(0xFF0A0D1A);
  static const surface = Color(0xFF161A2B);
  static const surfaceLight = Color(0xFF20263D);
  static const navBar = Color(0xFF1A1F33);
  static const surfaceDim = Color(0xFF0E1120);
  static const surfaceContainer = Color(0xFF171C2E);
  static const surfaceContainerLow = Color(0xFF141826);
  static const surfaceContainerHighest = Color(0xFF3B4262);
  static const glassCardFill = Color(0xE0161A2B);
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
  static const blue = Color(0xFF4C7DF0);

  static const textPrimary = Color(0xFFF5F1E8);
  static const textSecondary = Color(0xFFA6ADC4);
  static const textTertiary = Color(0xFF7C8299);
  static const onSurfaceVariant = Color(0xFFBFC6DC);

  static const border = Color(0x0FFFFFFF);
  static const divider = Color(0x0AFFFFFF);
  static const outlineVariant = Color(0xFF454C6B);
  static const onPrimary = Color(0xFF3A2410);

  static const catFood = Color(0xFFFF6B6B);
  static const catTransport = Color(0xFF4C7DF0);
  static const catUtilities = Color(0xFFECB877);
  static const catHealth = Color(0xFFF472B6);
  static const catShopping = Color(0xFF9B8BFF);
  static const catOther = Color(0xFFA6ADC4);

  static const balanceCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF27346B), Color(0xFF141A30), Color(0x803B5BC9)],
    stops: [0.0, 0.5, 1.0],
  );

  static const primaryActionGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [tealBright, teal],
  );

  static const incomeCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E3A67), Color(0xFF2C5290)],
  );

  static const expenseCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7A3517), Color(0xFFC15C30)],
  );

  static const savingsCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2A2C63), Color(0xFF433F9A)],
  );

  /// Backdrop wash behind every screen — a soft navy glow off the top so the
  /// frosted nav and glass cards have colour to refract instead of flat black.
  static const appBackdropGradient = RadialGradient(
    center: Alignment(0, -1.15),
    radius: 1.5,
    colors: [Color(0xFF1A2145), Color(0xFF0A0D1A)],
    stops: [0.0, 0.7],
  );
}
