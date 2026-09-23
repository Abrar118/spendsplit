import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendsplit/features/settings/screens/settings_screen.dart';
import 'package:spendsplit/features/sms_import/providers/sms_providers.dart';
import 'package:spendsplit/features/sms_import/sms_gateway.dart';
import 'package:spendsplit/providers/providers.dart';

import 'support/fake_sms_gateway.dart';

void main() {
  Future<SharedPreferences> pumpSettings(
    WidgetTester tester,
    FakeSmsGateway gateway, [
    Map<String, Object> initial = const {},
  ]) async {
    SharedPreferences.setMockInitialValues(initial);
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          smsGatewayProvider.overrideWithValue(gateway),
        ],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    return prefs;
  }

  Finder smsSwitch() => find.descendant(
    of: find
        .ancestor(
          of: find.text('Import Trust Bank SMS'),
          matching: find.byType(Row),
        )
        .first,
    matching: find.byType(Switch),
  );

  testWidgets('switching on asks for permission and starts from now', (
    tester,
  ) async {
    final gateway = FakeSmsGateway(permissions: SmsPermissions.none);
    final prefs = await pumpSettings(tester, gateway);
    final before = DateTime.now().millisecondsSinceEpoch;

    await tester.tap(smsSwitch());
    await tester.pumpAndSettle();

    expect(prefs.getInt('sms_import_since'), greaterThanOrEqualTo(before));
    expect(
      find.text('New bank SMS are imported when you open the app'),
      findsOneWidget,
    );
  });

  testWidgets('denied permission keeps the switch off', (tester) async {
    final gateway = FakeSmsGateway(permissions: SmsPermissions.none)
      ..grantOnRequest = SmsPermissions.none;
    final prefs = await pumpSettings(tester, gateway);

    await tester.tap(smsSwitch());
    await tester.pumpAndSettle();

    expect(prefs.containsKey('sms_import_since'), isFalse);
    expect(find.textContaining('Allow SMS access'), findsOneWidget);
  });

  testWidgets('switching off clears the watermark', (tester) async {
    final prefs = await pumpSettings(tester, FakeSmsGateway(), {
      'sms_import_since': 5000,
    });

    await tester.tap(smsSwitch());
    await tester.pumpAndSettle();

    expect(prefs.containsKey('sms_import_since'), isFalse);
  });

  testWidgets('revoked READ_SMS shows a tap-to-allow subtitle', (tester) async {
    await pumpSettings(
      tester,
      FakeSmsGateway(permissions: SmsPermissions.none),
      {'sms_import_since': 5000},
    );
    expect(find.text('SMS permission is off — tap to allow'), findsOneWidget);
  });
}
