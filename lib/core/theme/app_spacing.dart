abstract final class AppSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const section = 28.0;

  /// Bottom inset a scrollable page reserves under the floating frosted nav.
  /// Deliberately less than the pill's full height — the last rows are meant to
  /// scroll a little way *behind* the glass, and that overlap is what gives the
  /// frost something to refract instead of flat background.
  static const navClearance = 84.0;
}
