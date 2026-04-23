/// Riverpod provider for network connectivity status.
///
/// Wraps the `connectivity_plus` package and exposes a reactive stream
/// of `List<ConnectivityResult>`. Downstream consumers can derive a
/// simple `bool isOnline` from this.
library;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connectivity_provider.g.dart';

/// Emits the current connectivity status whenever it changes.
///
/// Usage:
/// ```dart
/// final connectivity = ref.watch(connectivityProvider);
/// connectivity.when(
///   data: (results) {
///     final isOnline =
///         !results.contains(ConnectivityResult.none);
///     // ...
///   },
///   // ...
/// );
/// ```
@Riverpod(keepAlive: true)
Stream<List<ConnectivityResult>> connectivity(Ref ref) {
  return Connectivity().onConnectivityChanged;
}
