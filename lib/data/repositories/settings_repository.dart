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
      smsImportSince: _preferences.getInt(_smsImportSinceKey),
      bankBalance: _preferences.getDouble(_bankBalanceKey),
      bankBalanceAt: DateTime.tryParse(
        _preferences.getString(_bankBalanceAtKey) ?? '',
      ),
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

  static const _smsImportSinceKey = 'sms_import_since';
  static const _bankBalanceKey = 'bank_balance';
  static const _bankBalanceAtKey = 'bank_balance_at';

  Future<void> setSmsImportSince(int? millis) async {
    if (millis == null) {
      await _preferences.remove(_smsImportSinceKey);
    } else {
      await _preferences.setInt(_smsImportSinceKey, millis);
    }
  }

  Future<void> setBankBalance(double? balance, DateTime? at) async {
    if (balance == null || at == null) {
      await _preferences.remove(_bankBalanceKey);
      await _preferences.remove(_bankBalanceAtKey);
      return;
    }
    await _preferences.setDouble(_bankBalanceKey, balance);
    await _preferences.setString(_bankBalanceAtKey, at.toIso8601String());
  }
}
