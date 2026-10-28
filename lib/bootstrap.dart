import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/database/app_database.dart';
import 'data/repositories/secure_storage_repository.dart';
import 'providers/providers.dart';

/// Provider overrides shared by the app and the SMS background entrypoint.
Future<List<Override>> bootstrapOverrides() async {
  final sharedPreferences = await SharedPreferences.getInstance();
  const secureStorage = FlutterSecureStorage();
  final secureRepo = SecureStorageRepository(secureStorage);

  // iOS keeps Keychain items after the app is deleted, but not the database,
  // so a reinstall would show the old starting balance. No database file
  // means a fresh install.
  if (Platform.isIOS && !await (await databaseFile()).exists()) {
    await secureRepo.clear();
  }

  // One-time migration: move sensitive data from SharedPreferences to keystore
  await secureRepo.migrateFromSharedPreferences(
    oldCardNumber: sharedPreferences.getString('card_number'),
    oldInitialBalance: sharedPreferences.getDouble('initial_balance'),
  );
  // The keystore has them now; drop the plaintext copies.
  await sharedPreferences.remove('card_number');
  await sharedPreferences.remove('initial_balance');

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
