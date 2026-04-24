/// Sync indicator widget — a sleek, animated cloud icon for the app bar.
///
/// Displays the current synchronisation state with smooth transitions:
///   - **Idle**: Cloud with checkmark — all data is synced.
///   - **Syncing**: Rotating sync arrows — sync in progress.
///   - **Error**: Cloud with exclamation — last sync failed.
///   - **Offline**: Cloud off — no network connectivity.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mungiz/features/sync/presentation/providers/sync_providers.dart';

/// A compact sync status indicator designed for the app bar.
///
/// Watches [SyncStatusNotifier] and displays an animated icon
/// reflecting the current sync state. Tapping triggers a manual sync.
class SyncIndicator extends ConsumerWidget {
  /// Creates a [SyncIndicator].
  const SyncIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(syncControllerProvider);

    final colorScheme = Theme.of(context).colorScheme;

    return IconButton(
      onPressed: status == SyncStatus.syncing
          ? null
          : () async => ref
              .read(syncControllerProvider.notifier)
              .manualSync(),
      tooltip: _tooltip(status),
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: animation,
              child: child,
            ),
          );
        },
        child: _buildIcon(
          status: status,
          colorScheme: colorScheme,
        ),
      ),
    );
  }

  Widget _buildIcon({
    required SyncStatus status,
    required ColorScheme colorScheme,
  }) {
    switch (status) {
      case SyncStatus.idle:
        return Icon(
          Icons.cloud_done_rounded,
          key: const ValueKey('idle'),
          color: colorScheme.primary.withValues(alpha: 0.7),
          size: 22,
        );

      case SyncStatus.syncing:
        return Icon(
          Icons.sync_rounded,
          key: const ValueKey('syncing'),
          color: colorScheme.primary,
          size: 22,
        )
            .animate(
              onPlay: (c) => c.repeat(),
            )
            .rotate(
              duration: 1200.ms,
              curve: Curves.easeInOut,
            );

      case SyncStatus.error:
        return Icon(
          Icons.cloud_off_rounded,
          key: const ValueKey('error'),
          color: colorScheme.error,
          size: 22,
        );

      case SyncStatus.offline:
        return Icon(
          Icons.cloud_off_outlined,
          key: const ValueKey('offline'),
          color: colorScheme.onSurfaceVariant
              .withValues(alpha: 0.5),
          size: 22,
        );
    }
  }

  String _tooltip(SyncStatus status) {
    switch (status) {
      case SyncStatus.idle:
        return 'تمت المزامنة';
      case SyncStatus.syncing:
        return 'جارٍ المزامنة...';
      case SyncStatus.error:
        return 'فشلت المزامنة — انقر للمحاولة';
      case SyncStatus.offline:
        return 'غير متصل بالإنترنت';
    }
  }
}
