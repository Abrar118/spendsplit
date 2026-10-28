import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendsplit/features/export/screens/export_data_screen.dart';

void main() {
  testWidgets('shareOrigin is a non-empty rect on screen', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (c) {
            ctx = c;
            return const Scaffold(body: Text('x'));
          },
        ),
      ),
    );

    final origin = shareOrigin(ctx);
    expect(origin.isEmpty, isFalse);
    expect(
      Offset.zero & tester.view.physicalSize / tester.view.devicePixelRatio,
      predicate<Rect>((screen) => screen.contains(origin.center)),
    );
  });
}
