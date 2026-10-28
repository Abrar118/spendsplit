import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendsplit/features/auth/providers/auth_provider.dart';

void main() {
  test('lock is ignored while a system picker is open', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final session = container.read(appSessionUnlockedProvider.notifier)
      ..unlock();

    final picker = Completer<String?>();
    final picked = session.stayUnlockedDuring(() => picker.future);
    session.lock(); // Android backgrounds the app for the picker.
    expect(container.read(appSessionUnlockedProvider), isTrue);

    picker.complete('backup.json');
    expect(await picked, 'backup.json');
    session.lock();
    expect(container.read(appSessionUnlockedProvider), isFalse);
  });
}
