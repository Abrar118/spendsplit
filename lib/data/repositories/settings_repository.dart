import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/enums.dart';
import '../models/app_settings.dart';

class SettingsRepository {
  const SettingsRepository(this._preferences);

  final SharedPreferences _preferences;

  AppSettings loadSettings() {
    return AppSettings(
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
      cardNumber:
          _preferences.getString(AppSettingsKey.cardNumber.value) ??
          '4532756028418291',
    );
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

  Future<void> setCardNumber(String value) {
    return _preferences.setString(AppSettingsKey.cardNumber.value, value);
  }
}
