import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendsplit/core/widgets/bottom_nav_bar.dart';
import 'package:spendsplit/features/monthly/widgets/monthly_budget_card.dart';
import 'package:spendsplit/providers/providers.dart';

void main() {
  testWidgets('navigation fits a narrow phone and retains all actions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    var selected = -1;
    var added = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: BottomNavBar(
            currentIndex: 0,
            onDestinationSelected: (value) => selected = value,
            onAddPressed: () => added = true,
          ),
        ),
      ),
    );
    expect(find.byType(BackdropFilter), findsOneWidget);
    await tester.tap(find.text('MONTHLY'));
    expect(selected, 3);
    await tester.tap(find.bySemanticsLabel('Add transaction'));
    expect(added, isTrue);
    expect(tester.takeException(), isNull);
  });
  testWidgets('budget reports overspending and persists an edit', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'monthly_expense_budget': 100.0});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const MaterialApp(
          home: Scaffold(body: MonthlyBudgetCard(spent: 150)),
        ),
      ),
    );
    expect(find.textContaining('50 over budget'), findsOneWidget);
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '200');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.textContaining('50 remaining'), findsOneWidget);
    expect(prefs.getDouble('monthly_expense_budget'), 200);
    expect(tester.takeException(), isNull);
  });
}
