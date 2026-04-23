/// GoRouter configuration with authentication guard.
///
/// Routes are defined declaratively. An auth redirect guard forces
/// unauthenticated users to `/login` and prevents authenticated users
/// from accessing the login/register screens.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mungiz/core/constants/app_constants.dart';
import 'package:mungiz/core/providers/supabase_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'app_router.g.dart';

/// Provides the [GoRouter] instance, rebuilding when auth state
/// changes.
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  // Listen to auth state changes so the router re-evaluates
  // redirects. The value itself is unused — we only need the
  // reactive subscription.
  ref.watch(authStateChangesProvider);

  return GoRouter(
    initialLocation: RoutePaths.home,
    debugLogDiagnostics: true,

    // ── Redirect (Auth Guard) ──────────────────────────────
    redirect: (context, state) {
      final session =
          Supabase.instance.client.auth.currentSession;
      final isAuthenticated = session != null;
      final isAuthRoute =
          state.matchedLocation == RoutePaths.login ||
              state.matchedLocation == RoutePaths.register;

      // Not logged in → force to login.
      if (!isAuthenticated && !isAuthRoute) {
        return RoutePaths.login;
      }

      // Already logged in → prevent auth screens.
      if (isAuthenticated && isAuthRoute) {
        return RoutePaths.home;
      }

      // No redirect needed.
      return null;
    },

    // ── Routes ─────────────────────────────────────────────
    routes: [
      GoRoute(
        path: RoutePaths.home,
        name: 'home',
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'الرئيسية'),
      ),
      GoRoute(
        path: RoutePaths.login,
        name: 'login',
        builder: (context, state) =>
            const _PlaceholderScreen(
          title: 'تسجيل الدخول',
        ),
      ),
      GoRoute(
        path: RoutePaths.register,
        name: 'register',
        builder: (context, state) =>
            const _PlaceholderScreen(
          title: 'إنشاء حساب',
        ),
      ),
      GoRoute(
        path: RoutePaths.createTask,
        name: 'createTask',
        builder: (context, state) =>
            const _PlaceholderScreen(
          title: 'مهمة جديدة',
        ),
      ),
      GoRoute(
        path: RoutePaths.dashboard,
        name: 'dashboard',
        builder: (context, state) =>
            const _PlaceholderScreen(
          title: 'لوحة المتابعة',
        ),
      ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────
// Placeholder screen — replaced in Stage 4+ with real screens
// ─────────────────────────────────────────────────────────────

/// Temporary placeholder used to verify routing and theming.
///
/// Will be replaced with actual feature screens in subsequent
/// stages.
class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction_rounded,
              size: 64,
              color: colorScheme.primary.withValues(
                alpha: 0.6,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'قيد التطوير',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
