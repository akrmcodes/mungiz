/// GoRouter configuration with authentication guard and
/// StatefulShellRoute for tab-based navigation.
///
/// Architecture:
///   - Root navigator: hosts full-screen modal routes (login, register,
///     createTask) that render OVER the shell.
///   - StatefulShellRoute (indexedStack): hosts Branch 0 (Tasks) and
///     Branch 1 (Dashboard) and Branch 2 (Profile) with state preserved
///     across tab switches.
///
/// The modal routes use the root navigator key so they cover the shell.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mungiz/core/constants/app_constants.dart';
import 'package:mungiz/core/database/app_database.dart';
import 'package:mungiz/core/providers/supabase_providers.dart';
import 'package:mungiz/features/auth/presentation/login_screen.dart';
import 'package:mungiz/features/auth/presentation/register_screen.dart';
import 'package:mungiz/features/auth/presentation/screens/profile_screen.dart';
import 'package:mungiz/features/core/presentation/scaffold_with_nav_bar.dart';
import 'package:mungiz/features/dashboard/presentation/dashboard_screen.dart';
import 'package:mungiz/features/tasks/data/task_local_repository.dart';
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

class _EditTaskRouteLoader extends StatefulWidget {
  const _EditTaskRouteLoader({
    required this.taskId,
    required this.taskRepository,
  });

  final String taskId;
  final TaskLocalRepository taskRepository;

  @override
  State<_EditTaskRouteLoader> createState() => _EditTaskRouteLoaderState();
}

class _EditTaskRouteLoaderState extends State<_EditTaskRouteLoader> {
  late final Future<TaskEntry?> _taskFuture;

  @override
  void initState() {
    super.initState();
    _taskFuture = widget.taskRepository.getTaskById(widget.taskId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TaskEntry?>(
      future: _taskFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final task = snapshot.data;
        if (task == null) {
          return const _TaskEditUnavailableScreen();
        }

        return CreateTaskScreen(existingTask: task);
      },
    );
  }
}

class _TaskEditUnavailableScreen extends StatelessWidget {
  const _TaskEditUnavailableScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تعديل المهمة'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'تعذر العثور على المهمة',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'ربما تم حذفها أو لم تعد متاحة.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
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
  final profileKey = GlobalKey<NavigatorState>(debugLabel: 'profile');
  final routerRefreshNotifier = _RouterRefreshNotifier();
  final taskRepository = ref.read(taskLocalRepositoryProvider);

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
      GoRoute(
        parentNavigatorKey: rootKey,
        path: RoutePaths.editTask,
        name: 'editTask',
        builder: (context, state) {
          final existingTask = state.extra;
          if (existingTask is TaskEntry) {
            return CreateTaskScreen(existingTask: existingTask);
          }

          final taskId = state.pathParameters['id'];
          if (taskId == null || taskId.isEmpty) {
            return const _TaskEditUnavailableScreen();
          }

          return _EditTaskRouteLoader(
            taskId: taskId,
            taskRepository: taskRepository,
          );
        },
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

          // Branch 2 — Profile (path = '/profile')
          StatefulShellBranch(
            navigatorKey: profileKey,
            routes: [
              GoRoute(
                path: RoutePaths.profile,
                name: 'profile',
                builder: (context, state) => const ProfileScreen(),
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
