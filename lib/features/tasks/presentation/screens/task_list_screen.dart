/// Task list screen — the main authenticated landing screen.
///
/// Displays all tasks from the local Drift database via a reactive
/// stream. Features:
///   - Time-of-day Arabic greeting in the app bar.
///   - Staggered list animations with `flutter_animate`.
///   - Animated toggle chip for showing/hiding completed tasks.
///   - Premium animated FAB for task creation.
///   - Assignment badges on task cards (assigned-to / assigned-by).
///   - Loading shimmer, error, and empty states.
library;

import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:mungiz/core/constants/app_constants.dart';
import 'package:mungiz/core/theme/app_spacing.dart';
import 'package:mungiz/core/theme/widgets/animated_theme_toggle.dart';
import 'package:mungiz/features/auth/data/auth_repository.dart';
import 'package:mungiz/features/auth/data/profile_repository.dart';
import 'package:mungiz/features/sync/presentation/widgets/sync_indicator.dart';
import 'package:mungiz/features/tasks/presentation/providers/task_providers.dart';
import 'package:mungiz/features/tasks/presentation/widgets/empty_tasks.dart';
import 'package:mungiz/features/tasks/presentation/widgets/task_card.dart';

/// The main task list screen — the app's default landing screen.
class TaskListScreen extends ConsumerStatefulWidget {
  /// Creates a [TaskListScreen].
  const TaskListScreen({super.key});

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  /// Local cache of resolved display names keyed by user ID.
  ///
  /// Populated lazily as tasks are rendered. Stores the final resolved
  /// string (displayName ?? email) so repeated renders are instant.
  /// A `null` value means the lookup ran but found nothing.
  final Map<String, String?> _profileCache = {};

  /// Resolves a display name for a user ID.
  ///
  /// Returns immediately from the in-memory cache on repeat calls.
  /// On the first call for a given [userId], returns `null` and fires
  /// an async lookup via [ProfileRepository.resolveProfile], which
  /// tries local Drift first then Supabase. When the lookup completes,
  /// [setState] triggers a rebuild with the real name.
  String? _resolveProfileName(String userId) {
    if (_profileCache.containsKey(userId)) {
      return _profileCache[userId];
    }

    // Trigger async lookup; return null for this render cycle.
    unawaited(_lookupProfile(userId));
    return null;
  }

  Future<void> _lookupProfile(String userId) async {
    final name = await ref
        .read(profileRepositoryProvider)
        .resolveProfile(userId);
    if (mounted) {
      setState(() {
        _profileCache[userId] = name;
      });
    }
  }

  /// Returns an Arabic greeting based on time of day.
  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'صباح الخير ☀️';
    if (hour < 17) return 'مساء النور 🌤️';
    return 'مساء الخير 🌙';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final taskAsync = ref.watch(taskListProvider);
    final showCompleted = ref.watch(showCompletedProvider);
    final currentUserId = ref.read(authRepositoryProvider).currentUser?.id;

