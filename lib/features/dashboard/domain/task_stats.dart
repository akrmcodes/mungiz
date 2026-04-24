/// Freezed domain model for dashboard task statistics.
///
/// Computed in-memory from the local Drift database by
/// `DashboardRepository`. Never serialised — JSON annotations
/// are deliberately omitted since this object is not persisted.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'task_stats.freezed.dart';

/// Immutable snapshot of task statistics for the Dashboard.
@freezed
abstract class TaskStats with _$TaskStats {
  /// Creates a [TaskStats] snapshot.
  const factory TaskStats({
    /// Total number of tasks visible to the current user
    /// (assigned to OR created by them), excluding
    /// soft-deleted rows.
    required int totalTasks,

    /// Number of tasks where [isCompleted] is true.
    required int completed,

    /// Number of tasks where [isCompleted] is false.
    required int pending,

    /// Number of incomplete tasks whose [dueAt] is in the past.
    required int overdueCount,

    /// Completion rate as a fraction in [0, 1].
    ///
    /// `completed / totalTasks`, or 0.0 when [totalTasks] is 0.
    required double completionRate,

    /// Tasks completed per day for the last 7 days.
    ///
    /// Index 0 = 6 days ago, index 6 = today.
    /// Used to feed the Weekly Bar Chart.
    required List<int> weeklyCompletions,
  }) = _TaskStats;

  /// Zero-value snapshot used while the first database read
  /// is in-flight.
  factory TaskStats.empty() => const TaskStats(
        totalTasks: 0,
        completed: 0,
        pending: 0,
        overdueCount: 0,
        completionRate: 0,
        weeklyCompletions: [0, 0, 0, 0, 0, 0, 0],
      );
}
