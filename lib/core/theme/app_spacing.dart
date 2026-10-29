abstract final class AppSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const section = 28.0;

  /// Bottom room a scrollable page reserves so its last row, fully scrolled,
  /// clears the floating tab bar (60 tall, up to 34 above the screen edge on
  /// iPhone). Rows still pass under the glass while scrolling.
  static const navClearance = 108.0;
}
