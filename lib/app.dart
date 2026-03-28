import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'core/widgets/bottom_nav_bar.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/dollar_tracker/screens/dollar_tracker_screen.dart';
import 'features/goals/screens/goals_screen.dart';
import 'features/monthly/screens/monthly_screen.dart';
import 'features/transactions/screens/transactions_screen.dart';

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
    '/transactions' => 1,
    '/monthly' => 3,
    '/goals' => 4,
    _ => 0,
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
          if (index == 0) {
            context.go('/');
          } else if (index == 1) {
            context.go('/transactions');
          } else if (index == 3) {
            context.go('/monthly');
          } else if (index == 4) {
            context.go('/goals');
          }
        },
        onAddPressed: () => _showAddPlaceholderSheet(context),
      ),
    );
  }

  void _showAddPlaceholderSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: 16 + MediaQuery.viewPaddingOf(context).bottom,
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.96),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.28,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.08),
                      blurRadius: 30,
                      offset: const Offset(0, -8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        child: Container(
                          width: 52,
                          height: 5,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.outlineVariant.withValues(
                              alpha: 0.55,
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text('New Entry', style: theme.textTheme.headlineMedium),
                      const SizedBox(height: 12),
                      Text(
                        'Phase 1 establishes the add-sheet trigger contract. '
                        'The real transaction form lands in Phase 3.',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Close'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
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
