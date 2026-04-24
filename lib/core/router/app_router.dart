/// GoRouter configuration with authentication guard and
/// StatefulShellRoute for tab-based navigation.
///
/// Architecture:
///   - Root navigator: hosts full-screen modal routes (login, register,
///     createTask) that render OVER the shell.
///   - StatefulShellRoute (indexedStack): hosts Branch 0 (Tasks) and
///     Branch 1 (Dashboard) with state preserved across tab switches.
///
/// The [CreateTaskScreen] route uses `parentNavigatorKey: _rootKey`
/// so it covers the bottom nav bar — the same pattern used to fix
/// the blank-screen regression from the previous session.
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

// ── Navigator keys ────────────────────────────────────────────────────────

/// Root navigator key — required for routes that must cover the shell
/// (e.g. CreateTaskScreen, LoginScreen, RegisterScreen).
final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Shell navigator keys — one per branch.
final _tasksKey =
    GlobalKey<NavigatorState>(debugLabel: 'tasks');
final _dashboardKey =
    GlobalKey<NavigatorState>(debugLabel: 'dashboard');

// ── Provider ──────────────────────────────────────────────────────────────

/// Provides the singleton [GoRouter] instance, rebuilding on auth changes.
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  // Rebuild router (re-evaluate redirect) when auth state changes.
  ref.watch(authStateChangesProvider);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: RoutePaths.home,
    debugLogDiagnostics: true,

    // ── Auth redirect guard ───────────────────────────────────────
    redirect: (context, state) {
      final session =
          Supabase.instance.client.auth.currentSession;
      final isAuthenticated = session != null;
      final loc = state.matchedLocation;
      final isAuthRoute =
          loc == RoutePaths.login || loc == RoutePaths.register;

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
        parentNavigatorKey: _rootKey,
        path: RoutePaths.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: RoutePaths.register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // ── Create Task (above shell — covers the nav bar) ─────────
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: RoutePaths.createTask,
        name: 'createTask',
        builder: (context, state) => const CreateTaskScreen(),
      ),

      // ── Shell: Tab navigation ───────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ScaffoldWithNavBar(
          navigationShell: navigationShell,
        ),
        branches: [
          // Branch 0 — Tasks (initial tab, path = '/')
          StatefulShellBranch(
            navigatorKey: _tasksKey,
            routes: [
              GoRoute(
                path: RoutePaths.home,
                name: 'home',
                builder: (context, state) =>
                    const TaskListScreen(),
              ),
            ],
          ),

          // Branch 1 — Dashboard (path = '/dashboard')
          StatefulShellBranch(
            navigatorKey: _dashboardKey,
            routes: [
              GoRoute(
                path: RoutePaths.dashboard,
                name: 'dashboard',
                builder: (context, state) =>
                    const DashboardScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
