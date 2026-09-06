class AppSettings {
  AppSettings({
    required this.biometricEnabled,
    required this.dollarAnnualLimit,
    required this.dollarLimitYear,
    required this.initialBalance,
    this.monthlyExpenseBudget = 0,
    this.recapDismissedMonth,
    String? cardNumber,
  }) : cardNumber = _normalizeCardNumber(cardNumber);

  final bool biometricEnabled;
  final double dollarAnnualLimit;
  final int dollarLimitYear;
  final double initialBalance;
  final double monthlyExpenseBudget;

  /// Month key (`YYYY-MM`) of the last month-end recap the user dismissed.
  final String? recapDismissedMonth;
  final String cardNumber;

  bool get needsDollarLimitRefresh => dollarLimitYear != DateTime.now().year;

  AppSettings copyWith({
    bool? biometricEnabled,
    double? dollarAnnualLimit,
    int? dollarLimitYear,
    double? initialBalance,
    double? monthlyExpenseBudget,
    String? recapDismissedMonth,
    String? cardNumber,
  }) {
    return AppSettings(
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      dollarAnnualLimit: dollarAnnualLimit ?? this.dollarAnnualLimit,
      dollarLimitYear: dollarLimitYear ?? this.dollarLimitYear,
      initialBalance: initialBalance ?? this.initialBalance,
      monthlyExpenseBudget: monthlyExpenseBudget ?? this.monthlyExpenseBudget,
      recapDismissedMonth: recapDismissedMonth ?? this.recapDismissedMonth,
      cardNumber: cardNumber ?? this.cardNumber,
    );
  }

  static String _normalizeCardNumber(String? value) {
    final digits = value?.replaceAll(RegExp(r'\D'), '') ?? '';
    if (digits.length < 8) {
      return '4532756028418291';
    }
    return digits;
  }
}
