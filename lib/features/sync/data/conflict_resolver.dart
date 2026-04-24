/// Conflict resolution strategy for offline-first synchronisation.
///
/// Implements a strict **last-write-wins** (LWW) strategy by comparing
/// `updated_at` timestamps between the local Drift entry and the remote
/// Supabase entry. When timestamps are equal, the server (remote) wins
/// to maintain data authority.
library;

import 'package:mungiz/core/database/app_database.dart';
import 'package:mungiz/features/tasks/domain/task.dart';

/// Determines which version of a task should be kept when a conflict
/// is detected during synchronisation.
///
/// A conflict occurs when the same task has been modified both locally
/// (in Drift) and remotely (in Supabase) since the last sync.
abstract final class ConflictResolver {
  /// Compares [local] and [remote] versions of the same task.
  ///
  /// Returns `true` if the **remote** version should overwrite the local
  /// one (i.e. the remote wins). Returns `false` if the local version
  /// should be preserved and pushed to Supabase.
  ///
  /// Strategy: **last-write-wins** (LWW).
  ///   - If `remote.updatedAt >= local.updatedAt` → remote wins.
  ///   - Otherwise → local wins.
  static bool remoteWins({
    required TaskEntry local,
    required Task remote,
  }) {
    return !remote.updatedAt.isBefore(local.updatedAt);
  }
}
