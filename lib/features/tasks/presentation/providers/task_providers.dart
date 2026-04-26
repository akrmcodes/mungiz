/// Riverpod providers for the Task feature.
///
/// All task state is derived from the local Drift database via
/// [TaskLocalRepository]. The UI never queries Supabase directly.
///
/// IMPORTANT — keepAlive rationale:
/// Both [showCompletedProvider] and [taskListProvider] MUST be keepAlive
/// (i.e., NOT autoDispose). The app uses StatefulShellRoute.indexedStack;
/// when the user switches to the Dashboard tab, GoRouter keeps the Tasks
/// branch widget alive in the stack but all Riverpod listeners detach.
/// autoDispose providers are torn down the moment their last listener
/// unsubscribes. On return to Tasks, Riverpod must recreate them from
/// scratch. The dependency chain (taskListProvider watches
/// showCompletedProvider) combined with autoDispose creates a race
/// condition: taskListProvider permanently stays in AsyncLoading,
/// rendering the _ShimmerList that appears as a black screen when the
/// theme background hasn't yet resolved.
library;

import 'dart:developer' as dev;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mungiz/core/database/app_database.dart';
import 'package:mungiz/features/tasks/data/task_local_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'task_providers.g.dart';

// ─────────────────────────────────────────────────────────────────────────
// Toggle: show / hide completed tasks
// ─────────────────────────────────────────────────────────────────────────

/// Whether the task list should include completed tasks.
///
/// Defaults to `false` (completed tasks are hidden).
///
/// keepAlive: true — must survive StatefulShellRoute tab switches.
/// If autoDispose, switching to Dashboard and back resets this to
/// `false` and triggers a taskListProvider rebuild cascade.
@Riverpod(keepAlive: true)
class ShowCompleted extends _$ShowCompleted {
  @override
  bool build() => false;

  /// Toggles the visibility of completed tasks.
  void toggle() {
    state = !state;
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Reactive task stream from Drift (manual provider — avoids codegen
// issue with Drift-generated TaskEntry type)
// ─────────────────────────────────────────────────────────────────────────

/// Provides a reactive stream of tasks from the local Drift database.
///
/// Automatically rebuilds when [showCompletedProvider] changes.
/// Returns an empty list when no user is authenticated.
///
/// Uses a manually declared [StreamProvider] because `riverpod_generator`
/// throws `InvalidTypeException` on Drift-generated data classes
/// (e.g. `TaskEntry`).
///
/// keepAlive: true — NOT autoDispose. Survives StatefulShellRoute tab
/// switches so the stream is never torn down mid-navigation. Without
/// keepAlive the provider disposes when Tasks branch loses focus and
/// recreates on return, causing a permanent AsyncLoading black screen.
final StreamProvider<List<TaskEntry>> taskListProvider =
    StreamProvider<List<TaskEntry>>((ref) {
      final userId = Supabase.instance.client.auth.currentUser?.id;

      if (userId == null) {
        dev.log(
          '[taskListProvider] No authenticated user — returning empty list.',
          name: 'TaskProviders',
        );
        return Stream.value([]);
      }

      dev.log(
        '[taskListProvider] Subscribing to Drift stream for user $userId.',
        name: 'TaskProviders',
      );

      final showCompleted = ref.watch(showCompletedProvider);
      final repo = ref.watch(taskLocalRepositoryProvider);

      return repo.watchTasks(
        userId: userId,
        showCompleted: showCompleted,
      );
    });

// ─────────────────────────────────────────────────────────────────────────
// Task actions — simple provider exposing the notifier
// ─────────────────────────────────────────────────────────────────────────

/// Provides a [TaskActionsNotifier] for performing task mutations.
///
/// Uses [TaskLocalRepository] for all writes — changes appear instantly
/// in the UI via the reactive Drift stream.
///
/// Manually declared for the same codegen reason as [taskListProvider].
/// keepAlive implicitly (Provider without autoDispose modifier).
final taskActionsProvider = Provider<TaskActionsNotifier>((ref) {
  return TaskActionsNotifier(
    repo: ref.watch(taskLocalRepositoryProvider),
  );
});

/// Notifier that provides task mutation actions.
///
/// This is a plain class (not a Riverpod notifier subclass) exposed
/// via a standard `Provider`.
class TaskActionsNotifier {
  /// Creates a [TaskActionsNotifier].
  const TaskActionsNotifier({
    required TaskLocalRepository repo,
  }) : _repo = repo;

  final TaskLocalRepository _repo;

  /// Creates a new task, optionally assigned to another user.
  ///
  /// When [assignedTo] is provided, the task is assigned to that user's
  /// ID. Otherwise, it defaults to a personal task (assigned to self).
  ///
  /// The task is written to Drift with `sync_status: pending_create`.
  Future<void> addTask({
    required String title,
    String? description,
    DateTime? dueAt,
    String? assignedTo,
  }) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    await _repo.insertTask(
      title: title,
      userId: userId,
      assignedTo: assignedTo,
      description: description,
      dueAt: dueAt,
    );
  }

  /// Toggles a task's completion status.
  ///
  /// The change is written to Drift with `sync_status: pending_update`.
  Future<void> toggleComplete(
    String taskId, {
    required bool isCompleted,
  }) async {
    await _repo.toggleComplete(
      taskId,
      isCompleted: isCompleted,
    );
  }

  /// Updates an existing task.
  Future<void> updateTask({
    required String taskId,
    required String title,
    required String assignedTo,
    String? description,
    DateTime? dueAt,
  }) async {
    await _repo.updateTask(
      taskId: taskId,
      title: title,
      assignedTo: assignedTo,
      description: description,
      dueAt: dueAt,
    );
  }

  /// Deletes a task, preserving pending-delete sync semantics.
  Future<void> deleteTask(String taskId) async {
    await _repo.deleteTask(taskId);
  }
}
