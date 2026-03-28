import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/constants/enums.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/bottom_nav_bar.dart';
import 'features/auth/screens/lock_screen.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/dollar_tracker/screens/dollar_tracker_screen.dart';
import 'features/goals/screens/goals_screen.dart';
import 'features/monthly/screens/monthly_screen.dart';
import 'features/transactions/screens/transactions_screen.dart';
import 'features/transactions/widgets/add_transaction_sheet.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'shell',
);

class SpendSplitApp extends StatelessWidget {
  const SpendSplitApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/',
      routes: [
        ShellRoute(
          navigatorKey: _shellNavigatorKey,
          builder: (context, state, child) {
            return AppShell(
              currentLocation: state.uri.toString(),
              child: child,
            );
          },
          routes: [
            GoRoute(
              path: '/',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: DashboardScreen()),
            ),
            GoRoute(
              path: '/transactions',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: TransactionsScreen()),
            ),
            GoRoute(
              path: '/monthly',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: MonthlyScreen()),
            ),
            GoRoute(
              path: '/goals',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: GoalsScreen()),
            ),
          ],
        ),
        GoRoute(
          parentNavigatorKey: _rootNavigatorKey,
          path: '/dollar-tracker',
          builder: (context, state) => const DollarTrackerScreen(),
        ),
        GoRoute(
          parentNavigatorKey: _rootNavigatorKey,
          path: '/lock',
          builder: (context, state) => const LockScreen(),
        ),
      ],
    );

    return MaterialApp.router(
      title: 'SpendSplit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      routerConfig: router,
    );
  }
}

class AppShell extends StatelessWidget {
  const AppShell({
    required this.currentLocation,
    required this.child,
    super.key,
  });

  final String currentLocation;
  final Widget child;

  int get currentIndex => switch (currentLocation) {
    '/transactions' => AppTab.transactions.pageIndex,
    '/monthly' => AppTab.monthly.pageIndex,
    '/goals' => AppTab.goals.pageIndex,
    _ => AppTab.dashboard.pageIndex,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          const Positioned.fill(child: _NoiseBackdrop()),
          Positioned.fill(child: child),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: currentIndex,
        onDestinationSelected: (index) {
          switch (AppTab.fromIndex(index)) {
            case AppTab.dashboard:
              context.go('/');
            case AppTab.transactions:
              context.go('/transactions');
            case AppTab.add:
              return;
            case AppTab.monthly:
              context.go('/monthly');
            case AppTab.goals:
              context.go('/goals');
          }
        },
        onAddPressed: () => showAddTransactionSheet(context),
      ),
    );
  }
}

class _NoiseBackdrop extends StatelessWidget {
  const _NoiseBackdrop();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colors.surfaceDim, colors.surface],
        ),
      ),
      child: CustomPaint(
        painter: _NoisePainter(
          baseColor: colors.surface,
          grainColor: colors.onSurface.withValues(alpha: 0.018),
        ),
      ),
    );
  }
}

class _NoisePainter extends CustomPainter {
  const _NoisePainter({required this.baseColor, required this.grainColor});

  final Color baseColor;
  final Color grainColor;

  @override
  void paint(Canvas canvas, Size size) {
    final basePaint = Paint()..color = baseColor;
    canvas.drawRect(Offset.zero & size, basePaint);

    final grainPaint = Paint()..color = grainColor;
    const step = 6.0;
    for (double dx = 0; dx < size.width; dx += step) {
      for (double dy = 0; dy < size.height; dy += step) {
        final seed = ((dx + 3) * (dy + 5)).toInt();
        if (seed % 5 == 0) {
          canvas.drawRect(Rect.fromLTWH(dx, dy, 1.2, 1.2), grainPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _NoisePainter oldDelegate) {
    return oldDelegate.baseColor != baseColor ||
        oldDelegate.grainColor != grainColor;
  }
}
