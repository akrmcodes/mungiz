/// Riverpod providers for the Task feature.
///
/// All task state is derived from the local Drift database via
/// [TaskLocalRepository]. The UI never queries Supabase directly.
library;

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
@riverpod
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
final StreamProvider<List<TaskEntry>> taskListProvider =
    StreamProvider.autoDispose<List<TaskEntry>>((ref) {
  final userId =
      Supabase.instance.client.auth.currentUser?.id;

  if (userId == null) return Stream.value([]);

  final showCompleted =
      ref.watch(showCompletedProvider);
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

  /// Creates a new personal task.
  ///
  /// The task is written to Drift with `sync_status: pending_create`.
  Future<void> addTask({
    required String title,
    String? description,
    DateTime? dueAt,
  }) async {
    final userId =
        Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    await _repo.insertTask(
      title: title,
      userId: userId,
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
}
