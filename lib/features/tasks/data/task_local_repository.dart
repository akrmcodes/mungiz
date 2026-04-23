/// Task local repository — the single source of truth for the UI.
///
/// All task reads and writes go through this repository, which operates
/// exclusively on the local Drift database. The UI never queries Supabase
/// directly.
///
/// Writes are marked with a [SyncStatus] so the Sync Engine (Stage 7)
/// can push them to Supabase later.
library;

import 'package:drift/drift.dart';
import 'package:mungiz/core/database/app_database.dart';
import 'package:mungiz/core/providers/database_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'task_local_repository.g.dart';

/// Provides the [TaskLocalRepository] singleton.
@Riverpod(keepAlive: true)
TaskLocalRepository taskLocalRepository(Ref ref) {
  return TaskLocalRepository(db: ref.watch(appDatabaseProvider));
}

/// Drift-backed task repository — the **single source of truth** for task
/// data in the Mungiz app.
class TaskLocalRepository {
  /// Creates a [TaskLocalRepository].
  const TaskLocalRepository({required AppDatabase db}) : _db = db;

  final AppDatabase _db;

  static const _uuid = Uuid();

  // ── Watch (reactive stream) ──────────────────────────────────────────

  /// Returns a reactive stream of tasks for [userId].
  ///
  /// When [showCompleted] is `false` (default), only incomplete tasks
  /// are emitted. Set to `true` to include completed tasks.
  ///
  /// Results are ordered by creation date, newest first.
  Stream<List<TaskEntry>> watchTasks({
    required String userId,
    bool showCompleted = false,
  }) {
    final query = _db.select(_db.tasks)
      ..where(
        (t) =>
            t.assignedTo.equals(userId) |
            t.createdBy.equals(userId),
      )
      ..where(
        (t) => t.syncStatus.equalsValue(
          SyncStatus.pendingDelete,
        ).not(),
      )
      ..orderBy([
        (t) =>
            OrderingTerm.desc(t.createdAt),
      ]);

    if (!showCompleted) {
      query.where((t) => t.isCompleted.equals(false));
    }

    return query.watch();
  }

  // ── Insert ───────────────────────────────────────────────────────────

  /// Inserts a new task into the local database.
  ///
  /// The task is created with [SyncStatus.pendingCreate] so the Sync
  /// Engine knows to push it to Supabase.
  Future<void> insertTask({
    required String title,
    required String userId,
    String? description,
    DateTime? dueAt,
  }) async {
    final now = DateTime.now();
    final id = _uuid.v4();

    await _db.into(_db.tasks).insert(
          TasksCompanion.insert(
            id: id,
            title: title,
            description: Value(description),
            createdBy: userId,
            assignedTo: userId,
            dueAt: Value(dueAt),
            syncStatus: const Value(SyncStatus.pendingCreate),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
  }

  // ── Toggle Completion ────────────────────────────────────────────────

  /// Toggles the completion status of a task.
  ///
  /// Sets [SyncStatus.pendingUpdate] so the change is queued for sync.
  Future<void> toggleComplete(
    String taskId, {
    required bool isCompleted,
  }) async {
    await (_db.update(_db.tasks)
          ..where((t) => t.id.equals(taskId)))
        .write(
      TasksCompanion(
        isCompleted: Value(isCompleted),
        syncStatus: const Value(SyncStatus.pendingUpdate),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // ── Single Lookup ────────────────────────────────────────────────────

  /// Returns a single task by [id], or `null` if not found.
  Future<TaskEntry?> getTaskById(String id) async {
    final query = _db.select(_db.tasks)
      ..where((t) => t.id.equals(id));

    return query.getSingleOrNull();
  }
}
