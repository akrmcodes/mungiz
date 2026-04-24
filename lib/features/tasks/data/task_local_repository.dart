/// Task local repository — the single source of truth for the UI.
///
/// All task reads and writes go through this repository, which operates
/// exclusively on the local Drift database. The UI never queries Supabase
/// directly.
///
/// Writes are marked with a [SyncStatus] so the Sync Engine (Stage 7)
/// can push them to Supabase later.
library;

import 'dart:developer';

import 'package:drift/drift.dart';
import 'package:mungiz/core/database/app_database.dart';
import 'package:mungiz/core/providers/database_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

part 'task_local_repository.g.dart';

String? _normalizeDisplayName(String? value) {
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  return normalized;
}

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
        (t) => t.assignedTo.equals(userId) | t.createdBy.equals(userId),
      )
      ..where(
        (t) => t.syncStatus
            .equalsValue(
              SyncStatus.pendingDelete,
            )
            .not(),
      )
      ..orderBy([
        (t) => OrderingTerm.desc(t.createdAt),
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
  ///
  /// When [assignedTo] is provided and differs from [userId], the task
  /// is treated as an assigned task (`created_by` ≠ `assigned_to`).
  /// Otherwise, the task defaults to a personal task.
  Future<void> insertTask({
    required String title,
    required String userId,
    String? assignedTo,
    String? description,
    DateTime? dueAt,
  }) async {
    final now = DateTime.now();
    final id = _uuid.v4();
    final effectiveAssignee = assignedTo ?? userId;

    // ── FK safety ─────────────────────────────────────────────────────────
    // The Tasks table has a FOREIGN KEY on createdBy / assignedTo → Profiles(id).
    // If _cacheProfile silently failed at login (e.g. Supabase returned null,
    // or the DB was wiped during development), the insert below would throw
    // "FOREIGN KEY CONSTRAINT FAILED". We proactively upsert a stub profile
    // row so the constraint is always satisfied.
    await _ensureProfileExists(userId);
    if (effectiveAssignee != userId) {
      await _ensureProfileExists(effectiveAssignee);
    }

    await _db
        .into(_db.tasks)
        .insert(
          TasksCompanion.insert(
            id: id,
            title: title,
            description: Value(description),
            createdBy: userId,
            assignedTo: effectiveAssignee,
            dueAt: Value(dueAt),
            syncStatus: const Value(SyncStatus.pendingCreate),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
  }

  // ── FK helpers ───────────────────────────────────────────────────────────

  /// Ensures a [Profiles] row exists for [userId] so that the FK constraint
  /// on [Tasks.createdBy] / [Tasks.assignedTo] is satisfied.
  ///
  /// Priority order:
  ///   1. Already exists locally  → no-op.
  ///   2. Supabase has the row    → upsert full data.
  ///   3. Supabase unreachable    → upsert a minimal stub (email = userId).
  Future<void> _ensureProfileExists(String userId) async {
    // 1. Already cached → nothing to do.
    final existing = await (_db.select(
      _db.profiles,
    )..where((p) => p.id.equals(userId))).getSingleOrNull();
    if (existing != null) return;

    log(
      'Profile not found locally for $userId — attempting remote fetch.',
      name: 'TaskLocalRepository',
    );

    // 2. Try to fetch from Supabase and cache.
    try {
      final client = Supabase.instance.client;
      final data = await client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (data != null) {
        await _db
            .into(_db.profiles)
            .insertOnConflictUpdate(
              ProfilesCompanion(
                id: Value(data['id'] as String),
                email: Value((data['email'] as String?) ?? userId),
                displayName: Value(
                  _normalizeDisplayName(data['display_name'] as String?),
                ),
                avatarUrl: Value(data['avatar_url'] as String?),
              ),
            );
        log(
          'Profile fetched from Supabase and cached for $userId.',
          name: 'TaskLocalRepository',
        );
        return;
      }
    } on Object catch (e, st) {
      log(
        'Remote profile fetch failed — falling back to stub.',
        name: 'TaskLocalRepository',
        error: e,
        stackTrace: st,
      );
    }

    // 3. Offline or no remote row → insert a minimal stub so the FK passes.
    //    The sync engine will overwrite this with real data later.
    final currentUser = Supabase.instance.client.auth.currentUser;
    await _db
        .into(_db.profiles)
        .insertOnConflictUpdate(
          ProfilesCompanion(
            id: Value(userId),
            email: Value(currentUser?.email ?? userId),
            displayName: const Value(null),
            avatarUrl: const Value(null),
          ),
        );
    log(
      'Stub profile inserted for $userId to satisfy FK constraint.',
      name: 'TaskLocalRepository',
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
    await (_db.update(_db.tasks)..where((t) => t.id.equals(taskId))).write(
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
    final query = _db.select(_db.tasks)..where((t) => t.id.equals(id));

    return query.getSingleOrNull();
  }
}
