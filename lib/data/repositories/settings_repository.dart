import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/enums.dart';
import '../models/app_settings.dart';

class SettingsRepository {
  const SettingsRepository(this._preferences);

  final SharedPreferences _preferences;

  AppSettings loadSettings() {
    return AppSettings(
      monthlyExpenseBudget:
          _preferences.getDouble('monthly_expense_budget') ?? 0,
      biometricEnabled:
          _preferences.getBool(AppSettingsKey.biometricEnabled.value) ?? false,
      dollarAnnualLimit:
          _preferences.getDouble(AppSettingsKey.dollarAnnualLimit.value) ??
          12000.0,
      dollarLimitYear:
          _preferences.getInt(AppSettingsKey.dollarLimitYear.value) ??
          DateTime.now().year,
      initialBalance:
          _preferences.getDouble(AppSettingsKey.initialBalance.value) ?? 0.0,
      recapDismissedMonth: _preferences.getString('recap_dismissed_month'),
      cardNumber:
          _preferences.getString(AppSettingsKey.cardNumber.value) ??
          '4532756028418291',
    );
  }

  Future<void> setRecapDismissedMonth(String monthKey) {
    return _preferences.setString('recap_dismissed_month', monthKey);
  }

  Future<void> setBiometricEnabled(bool value) {
    return _preferences.setBool(AppSettingsKey.biometricEnabled.value, value);
  }

  Future<void> setDollarAnnualLimit(double value) {
    return _preferences.setDouble(
      AppSettingsKey.dollarAnnualLimit.value,
      value,
    );
  }

  Future<void> setDollarLimitYear(int value) {
    return _preferences.setInt(AppSettingsKey.dollarLimitYear.value, value);
  }

  Future<void> setInitialBalance(double value) {
    return _preferences.setDouble(AppSettingsKey.initialBalance.value, value);
  }

  Future<void> setMonthlyExpenseBudget(double value) async {
    if (!value.isFinite || value < 0) {
      throw ArgumentError.value(value, 'budget');
    }
    final saved = await _preferences.setDouble('monthly_expense_budget', value);
    if (!saved) throw StateError('Could not save the monthly budget');
  }

  Future<void> setCardNumber(String value) {
    return _preferences.setString(AppSettingsKey.cardNumber.value, value);
  }
}
