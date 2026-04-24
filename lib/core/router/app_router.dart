/// GoRouter configuration with authentication guard and
/// StatefulShellRoute for tab-based navigation.
///
/// Architecture:
///   - Root navigator: hosts full-screen modal routes (login, register,
///     createTask) that render OVER the shell.
///   - StatefulShellRoute (indexedStack): hosts Branch 0 (Tasks) and
///     Branch 1 (Dashboard) with state preserved across tab switches.
///
/// The modal routes use the root navigator key so they cover the shell.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mungiz/core/constants/app_constants.dart';
import 'package:mungiz/core/providers/supabase_providers.dart';
import 'package:mungiz/features/auth/presentation/login_screen.dart';
import 'package:mungiz/features/auth/presentation/register_screen.dart';
import 'package:mungiz/features/core/presentation/scaffold_with_nav_bar.dart';
import 'package:mungiz/features/dashboard/presentation/dashboard_screen.dart';
import 'package:mungiz/features/tasks/presentation/screens/create_task_screen.dart';
import 'package:mungiz/features/tasks/presentation/screens/task_list_screen.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'app_router.g.dart';

// ── Provider ──────────────────────────────────────────────────────────────

class _RouterRefreshNotifier extends ChangeNotifier {
  void refresh() {
    notifyListeners();
  }
}

/// Provides the singleton [GoRouter] instance and refreshes redirects when
/// auth state changes.
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  // Each router instance must own its navigator keys. The router is rebuilt
  // when auth changes, so sharing global keys across instances can produce
  // duplicate-key collisions while the old router is still tearing down.
  final rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  final tasksKey = GlobalKey<NavigatorState>(debugLabel: 'tasks');
  final dashboardKey = GlobalKey<NavigatorState>(debugLabel: 'dashboard');
  final routerRefreshNotifier = _RouterRefreshNotifier();

  ref
    ..listen(authStateChangesProvider, (
      previousState,
      nextState,
    ) {
      routerRefreshNotifier.refresh();
    })
    ..onDispose(routerRefreshNotifier.dispose);

  final router = GoRouter(
    navigatorKey: rootKey,
    initialLocation: RoutePaths.home,
    debugLogDiagnostics: true,
    refreshListenable: routerRefreshNotifier,

    // ── Auth redirect guard ───────────────────────────────────────
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isAuthenticated = session != null;
      final loc = state.matchedLocation;
      final isAuthRoute = loc == RoutePaths.login || loc == RoutePaths.register;

      if (!isAuthenticated && !isAuthRoute) {
        return RoutePaths.login;
      }
      if (isAuthenticated && isAuthRoute) {
        return RoutePaths.home;
      }
      return null;
    },

    // ── Routes ───────────────────────────────────────────────────
    routes: [
      // ── Auth routes (full-screen, above shell) ─────────────────
      GoRoute(
        parentNavigatorKey: rootKey,
        path: RoutePaths.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootKey,
        path: RoutePaths.register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // ── Create Task (above shell — covers the nav bar) ─────────
      GoRoute(
        parentNavigatorKey: rootKey,
        path: RoutePaths.createTask,
        name: 'createTask',
        builder: (context, state) => const CreateTaskScreen(),
      ),

      // ── Shell: Tab navigation ───────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => ScaffoldWithNavBar(
          navigationShell: navigationShell,
        ),
        branches: [
          // Branch 0 — Tasks (initial tab, path = '/')
          StatefulShellBranch(
            navigatorKey: tasksKey,
            routes: [
              GoRoute(
                path: RoutePaths.home,
                name: 'home',
                builder: (context, state) => const TaskListScreen(),
              ),
            ],
          ),

          // Branch 1 — Dashboard (path = '/dashboard')
          StatefulShellBranch(
            navigatorKey: dashboardKey,
            routes: [
              GoRoute(
                path: RoutePaths.dashboard,
                name: 'dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
}
