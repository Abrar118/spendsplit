import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendsplit/core/widgets/bottom_nav_bar.dart';
import 'package:spendsplit/data/database/app_database.dart';
import 'package:spendsplit/data/models/financial_summaries.dart';
import 'package:spendsplit/features/dashboard/widgets/monthly_snapshot_row.dart';
import 'package:spendsplit/features/graphs/widgets/spending_chart.dart';
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
    expect(find.text('Monthly'), findsNothing);
    await tester.tap(find.bySemanticsLabel('Monthly'));
    expect(selected, 3);
    await tester.tap(find.bySemanticsLabel('Graphs'));
    expect(selected, 4);
    await tester.tap(find.bySemanticsLabel('Goals'));
    expect(selected, 5);
    await tester.tap(find.bySemanticsLabel('Add transaction'));
    expect(added, isTrue);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'MonthlySnapshotRow shows all three figures with no overflow at 320dp',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MonthlySnapshotRow(
              summary: MonthlyFinanceSummary(
                month: DateTime(2026, 9),
                income: 77000,
                expenses: 12345,
                saved: 5000,
              ),
            ),
          ),
        ),
      );
      expect(find.text('Income'), findsOneWidget);
      expect(find.text('Spent'), findsOneWidget);
      expect(find.text('To savings'), findsOneWidget);
      // The row must lay all three out at once — no horizontal scroll view that
      // pushes the last row off-screen.
      expect(
        find.descendant(
          of: find.byType(MonthlySnapshotRow),
          matching: find.byType(Scrollable),
        ),
        findsNothing,
      );
      // The savings amount stays within the 320dp viewport.
      expect(
        tester.getBottomRight(find.text('৳ 5,000')).dx,
        lessThanOrEqualTo(320),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'SpendingChart shows 12 rolling month labels ending at the current month',
    (tester) async {
      final now = DateTime.now();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SpendingChart(
                transactions: [
                  TransactionsTableData(
                    id: 1,
                    type: 'expense',
                    amount: 1200,
                    date: DateTime(now.year, now.month, 3),
                    createdAt: now,
                    needsReview: false,
                  ),
                  TransactionsTableData(
                    id: 2,
                    type: 'income',
                    amount: 5000,
                    date: DateTime(now.year, now.month, 4),
                    createdAt: now,
                    needsReview: false,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      final currentLabel = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ][now.month - 1];
      expect(find.text(currentLabel), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('budget reports overspending and persists an edit', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'monthly_expense_budget': 100.0});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          // A past month: no pace marker, so the text doesn't depend on today.
          home: Scaffold(
            body: MonthlyBudgetCard(spent: 150, month: DateTime(2020)),
          ),
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
