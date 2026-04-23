/// Task list screen — the main authenticated landing screen.
///
/// Displays all tasks from the local Drift database via a reactive
/// stream. Features:
///   - Time-of-day Arabic greeting in the app bar.
///   - Staggered list animations with `flutter_animate`.
///   - Animated toggle chip for showing/hiding completed tasks.
///   - Premium animated FAB for task creation.
///   - Loading shimmer, error, and empty states.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mungiz/core/constants/app_constants.dart';
import 'package:mungiz/core/theme/app_spacing.dart';
import 'package:mungiz/features/auth/data/auth_repository.dart';
import 'package:mungiz/features/tasks/presentation/providers/task_providers.dart';
import 'package:mungiz/features/tasks/presentation/widgets/empty_tasks.dart';
import 'package:mungiz/features/tasks/presentation/widgets/task_card.dart';

/// The main task list screen — the app's default landing screen.
class TaskListScreen extends ConsumerWidget {
  /// Creates a [TaskListScreen].
  const TaskListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final taskAsync = ref.watch(taskListProvider);
    final showCompleted =
        ref.watch(showCompletedProvider);

    return Scaffold(
      // ── App Bar ──────────────────────────────────────────
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              _greeting(),
              style:
                  theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            const Text('مهامي'),
          ],
        ),
        toolbarHeight: 72,
        actions: [
          // ── Sign out ──
          IconButton(
            icon: const Icon(
              Icons.logout_rounded,
            ),
            tooltip: 'تسجيل الخروج',
            onPressed: () async {
              await ref
                  .read(authRepositoryProvider)
                  .signOut();
              if (context.mounted) {
                context.go(RoutePaths.login);
              }
            },
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),

      // ── Body ────────────────────────────────────────────
      body: Column(
        children: [
          // ── Filter bar ──────────────────────────────────
          _FilterBar(
            showCompleted: showCompleted,
            onToggle: () =>
                ref.read(showCompletedProvider.notifier).toggle(),
            colorScheme: colorScheme,
            theme: theme,
          ),

          // ── Task list ───────────────────────────────────
          Expanded(
            child: taskAsync.when(
              data: (tasks) {
                if (tasks.isEmpty) {
                  return EmptyTasks(
                    onCreateTask: () =>
                        context.push(RoutePaths.createTask),
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
                    return TaskCard(
                      task: task,
                      onToggleComplete: () => ref
                          .read(
                            taskActionsProvider,
                          )
                          .toggleComplete(
                            task.id,
                            isCompleted:
                                !task.isCompleted,
                          ),
                    )
                        .animate()
                        .fadeIn(
                          delay: Duration(
                            milliseconds: (index * 50)
                                .clamp(0, 300),
                          ),
                          duration: 400.ms,
                        )
                        .slideX(
                          begin: 0.05,
                          delay: Duration(
                            milliseconds: (index * 50)
                                .clamp(0, 300),
                          ),
                          duration: 400.ms,
                          curve: Curves.easeOutCubic,
                        );
                  },
                );
              },
              loading: () => const _ShimmerList(),
              error: (error, _) => _ErrorState(
                error: error,
                onRetry: () =>
                    ref.invalidate(taskListProvider),
              ),
            ),
          ),
        ],
      ),

      // ── FAB ─────────────────────────────────────────────
      floatingActionButton: _AnimatedFab(
        onPressed: () =>
            context.push(RoutePaths.createTask),
        colorScheme: colorScheme,
      ),
    );
  }

  /// Returns an Arabic greeting based on time of day.
  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'صباح الخير ☀️';
    if (hour < 17) return 'مساء النور 🌤️';
    return 'مساء الخير 🌙';
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
                showCompleted
                    ? 'إخفاء المكتملة'
                    : 'عرض المكتملة',
                style: theme.textTheme.labelMedium,
              ),
              selectedColor:
                  colorScheme.primaryContainer,
              checkmarkColor:
                  colorScheme.onPrimaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: showCompleted
                      ? colorScheme.primary
                          .withValues(alpha: 0.3)
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
            color: colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.4),
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
              color: colorScheme.surfaceContainerHigh
                  .withValues(alpha: 0.5),
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
// Error state
// ─────────────────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.error,
    required this.onRetry,
  });

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(
          AppSpacing.screenPaddingH,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: colorScheme.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'حدث خطأ أثناء تحميل المهام',
              textAlign: TextAlign.center,
              style:
                  theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '$error',
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style:
                  theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}
