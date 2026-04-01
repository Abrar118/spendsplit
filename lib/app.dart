import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/constants/enums.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/bottom_nav_bar.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/lock_screen.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/dollar_tracker/screens/dollar_tracker_screen.dart';
import 'features/export/screens/export_data_screen.dart';
import 'features/goals/screens/goals_screen.dart';
import 'features/monthly/screens/monthly_screen.dart';
import 'features/settings/screens/manage_categories_screen.dart';
import 'features/settings/screens/manage_templates_screen.dart';
import 'features/settings/screens/settings_screen.dart';
import 'features/transactions/screens/transactions_screen.dart';
import 'features/transactions/widgets/add_transaction_sheet.dart';
import 'providers/providers.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

/// A [ChangeNotifier] that listens to auth-related Riverpod providers and
/// calls [notifyListeners] to trigger GoRouter's [redirect] re-evaluation
/// without recreating the entire router.
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    _ref.listen(appSettingsProvider, (prev, next) => notifyListeners());
    _ref.listen(appSessionUnlockedProvider, (prev, next) => notifyListeners());
  }

  final Ref _ref;

  String? redirect(BuildContext context, GoRouterState state) {
    final settings = _ref.read(appSettingsProvider);
    final sessionUnlocked = _ref.read(appSessionUnlockedProvider);
    final isLockRoute = state.uri.path == AppRoute.lock.path;
    final shouldRequireLock = settings.biometricEnabled && !sessionUnlocked;

    if (shouldRequireLock && !isLockRoute) return AppRoute.lock.path;
    if (!shouldRequireLock && isLockRoute) return AppRoute.dashboard.path;
    return null;
  }
}

final _routerNotifierProvider = Provider<_RouterNotifier>((ref) {
  return _RouterNotifier(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.read(_routerNotifierProvider);
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoute.dashboard.path,
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return AppShell(currentLocation: state.uri.path, child: child);
        },
        routes: [
          GoRoute(
            path: AppRoute.dashboard.path,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: DashboardScreen()),
          ),
          GoRoute(
            path: AppRoute.transactions.path,
            pageBuilder: (context, state) => NoTransitionPage(
              child: TransactionsScreen(
                initialMonth: _parseMonthQuery(
                  state.uri.queryParameters['month'],
                ),
                initialCategoryId: int.tryParse(
                  state.uri.queryParameters['categoryId'] ?? '',
                ),
              ),
            ),
          ),
          GoRoute(
            path: AppRoute.monthly.path,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: MonthlyScreen()),
          ),
          GoRoute(
            path: AppRoute.goals.path,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: GoalsScreen()),
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoute.dollarTracker.path,
        builder: (context, state) => const DollarTrackerScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoute.settings.path,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoute.exportData.path,
        builder: (context, state) => const ExportDataScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoute.manageCategories.path,
        builder: (context, state) => const ManageCategoriesScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoute.manageTemplates.path,
        builder: (context, state) => const ManageTemplatesScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoute.lock.path,
        builder: (context, state) => const LockScreen(),
      ),
    ],
  );
});

class SpendSplitApp extends ConsumerWidget {
  const SpendSplitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.read(routerProvider);
    return MaterialApp.router(
      title: 'SpendSplit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      routerConfig: router,
    );
  }
}

DateTime? _parseMonthQuery(String? value) {
  if (value == null || value.isEmpty) return null;
  final parts = value.split('-');
  if (parts.length != 2) return null;
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  if (year == null || month == null || month < 1 || month > 12) return null;
  return DateTime(year, month);
}

class AppShell extends StatelessWidget {
  const AppShell({
    required this.currentLocation,
    required this.child,
    super.key,
  });

  final String currentLocation;
  final Widget child;

  int get currentIndex => switch (AppRoute.fromLocation(currentLocation)) {
    AppRoute.transactions => AppTab.transactions.pageIndex,
    AppRoute.monthly => AppTab.monthly.pageIndex,
    AppRoute.goals => AppTab.goals.pageIndex,
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
          final tab = AppTab.fromIndex(index);
          final route = tab.route;
          if (route == null) return;
          context.go(route.path);
        },
        onAddPressed: () async {
          if (!context.mounted) return;
          await showAddTransactionSheet(context);
        },
      ),
    );
  }
}

class _NoiseBackdrop extends StatelessWidget {
  const _NoiseBackdrop();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(color: AppColors.background);
  }
}
