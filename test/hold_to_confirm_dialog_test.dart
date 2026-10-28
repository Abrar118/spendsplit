import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendsplit/features/export/screens/export_data_screen.dart';

void main() {
  testWidgets('restore confirm dialog lays out and completes on hold', (
    tester,
  ) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => result = await showDialog<bool>(
              context: context,
              builder: (_) => const HoldToConfirmDialog(),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Hold to replace everything'), findsOneWidget);

    final hold = await tester.startGesture(
      tester.getCenter(find.text('Hold to replace everything')),
    );
    await tester.pump(const Duration(milliseconds: 150)); // tap-down fires
    await tester.pump(); // ticker starts
    await tester.pump(const Duration(milliseconds: 1600));
    await hold.up();
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });
}
