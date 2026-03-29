import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

final localAuthenticationProvider = Provider<LocalAuthentication>((ref) {
  return LocalAuthentication();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(localAuthenticationProvider));
});

class AuthRepository {
  const AuthRepository(this._localAuthentication);

  final LocalAuthentication _localAuthentication;

  Future<bool> isAvailable() async {
    try {
      final supported = await _localAuthentication.isDeviceSupported();
      if (!supported) return false;
      final enrolled = await _localAuthentication.getAvailableBiometrics();
      return enrolled.isNotEmpty;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> authenticate({
    required String reason,
    bool biometricOnly = false,
  }) async {
    try {
      return await _localAuthentication.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          biometricOnly: biometricOnly,
          stickyAuth: true,
          useErrorDialogs: false,
          sensitiveTransaction: true,
        ),
      );
    } on PlatformException {
      return false;
    }
  }

  Future<void> stopAuthentication() async {
    try {
      await _localAuthentication.stopAuthentication();
    } on PlatformException {
      // Nothing to do if the platform has already torn down auth state.
    }
  }
}

class AppSessionLockController extends Notifier<bool> {
  @override
  bool build() => false;

  void unlock() {
    state = true;
  }

  void lock() {
    state = false;
  }
}

final appSessionUnlockedProvider =
    NotifierProvider<AppSessionLockController, bool>(
      AppSessionLockController.new,
    );
