import 'package:flutter/material.dart';

abstract final class AppColors {
  static const background = Color(0xFF141210);
  static const surface = Color(0xFF26221E);
  static const surfaceLight = Color(0xFF342E28);
  static const navBar = Color(0xFF2C2722);
  static const surfaceDim = Color(0xFF1A1714);
  static const surfaceContainer = Color(0xFF2C2722);
  static const surfaceContainerLow = Color(0xFF24201C);
  static const surfaceContainerHighest = Color(0xFF494139);
  static const glassCardFill = Color(0xCC26221E);
  static const glassCardBorder = Color(0x14FFFFFF);

  static const teal = Color(0xFFE8BF89);
  static const tealBright = Color(0xFFF5D9AF);
  static const coral = Color(0xFFF18355);
  static const green = Color(0xFF34D399);
  static const purple = Color(0xFFA78BFA);
  static const softPurple = Color(0xFFD4C6FF);
  static const amber = Color(0xFFE8B778);
  static const blue = Color(0xFF6D9EFF);

  static const textPrimary = Color(0xFFFAF4EB);
  static const textSecondary = Color(0xFFB7AA98);
  static const textTertiary = Color(0xFF948674);
  static const onSurfaceVariant = Color(0xFFCDBEA9);

  static const border = Color(0x0FFFFFFF);
  static const divider = Color(0x0AFFFFFF);
  static const outlineVariant = Color(0xFF5F5143);
  static const onPrimary = Color(0xFF34200D);

  static const catFood = Color(0xFFFF6B6B);
  static const catTransport = Color(0xFF6D9EFF);
  static const catUtilities = Color(0xFFE8B778);
  static const catHealth = Color(0xFFF472B6);
  static const catShopping = Color(0xFFA78BFA);
  static const catOther = Color(0xFFB7AA98);

  static const balanceCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3C3328), Color(0xFF201B18), Color(0x66345BC5)],
    stops: [0.0, 0.45, 1.0],
  );

  static const primaryActionGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [tealBright, teal],
  );

  static const incomeCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF20385D), Color(0xFF284C83)],
  );

  static const expenseCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF713718), Color(0xFFAE532B)],
  );

  static const savingsCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF292B56), Color(0xFF3D4485)],
  );
}
