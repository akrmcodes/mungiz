/// Riverpod providers for the Dashboard feature.
///
/// [dashboardStatsProvider] watches the local Drift database via
/// [DashboardRepository] and exposes a reactive [AsyncValue<TaskStats>]
/// that the UI can consume directly.
///
/// keepAlive: true — must NOT be autoDispose. StatefulShellRoute keeps
/// both branch widgets alive in the indexed stack but Riverpod listeners
/// detach when a branch is not the active page. autoDispose would tear
/// the stream down on every tab switch, forcing a full reload on return.
library;

import 'dart:developer' as dev;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mungiz/features/dashboard/data/dashboard_repository.dart';
import 'package:mungiz/features/dashboard/domain/task_stats.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provides a live [TaskStats] stream for the authenticated user.
///
/// Declared as a manual [StreamProvider] (not codegen) for the same
/// reason as `taskListProvider` — riverpod_generator throws on
/// Drift-generated types used as return values in watch() calls.
///
/// keepAlive: true — NOT autoDispose. Survives StatefulShellRoute tab
/// switches so the stream is never destroyed when the user switches tabs.
final StreamProvider<TaskStats> dashboardStatsProvider =
    StreamProvider<TaskStats>((ref) {
  final userId =
      Supabase.instance.client.auth.currentUser?.id;

  if (userId == null) {
    dev.log(
      '[dashboardStatsProvider] No authenticated user — returning empty stats.',
      name: 'DashboardProviders',
    );
    return Stream.value(TaskStats.empty());
  }

  dev.log(
    '[dashboardStatsProvider] Subscribing to Drift stream '
    'for user $userId.',
    name: 'DashboardProviders',
  );

  final repo = ref.watch(dashboardRepositoryProvider);
  return repo.watchStats(userId: userId);
});
