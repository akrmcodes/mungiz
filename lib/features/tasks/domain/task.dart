/// Freezed domain model for a task.
///
/// Maps to both the Supabase `public.tasks` table and the local Drift
/// `Tasks` table. JSON keys use snake_case to match the Supabase column
/// naming convention.
///
/// The `syncStatus` field tracks offline-first synchronisation state and
/// is local-only (never sent to Supabase).
library;

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mungiz/core/database/app_database.dart';

part 'task.freezed.dart';
part 'task.g.dart';

/// Immutable representation of a task.
@freezed
abstract class Task with _$Task {
  const factory Task({
    /// UUID primary key.
    required String id,

    /// Task title (required, min 1 char).
    required String title,

    /// UUID of the user who created this task.
    @JsonKey(name: 'created_by') required String createdBy,

    /// UUID of the user this task is assigned to.
    @JsonKey(name: 'assigned_to') required String assignedTo,

    /// Timestamp when the task was created.
    @JsonKey(name: 'created_at') required DateTime createdAt,

    /// Timestamp of the last task update.
    @JsonKey(name: 'updated_at') required DateTime updatedAt,

    /// Optional task description.
    String? description,

    /// Whether the task has been marked as completed.
    @Default(false) @JsonKey(name: 'is_completed') bool isCompleted,

    /// Optional due date/time.
    @JsonKey(name: 'due_at') DateTime? dueAt,

    /// Local-only sync tracking — excluded from JSON serialisation.
    @JsonKey(includeFromJson: false, includeToJson: false)
    @Default(SyncStatus.synced)
    SyncStatus syncStatus,
  }) = _Task;

  /// Deserialises from a Supabase JSON row.
  factory Task.fromJson(Map<String, dynamic> json) =>
      _$TaskFromJson(json);

  /// Maps a Drift [TaskEntry] to the domain [Task] model.
  factory Task.fromDriftEntry(TaskEntry entry) {
    return Task(
      id: entry.id,
      title: entry.title,
      description: entry.description,
      isCompleted: entry.isCompleted,
      dueAt: entry.dueAt,
      createdBy: entry.createdBy,
      assignedTo: entry.assignedTo,
      syncStatus: entry.syncStatus,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
    );
  }
}
