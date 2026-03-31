class AppSettings {
  AppSettings({
    required this.biometricEnabled,
    required this.dollarAnnualLimit,
    required this.dollarLimitYear,
    required this.initialBalance,
    String? cardNumber,
  }) : cardNumber = _normalizeCardNumber(cardNumber);

  final bool biometricEnabled;
  final double dollarAnnualLimit;
  final int dollarLimitYear;
  final double initialBalance;
  final String cardNumber;

  bool get needsDollarLimitRefresh => dollarLimitYear != DateTime.now().year;

  AppSettings copyWith({
    bool? biometricEnabled,
    double? dollarAnnualLimit,
    int? dollarLimitYear,
    double? initialBalance,
    String? cardNumber,
  }) {
    return AppSettings(
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      dollarAnnualLimit: dollarAnnualLimit ?? this.dollarAnnualLimit,
      dollarLimitYear: dollarLimitYear ?? this.dollarLimitYear,
      initialBalance: initialBalance ?? this.initialBalance,
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
