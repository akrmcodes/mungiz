/// Sync engine — pushes local mutations to Supabase and pulls remote
/// changes back into Drift.
///
/// Orchestrates the full offline-first synchronisation cycle:
///   1. **Push** — find all tasks with `sync_status != synced`, push each
///      to Supabase, and mark them `synced` on success.
///   2. **Pull** — fetch all remote tasks, resolve conflicts via
///      last-write-wins, and upsert into Drift.
///
/// The engine operates on individual items so a single failure does not
/// block the rest of the queue (partial-sync tolerance).
library;

import 'dart:developer';

import 'package:drift/drift.dart';
import 'package:mungiz/core/database/app_database.dart';
import 'package:mungiz/core/providers/database_providers.dart';
import 'package:mungiz/features/sync/data/conflict_resolver.dart';
import 'package:mungiz/features/tasks/data/task_remote_repository.dart';
import 'package:mungiz/features/tasks/domain/task.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'sync_engine.g.dart';

/// Provides the [SyncEngine] singleton.
@Riverpod(keepAlive: true)
SyncEngine syncEngine(Ref ref) {
  return SyncEngine(
    db: ref.watch(appDatabaseProvider),
    remote: ref.watch(taskRemoteRepositoryProvider),
  );
}

/// Handles bi-directional synchronisation between the local Drift
/// database and the remote Supabase backend.
class SyncEngine {
  /// Creates a [SyncEngine].
  const SyncEngine({
    required AppDatabase db,
    required TaskRemoteRepository remote,
  })  : _db = db,
        _remote = remote;

  final AppDatabase _db;
  final TaskRemoteRepository _remote;

  // ── Full Sync ──────────────────────────────────────────────────────────

  /// Executes a complete synchronisation cycle: push then pull.
  ///
  /// Any individual item failure is logged and skipped so the rest
  /// of the queue can proceed.
  Future<void> fullSync() async {
    final userId =
        Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      log(
        'No authenticated user — skipping sync.',
        name: 'SyncEngine',
      );
      return;
    }

    log('Starting full sync for $userId…', name: 'SyncEngine');

    await pushPendingChanges(userId);
    await pullRemoteChanges(userId);

    log('Full sync complete.', name: 'SyncEngine');
  }

  // ── Push ────────────────────────────────────────────────────────────────

  /// Pushes all locally pending changes to Supabase.
  ///
  /// Iterates tasks where `sync_status != synced` and handles each
  /// operation type individually. On success the local row is marked
  /// `synced`. On failure the item is skipped (the next sync cycle
  /// will retry it).
  Future<void> pushPendingChanges(String userId) async {
    final pending = await (_db.select(_db.tasks)
          ..where(
            (t) => t.syncStatus.equalsValue(SyncStatus.synced).not(),
          ))
        .get();

    if (pending.isEmpty) {
      log('No pending changes to push.', name: 'SyncEngine');
      return;
    }

    log(
      'Pushing ${pending.length} pending change(s)…',
      name: 'SyncEngine',
    );

    for (final entry in pending) {
      try {
        switch (entry.syncStatus) {
          case SyncStatus.pendingCreate:
          case SyncStatus.pendingUpdate:
            await _remote.pushTask(Task.fromDriftEntry(entry));
          case SyncStatus.pendingDelete:
            await _deleteRemoteTask(entry.id);
            // Remove from local DB after successful remote delete.
            await (_db.delete(_db.tasks)
                  ..where((t) => t.id.equals(entry.id)))
                .go();
            continue; // Skip the status update below.
          case SyncStatus.synced:
            continue; // Should not happen, but guard anyway.
        }

        // Mark as synced locally.
        await (_db.update(_db.tasks)
              ..where((t) => t.id.equals(entry.id)))
            .write(
          const TasksCompanion(
            syncStatus: Value(SyncStatus.synced),
          ),
        );
      } on Object catch (e, st) {
        log(
          'Push failed for task ${entry.id} '
          '(${entry.syncStatus.name})',
          name: 'SyncEngine',
          error: e,
          stackTrace: st,
        );
        // Skip this item — it will be retried on the next sync cycle.
      }
    }
  }

  // ── Pull ────────────────────────────────────────────────────────────────

  /// Fetches all tasks from Supabase and upserts them into Drift,
  /// resolving conflicts via last-write-wins.
  Future<void> pullRemoteChanges(String userId) async {
    final remoteTasks = await _remote.fetchAllTasks(userId);

    log(
      'Pulled ${remoteTasks.length} remote task(s).',
      name: 'SyncEngine',
    );

    for (final remote in remoteTasks) {
      try {
        final local = await (_db.select(_db.tasks)
              ..where((t) => t.id.equals(remote.id)))
            .getSingleOrNull();

        if (local == null) {
          // New remote task — insert locally as synced.
          await _db.into(_db.tasks).insertOnConflictUpdate(
                _remoteToCompanion(remote),
              );
          continue;
        }

        // Local row exists — check if it has pending local changes.
        if (local.syncStatus != SyncStatus.synced) {
          // Local has un-pushed edits. Use conflict resolver.
          if (ConflictResolver.remoteWins(
            local: local,
            remote: remote,
          )) {
            // Remote wins — overwrite local.
            await (_db.update(_db.tasks)
                  ..where((t) => t.id.equals(remote.id)))
                .write(_remoteToCompanion(remote));
          }
          // Otherwise local wins — keep local; it will be pushed next cycle.
          continue;
        }

        // Local is synced — always accept remote update.
        await (_db.update(_db.tasks)
              ..where((t) => t.id.equals(remote.id)))
            .write(_remoteToCompanion(remote));
      } on Object catch (e, st) {
        log(
          'Pull upsert failed for task ${remote.id}',
          name: 'SyncEngine',
          error: e,
          stackTrace: st,
        );
      }
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  /// Converts a remote [Task] domain model to a Drift [TasksCompanion]
  /// for upsert.
  TasksCompanion _remoteToCompanion(Task remote) {
    return TasksCompanion(
      id: Value(remote.id),
      title: Value(remote.title),
      description: Value(remote.description),
      isCompleted: Value(remote.isCompleted),
      dueAt: Value(remote.dueAt),
      createdBy: Value(remote.createdBy),
      assignedTo: Value(remote.assignedTo),
      syncStatus: const Value(SyncStatus.synced),
      createdAt: Value(remote.createdAt),
      updatedAt: Value(remote.updatedAt),
    );
  }

  /// Deletes a task from Supabase by [taskId].
  Future<void> _deleteRemoteTask(String taskId) async {
    final client = Supabase.instance.client;
    await client.from('tasks').delete().eq('id', taskId);
  }
}
