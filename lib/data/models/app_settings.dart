class AppSettings {
  const AppSettings({
    required this.biometricEnabled,
    required this.dollarAnnualLimit,
    required this.dollarLimitYear,
    required this.initialBalance,
  });

  final bool biometricEnabled;
  final double dollarAnnualLimit;
  final int dollarLimitYear;
  final double initialBalance;

  bool get needsDollarLimitRefresh => dollarLimitYear != DateTime.now().year;

  AppSettings copyWith({
    bool? biometricEnabled,
    double? dollarAnnualLimit,
    int? dollarLimitYear,
    double? initialBalance,
  }) {
    return AppSettings(
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      dollarAnnualLimit: dollarAnnualLimit ?? this.dollarAnnualLimit,
      dollarLimitYear: dollarLimitYear ?? this.dollarLimitYear,
      initialBalance: initialBalance ?? this.initialBalance,
    );
  }
}
