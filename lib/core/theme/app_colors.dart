import 'package:flutter/material.dart';

abstract final class AppColors {
  static const background = Color(0xFF0A0E1A);
  static const surface = Color(0xFF141829);
  static const surfaceLight = Color(0xFF1C2137);
  static const navBar = Color(0xFF0F1322);
  static const surfaceDim = Color(0xFF11131E);
  static const surfaceContainer = Color(0xFF1D1F2B);
  static const surfaceContainerLow = Color(0xFF191B26);
  static const surfaceContainerHighest = Color(0xFF323440);

  static const teal = Color(0xFF00E5BF);
  static const tealBright = Color(0xFF6FFFDC);
  static const coral = Color(0xFFFF6B6B);
  static const green = Color(0xFF34D399);
  static const purple = Color(0xFF9C7CFF);
  static const softPurple = Color(0xFFCEBDFF);
  static const amber = Color(0xFFFBBF24);
  static const blue = Color(0xFF60A5FA);

  static const textPrimary = Color(0xFFF1F5F9);
  static const textSecondary = Color(0xFF8892A7);
  static const textTertiary = Color(0xFF4A5568);
  static const onSurfaceVariant = Color(0xFFB9CAC3);

  static const border = Color(0x0FFFFFFF);
  static const divider = Color(0x0AFFFFFF);
  static const outlineVariant = Color(0xFF3B4A45);
  static const onPrimary = Color(0xFF00382D);

  static const catFood = Color(0xFFFF6B6B);
  static const catTransport = Color(0xFF60A5FA);
  static const catUtilities = Color(0xFFFBBF24);
  static const catHealth = Color(0xFFF472B6);
  static const catShopping = Color(0xFF9C7CFF);
  static const catOther = Color(0xFF8892A7);

  static const balanceCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A1D2E), Color(0xFF4C1D95)],
  );

  static const primaryActionGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [tealBright, teal],
  );

  static const incomeCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF059669), Color(0xFF047857)],
  );

  static const expenseCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
  );

  static const savingsCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
  );
}
