/// Riverpod provider for the local Drift database.
///
/// The [AppDatabase] instance is a `keepAlive` singleton — it is opened
/// once at app startup and remains open for the app's lifetime.
library;

import 'package:mungiz/core/database/app_database.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'database_providers.g.dart';

/// Provides the singleton [AppDatabase] (Drift) instance.
///
/// Usage:
/// ```dart
/// final db = ref.watch(appDatabaseProvider);
/// ```
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase();

  // Close the database when the provider is disposed (app teardown).
  ref.onDispose(db.close);

  return db;
}
