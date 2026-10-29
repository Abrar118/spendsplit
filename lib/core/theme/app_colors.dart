import 'package:flutter/material.dart';

/// Grid Numerals palette. Every hue has exactly one job; never reuse one for
/// decoration.
abstract final class AppColors {
  // --- Ground and surfaces: near-black, square modules layered by value ---
  static const background = Color(0xFF101113);
  static const surface = Color(0xFF17181B);
  static const surfaceLight = Color(0xFF1F2024);
  static const surfaceRaised = Color(0xFF26272C);
  static const navBar = Color(0xF0101113);

  /// The floating tab bar's frosted glass: a light grey wash over a heavy
  /// blur, so what scrolls underneath shows through, with a faint light edge.
  static const navGlass = Color(0x472C2D33);
  static const navGlassEdge = Color(0x2EFFFFFF);
  static const surfaceDim = Color(0xFF0B0C0D);
  static const surfaceContainer = Color(0xFF17181B);
  static const surfaceContainerLow = Color(0xFF141517);
  static const surfaceContainerHighest = Color(0xFF2C2D33);

  /// The faint construction grid drawn behind hero figures.
  static const gridLine = Color(0xFF1C1E22);

  /// Hairline rules between rows and around outlined states.
  static const hairline = Color(0xFF2A2C31);

  // --- The legend ---
  /// Available balance and the primary action. Nothing else.
  static const accent = Color(0xFFFF5A1F);
  static const accentBright = Color(0xFFFF8452);

  /// Savings: the bone plane beside Available.
  static const savings = Color(0xFFE8E4DC);
  static const savingsDim = Color(0xFFA9A59D);

  /// Spending, negative amounts, delete, and the needs-review stamp.
  static const spend = Color(0xFFFF3D6E);

  /// Income and positive amounts.
  static const income = Color(0xFF3DDC97);

  /// Warnings: over pace, deadlines, projected overspend.
  static const warning = Color(0xFFFFC53D);

  /// The Dollar Tracker, and only the Dollar Tracker.
  static const usd = Color(0xFF4C7DFF);

  static const textPrimary = Color(0xFFF2F2F0);
  static const textSecondary = Color(0xFFA2A6AD);
  static const textTertiary = Color(0xFF7C8088);
  static const onSurfaceVariant = Color(0xFFC4C7CC);

  static const border = hairline;
  static const divider = Color(0xFF232428);
  static const outlineVariant = Color(0xFF3A3C42);

  /// Ink on the orange accent (white fails contrast there).
  static const onPrimary = Color(0xFF140A05);
}
