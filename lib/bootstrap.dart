import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/repositories/secure_storage_repository.dart';
import 'providers/providers.dart';

/// Provider overrides shared by the app and the SMS background entrypoint.
Future<List<Override>> bootstrapOverrides() async {
  final sharedPreferences = await SharedPreferences.getInstance();
  const secureStorage = FlutterSecureStorage();
  final secureRepo = SecureStorageRepository(secureStorage);

  // One-time migration: move sensitive data from SharedPreferences to keystore
  await secureRepo.migrateFromSharedPreferences(
    oldCardNumber: sharedPreferences.getString('card_number'),
    oldInitialBalance: sharedPreferences.getDouble('initial_balance'),
  );

  // Pre-load secure values so providers can access them synchronously
  final secureCardNumber = await secureRepo.getCardNumber();
  final secureInitialBalance = await secureRepo.getInitialBalance();

  return [
    sharedPreferencesProvider.overrideWithValue(sharedPreferences),
    secureStorageProvider.overrideWithValue(secureRepo),
    secureCardNumberProvider.overrideWithValue(secureCardNumber),
    secureInitialBalanceProvider.overrideWithValue(secureInitialBalance),
  ];
}
