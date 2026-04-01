import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stores sensitive financial settings in the platform keystore
/// (Android Keystore / iOS Keychain) instead of plaintext SharedPreferences.
class SecureStorageRepository {
  const SecureStorageRepository(this._storage);

  final FlutterSecureStorage _storage;

  static const _keyCardNumber = 'secure_card_number';
  static const _keyInitialBalance = 'secure_initial_balance';

  Future<String> getCardNumber() async {
    return await _storage.read(key: _keyCardNumber) ?? '';
  }

  Future<void> setCardNumber(String value) async {
    await _storage.write(key: _keyCardNumber, value: value);
  }

  Future<double> getInitialBalance() async {
    final raw = await _storage.read(key: _keyInitialBalance);
    if (raw == null) return 0.0;
    return double.tryParse(raw) ?? 0.0;
  }

  Future<void> setInitialBalance(double value) async {
    await _storage.write(key: _keyInitialBalance, value: value.toString());
  }

  /// One-time migration: move values from SharedPreferences to secure storage.
  /// Call on app startup; safe to call multiple times (idempotent).
  Future<void> migrateFromSharedPreferences({
    required String? oldCardNumber,
    required double? oldInitialBalance,
  }) async {
    // Only migrate if secure storage is empty and old values exist
    final existingCard = await _storage.read(key: _keyCardNumber);
    if (existingCard == null && oldCardNumber != null && oldCardNumber.isNotEmpty) {
      await _storage.write(key: _keyCardNumber, value: oldCardNumber);
    }

    final existingBalance = await _storage.read(key: _keyInitialBalance);
    if (existingBalance == null && oldInitialBalance != null && oldInitialBalance != 0.0) {
      await _storage.write(
        key: _keyInitialBalance,
        value: oldInitialBalance.toString(),
      );
    }
  }
}