    return Scaffold(
      // ── App Bar ──────────────────────────────────────────
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              _greeting(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            const Text('مهامي'),
          ],
        ),
        toolbarHeight: 72,
        actions: [
          // ── Sync indicator ──
          const SyncIndicator(),

          const Gap(AppSpacing.xs),

          // ── Theme toggle ──
          const AnimatedThemeToggle(),

          const Gap(AppSpacing.xs),

          // ── Sign out ──
          IconButton(
            icon: const Icon(
              Icons.logout_rounded,
            ),
            tooltip: 'تسجيل الخروج',
            onPressed: () async {
              await ref.read(authRepositoryProvider).signOut();
              if (context.mounted) {
                context.go(RoutePaths.login);
              }
            },
          ),
        ],
      ),

      // ── Body ────────────────────────────────────────────
      body: Column(
        children: [
          // ── Filter bar ──────────────────────────────────
          _FilterBar(
            showCompleted: showCompleted,
            onToggle: () => ref.read(showCompletedProvider.notifier).toggle(),
            colorScheme: colorScheme,
            theme: theme,
          ),

          // ── Task list ───────────────────────────────────
          Expanded(
            child: taskAsync.when(
              data: (tasks) {
                if (tasks.isEmpty) {
                  return EmptyTasks(
                    onCreateTask: () => context.push(RoutePaths.createTask),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(
                    top: AppSpacing.sm,
                    bottom: 100, // FAB clearance
                  ),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];

                    // Resolve profile names for
                    // assignment badges.
                    String? assigneeName;
                    String? creatorName;
                    if (currentUserId != null) {
                      if (task.assignedTo != currentUserId) {
                        assigneeName = _resolveProfileName(
                          task.assignedTo,
                        );
                      }
                      if (task.createdBy != currentUserId) {
                        creatorName = _resolveProfileName(
                          task.createdBy,
                        );
                      }
                    }

                    return TaskCard(
                          task: task,
                          currentUserId: currentUserId ?? '',
                          assigneeName: assigneeName,
                          creatorName: creatorName,
                          onToggleComplete: () => ref
                              .read(
                                taskActionsProvider,
                              )
                              .toggleComplete(
                                task.id,
                                isCompleted: !task.isCompleted,
                              ),
                        )
                        .animate()
                        .fadeIn(
                          delay: Duration(
                            milliseconds: (index * 50).clamp(0, 300),
                          ),
                          duration: 400.ms,
                        )
                        .slideX(
                          begin: 0.05,
                          delay: Duration(
                            milliseconds: (index * 50).clamp(0, 300),
                          ),
                          duration: 400.ms,
                          curve: Curves.easeOutCubic,
                        );
                  },
                );
              },
              loading: () => const _ShimmerList(),
              error: (error, stack) {
                // ── EXTREME OBSERVABILITY ──────────────────────
                // Log the full stack trace to the console so the
                // developer can read it and diagnose the root cause
                // without needing to attach a debugger.
                dev.log(
                  '[TaskListScreen] ERROR in taskListProvider!',
                  name: 'TaskListScreen',
                  error: error,
                  stackTrace: stack,
                  level: 1000, // severe
                );
                return _ErrorState(
                  error: error,
                  stack: stack,
                  onRetry: () => ref.invalidate(taskListProvider),
                );
              },
            ),
          ),
        ],
      ),

      // ── FAB ─────────────────────────────────────────────
      floatingActionButton: _AnimatedFab(
        onPressed: () => context.push(RoutePaths.createTask),
        colorScheme: colorScheme,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Filter bar — toggle chip for completed tasks
// ─────────────────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.showCompleted,
    required this.onToggle,
    required this.colorScheme,
    required this.theme,
  });

  final bool showCompleted;
  final VoidCallback onToggle;
  final ColorScheme colorScheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPaddingH,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: FilterChip(
                  selected: showCompleted,
                  onSelected: (_) => onToggle(),
                  avatar: AnimatedSwitcher(
                    duration: const Duration(
                      milliseconds: 250,
                    ),
                    child: Icon(
                      showCompleted
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                      key: ValueKey(showCompleted),
                      size: 18,
                    ),
                  ),
                  label: Text(
                    showCompleted ? 'إخفاء المكتملة' : 'عرض المكتملة',
                    style: theme.textTheme.labelMedium,
                  ),
                  selectedColor: colorScheme.primaryContainer,
                  checkmarkColor: colorScheme.onPrimaryContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: showCompleted
                          ? colorScheme.primary.withValues(alpha: 0.3)
                          : colorScheme.outlineVariant,
                    ),
                  ),
                ),
              )
              .animate()
              .fadeIn(duration: 400.ms)
              .slideX(
                begin: -0.05,
                duration: 400.ms,
              ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Animated FAB
// ─────────────────────────────────────────────────────────────────────────

class _AnimatedFab extends StatelessWidget {
  const _AnimatedFab({
    required this.onPressed,
    required this.colorScheme,
  });

  final VoidCallback onPressed;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
          onPressed: onPressed,
          icon: const Icon(Icons.add_rounded),
          label: const Text('مهمة جديدة'),
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppSpacing.cardRadius,
            ),
          ),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
        )
        .animate()
        .fadeIn(delay: 300.ms, duration: 500.ms)
        .slideY(
          begin: 0.4,
          delay: 300.ms,
          duration: 500.ms,
          curve: Curves.easeOutBack,
        )
        .scale(
          begin: const Offset(0.8, 0.8),
          delay: 300.ms,
          duration: 500.ms,
          curve: Curves.easeOutBack,
        );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Shimmer loading state
// ─────────────────────────────────────────────────────────────────────────

class _ShimmerList extends StatelessWidget {
  const _ShimmerList();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.sm,
      ),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
              margin: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPaddingH,
                vertical: AppSpacing.sm / 2,
              ),
              height: 88,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  AppSpacing.cardRadius,
                ),
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.4,
                ),
              ),
            )
            .animate(
              onPlay: (c) => c.repeat(),
            )
            .shimmer(
              duration: 1200.ms,
              delay: Duration(
                milliseconds: index * 100,
              ),
              color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
            )
            .animate()
            .fadeIn(
              delay: Duration(
                milliseconds: index * 80,
              ),
              duration: 400.ms,
            );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Error state — EXTREME OBSERVABILITY
// ─────────────────────────────────────────────────────────────────────────

/// A deliberately loud, impossible-to-miss error widget.
///
/// Uses a full red background with white text so any crash in
/// [taskListProvider] is immediately visible without a debugger.
/// The full [stack] trace is rendered on screen and also logged
/// to the console via `dart:developer`.
class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.error,
    required this.stack,
    required this.onRetry,
  });

  final Object error;
  final StackTrace stack;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFB00020), // blazing red
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header ───────────────────────────────────────
              const Row(
                children: [
                  Icon(
                    Icons.bug_report_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '🚨 TASK LIST PROVIDER ERROR',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── Error message ────────────────────────────────
              Text(
                error.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 12),

              // ── Stack trace (scrollable) ─────────────────────
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    stack.toString(),
                    style: const TextStyle(
                      color: Color(0xFFFFCDD2),
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── Retry button ─────────────────────────────────
              ElevatedButton.icon(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFFB00020),
                ),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text(
                  'إعادة المحاولة',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
