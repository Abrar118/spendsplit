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

  /// Returns true if the device supports any form of local auth
  /// (biometrics, PIN, pattern, password).
  Future<bool> isDeviceSupported() async {
    try {
      return await _localAuthentication.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  /// Returns true if biometrics (fingerprint/face) are enrolled.
  Future<bool> hasBiometrics() async {
    try {
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

  int _holds = 0;

  void unlock() {
    state = true;
  }

  void lock() {
    if (_holds > 0) return;
    state = false;
  }

  /// Ignores [lock] while [action] runs. Android's system file picker
  /// backgrounds the app; re-locking then would tear down the screen that is
  /// waiting for the picked file.
  Future<T> stayUnlockedDuring<T>(Future<T> Function() action) async {
    _holds++;
    try {
      return await action();
    } finally {
      _holds--;
    }
  }
}

final appSessionUnlockedProvider =
    NotifierProvider<AppSessionLockController, bool>(
      AppSessionLockController.new,
    );
