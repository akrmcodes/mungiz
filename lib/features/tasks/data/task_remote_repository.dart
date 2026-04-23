/// Task remote repository — Supabase push/pull logic.
///
/// This repository is used exclusively by the Sync Engine (Stage 7).
/// The UI **never** calls these methods directly. All user-facing reads
/// come from the task local repository (Drift).
library;

import 'package:mungiz/core/constants/app_constants.dart';
import 'package:mungiz/core/providers/supabase_providers.dart';
import 'package:mungiz/features/tasks/domain/task.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'task_remote_repository.g.dart';

/// Provides the [TaskRemoteRepository] singleton.
@Riverpod(keepAlive: true)
TaskRemoteRepository taskRemoteRepository(Ref ref) {
  return TaskRemoteRepository(
    client: ref.watch(supabaseClientProvider),
  );
}

/// Supabase-backed remote repository for task synchronisation.
///
/// Methods here are called by the Sync Engine, not the UI.
class TaskRemoteRepository {
  /// Creates a [TaskRemoteRepository].
  const TaskRemoteRepository({
    required SupabaseClient client,
  }) : _client = client;

  final SupabaseClient _client;

  // ── Pull ──────────────────────────────────────────────────────────────

  /// Fetches all tasks from Supabase for the current user.
  ///
  /// Used by the Sync Engine during the pull phase.
  Future<List<Task>> fetchAllTasks(String userId) async {
    final data = await _client
        .from(SupabaseTables.tasks)
        .select()
        .or('created_by.eq.$userId,assigned_to.eq.$userId')
        .order('created_at', ascending: false);

    return data.map(Task.fromJson).toList();
  }

  // ── Push ──────────────────────────────────────────────────────────────

  /// Upserts a task to Supabase.
  ///
  /// Used by the Sync Engine to push locally created or updated tasks.
  Future<void> pushTask(Task task) async {
    final json = task.toJson();
    await _client.from(SupabaseTables.tasks).upsert(json);
  }

  /// Updates only the completion status of a task on Supabase.
  ///
  /// Lighter than a full upsert when only `is_completed` changed.
  Future<void> pushCompletion(
    String taskId, {
    required bool isCompleted,
  }) async {
    await _client.from(SupabaseTables.tasks).update({
      'is_completed': isCompleted,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', taskId);
  }
}
