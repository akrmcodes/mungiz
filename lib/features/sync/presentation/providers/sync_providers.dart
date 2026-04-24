/// Sync providers — connectivity-aware automatic synchronisation.
///
/// Watches the device's network state via `connectivity_plus` and
/// triggers a full push-then-pull sync cycle:
///   - **Automatically** when connectivity is restored (offline → online).
///   - **Periodically** every `_syncIntervalMinutes` minutes while online.
///   - **Manually** via `SyncController.manualSync`.
///
/// Exposes a [SyncStatus] enum so the UI can display a sync indicator.
library;

import 'dart:async';
import 'dart:developer';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mungiz/core/providers/connectivity_provider.dart';
import 'package:mungiz/features/sync/data/sync_engine.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sync_providers.g.dart';

// ─────────────────────────────────────────────────────────────────────────
// Sync status enum
// ─────────────────────────────────────────────────────────────────────────

/// Represents the current state of the synchronisation engine.
enum SyncStatus {
  /// The engine is idle — all data is synced.
  idle,

  /// A sync cycle is currently in progress.
  syncing,

  /// The last sync cycle encountered an error.
  error,

  /// The device is offline — sync is not possible.
  offline,
}

// ─────────────────────────────────────────────────────────────────────────
// Sync status notifier (code-gen)
// ─────────────────────────────────────────────────────────────────────────

/// Provides and manages the current [SyncStatus].
@Riverpod(keepAlive: true)
class SyncStatusNotifier extends _$SyncStatusNotifier {
  @override
  SyncStatus build() => SyncStatus.idle;

  /// Updates the sync status.
  // ignore: use_setters_to_change_properties
  void set(SyncStatus status) {
    state = status;
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Sync controller (code-gen — keepAlive so it survives navigation)
// ─────────────────────────────────────────────────────────────────────────

/// Interval between automatic sync cycles when online.
const _syncIntervalMinutes = 5;

/// Controls automatic and manual synchronisation.
///
/// Lifecycle:
///   1. On creation, listens to connectivity changes.
///   2. When connectivity transitions from offline → online, triggers
///      a full sync.
///   3. While online, a periodic timer fires every `_syncIntervalMinutes`
///      minutes.
///   4. UI can call `manualSync` for user-initiated refresh.
@Riverpod(keepAlive: true)
class SyncControllerNotifier extends _$SyncControllerNotifier {
  Timer? _periodicTimer;
  bool _wasOffline = false;
  bool _isSyncing = false;

  @override
  SyncStatus build() {
    // Listen to connectivity changes and register cleanup.
    ref
      ..listen<AsyncValue<List<ConnectivityResult>>>(
        connectivityProvider,
        (previous, next) {
          next.whenData(_onConnectivityChanged);
        },
        fireImmediately: true,
      )
      ..onDispose(_stopPeriodicTimer);

    return SyncStatus.idle;
  }

  void _onConnectivityChanged(
    List<ConnectivityResult> results,
  ) {
    final isOnline =
        !results.contains(ConnectivityResult.none);

    if (isOnline && _wasOffline) {
      log(
        'Connectivity restored — triggering sync.',
        name: 'SyncController',
      );
      unawaited(_performSync());
    }

    _wasOffline = !isOnline;

    if (isOnline) {
      _startPeriodicTimer();
      if (!_isSyncing) {
        state = SyncStatus.idle;
      }
    } else {
      _stopPeriodicTimer();
      state = SyncStatus.offline;
    }
  }

  /// Triggers a manual sync cycle (e.g. pull-to-refresh).
  Future<void> manualSync() async {
    await _performSync();
  }

  Future<void> _performSync() async {
    if (_isSyncing) return;
    _isSyncing = true;

    state = SyncStatus.syncing;

    try {
      await ref.read(syncEngineProvider).fullSync();
      state = SyncStatus.idle;
    } on Object catch (e, st) {
      log(
        'Sync cycle failed',
        name: 'SyncController',
        error: e,
        stackTrace: st,
      );
      state = SyncStatus.error;
    } finally {
      _isSyncing = false;
    }
  }

  void _startPeriodicTimer() {
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(
      const Duration(minutes: _syncIntervalMinutes),
      (_) => unawaited(_performSync()),
    );
  }

  void _stopPeriodicTimer() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }
}
