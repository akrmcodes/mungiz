/// Dashboard repository — aggregates task statistics from Drift.
///
/// All queries run against the local Drift database so the dashboard
/// works 100 % offline. Stats are recomputed on every emission of the
/// underlying Drift stream, giving the UI a reactive, live view.
///
/// Provides:
///   - `watchStats`: a live stream of `TaskStats` for a given user ID.
library;

import 'dart:developer';

import 'package:drift/drift.dart';
import 'package:mungiz/core/database/app_database.dart';
import 'package:mungiz/core/providers/database_providers.dart';
import 'package:mungiz/features/dashboard/domain/task_stats.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dashboard_repository.g.dart';

/// Provides the [DashboardRepository] singleton.
@Riverpod(keepAlive: true)
DashboardRepository dashboardRepository(Ref ref) {
  return DashboardRepository(db: ref.watch(appDatabaseProvider));
}

/// Aggregates task statistics from the local Drift database.
class DashboardRepository {
  /// Creates a [DashboardRepository].
  const DashboardRepository({required AppDatabase db}) : _db = db;

  final AppDatabase _db;

  // ── Watch ──────────────────────────────────────────────────────────────

  /// Returns a reactive [Stream] of [TaskStats] for [userId].
  ///
  /// Emits a new snapshot every time any task row changes. Errors are
  /// caught, logged, and a safe [TaskStats.empty] value is emitted so
  /// the stream never terminates on transient failures.
  Stream<TaskStats> watchStats({required String userId}) {
    final query = _db.select(_db.tasks)
      ..where(
        (t) =>
            t.assignedTo.equals(userId) |
            t.createdBy.equals(userId),
      )
      ..where(
        (t) => t.syncStatus
            .equalsValue(SyncStatus.pendingDelete)
            .not(),
      );

    return query.watch().map(_computeStats).handleError(
      (Object e, StackTrace st) {
        log(
          'DashboardRepository.watchStats error',
          name: 'DashboardRepository',
          error: e,
          stackTrace: st,
        );
        return TaskStats.empty();
      },
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  /// Computes a [TaskStats] snapshot from a list of [TaskEntry] rows.
  ///
  /// Pure function — no I/O, trivially unit-testable.
  TaskStats _computeStats(List<TaskEntry> rows) {
    if (rows.isEmpty) return TaskStats.empty();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Initialise 7-day bucket: index 0 = 6 days ago, index 6 = today.
    final weekly = List<int>.filled(7, 0);

    var completed = 0;
    var overdue = 0;

    for (final task in rows) {
      if (task.isCompleted) {
        completed++;

        // Place the task in the correct weekly bucket by updatedAt
        // (completion timestamp). Only count rows within the last 7 days.
        final updatedDay = DateTime(
          task.updatedAt.year,
          task.updatedAt.month,
          task.updatedAt.day,
        );
        final daysAgo = today.difference(updatedDay).inDays;
        if (daysAgo >= 0 && daysAgo < 7) {
          // Index 6 = today (daysAgo == 0), index 0 = 6 days ago.
          weekly[6 - daysAgo]++;
        }
      } else {
        // Overdue = incomplete + due_at is strictly before today.
        final dueAt = task.dueAt;
        if (dueAt != null) {
          final dueDay = DateTime(
            dueAt.year,
            dueAt.month,
            dueAt.day,
          );
          if (dueDay.isBefore(today)) overdue++;
        }
      }
    }

    final total = rows.length;
    final pending = total - completed;
    final rate = total > 0 ? completed / total : 0.0;

    return TaskStats(
      totalTasks: total,
      completed: completed,
      pending: pending,
      overdueCount: overdue,
      completionRate: rate,
      weeklyCompletions: weekly,
    );
  }
}
