enum AppTab {
  dashboard(0),
  transactions(1),
  add(2),
  monthly(3),
  goals(4);

  const AppTab(this.pageIndex);

  final int pageIndex;

  static AppTab fromIndex(int index) {
    return AppTab.values.firstWhere(
      (tab) => tab.pageIndex == index,
      orElse: () => AppTab.dashboard,
    );
  }

  AppRoute? get route => switch (this) {
    AppTab.dashboard => AppRoute.dashboard,
    AppTab.transactions => AppRoute.transactions,
    AppTab.add => null,
    AppTab.monthly => AppRoute.monthly,
    AppTab.goals => AppRoute.goals,
  };
}

enum AppRoute {
  dashboard('/'),
  transactions('/transactions'),
  monthly('/monthly'),
  goals('/goals'),
  dollarTracker('/dollar-tracker'),
  settings('/settings'),
  exportData('/export'),
  manageCategories('/manage-categories'),
  manageTemplates('/manage-templates'),
  lock('/lock');

  const AppRoute(this.path);

  final String path;

  static AppRoute fromLocation(String location) {
    return AppRoute.values.firstWhere(
      (route) => route.path == location,
      orElse: () => AppRoute.dashboard,
    );
  }
}

enum TransactionType {
  income('income'),
  expense('expense'),
  savingsDeposit('savings_deposit'),
  savingsWithdrawal('savings_withdrawal');

  const TransactionType(this.dbValue);

  final String dbValue;

  static TransactionType fromDbValue(String value) {
    return TransactionType.values.firstWhere(
      (type) => type.dbValue == value,
      orElse: () => TransactionType.expense,
    );
  }
}

enum IncomeSource {
  salary('salary'),
  freelance('freelance'),
  other('other');

  const IncomeSource(this.dbValue);

  final String dbValue;
}

enum TransactionQuickFilter { all, income, expense, savings }

enum AppSettingsKey {
  biometricEnabled('biometric_enabled'),
  dollarAnnualLimit('dollar_annual_limit'),
  dollarLimitYear('dollar_limit_year'),
  initialBalance('initial_balance'),
  cardNumber('card_number');

  const AppSettingsKey(this.value);

  final String value;
}
