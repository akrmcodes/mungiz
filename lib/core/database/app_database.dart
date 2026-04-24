/// Drift local database — the single source of truth for the Mungiz app.
///
/// All UI reads come from this database. Supabase is the remote sync target
/// and is never queried directly by the presentation layer.
///
/// Tables:
///   - [Profiles] — mirrors `public.profiles` on Supabase.
///   - [Tasks]    — mirrors `public.tasks` with an additional `syncStatus`.
///   - [SyncQueue] — tracks local mutations pending push to Supabase.
library;

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

// =============================================================================
// ENUMS
// =============================================================================

/// Tracks the synchronisation state of a local task row against Supabase.
enum SyncStatus {
  /// Row is in sync with the remote database.
  synced,

  /// Row was created locally and has not yet been pushed.
  pendingCreate,

  /// Row was updated locally and the change has not yet been pushed.
  pendingUpdate,

  /// Row was marked for deletion locally and the delete has
  /// not yet been pushed.
  pendingDelete,
}

// =============================================================================
// TABLE DEFINITIONS
// =============================================================================

/// Local mirror of the Supabase `public.profiles` table.
///
/// One row per authenticated user. The [id] maps 1-to-1 with `auth.users.id`.
@DataClassName('ProfileEntry')
class Profiles extends Table {
  /// UUID primary key — matches the Supabase Auth user ID.
  TextColumn get id => text()();

  /// User's email address.
  TextColumn get email => text()();

  /// Optional display name.
  TextColumn get displayName => text().nullable()();

  /// Optional avatar image URL.
  TextColumn get avatarUrl => text().nullable()();

  /// Timestamp when the profile was created.
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  /// Timestamp of the last profile update.
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Local mirror of the Supabase `public.tasks` table, with an added
/// [syncStatus] column for offline-first synchronisation tracking.
@DataClassName('TaskEntry')
class Tasks extends Table {
  /// UUID primary key — generated locally or received from Supabase.
  TextColumn get id => text()();

  /// Task title (required).
  TextColumn get title => text().withLength(min: 1)();

  /// Optional task description.
  TextColumn get description => text().nullable()();

  /// Whether the task has been marked as completed.
  BoolColumn get isCompleted =>
      boolean().withDefault(const Constant(false))();

  /// Optional due date/time.
  DateTimeColumn get dueAt => dateTime().nullable()();

  /// UUID of the user who created this task.
  @ReferenceName('createdTasks')
  TextColumn get createdBy =>
      text().references(Profiles, #id)();

  /// UUID of the user this task is assigned to.
  @ReferenceName('assignedTasks')
  TextColumn get assignedTo =>
      text().references(Profiles, #id)();

  /// Synchronisation state of this row against the remote database.
  IntColumn get syncStatus => intEnum<SyncStatus>()
      .withDefault(Constant(SyncStatus.synced.index))();

  /// Timestamp when the task was created.
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  /// Timestamp of the last task update.
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Queue of local mutations that need to be pushed to Supabase.
///
/// Each row represents a single create / update / delete operation performed
/// while the device was offline (or before the sync engine processed it).
@DataClassName('SyncQueueEntry')
class SyncQueue extends Table {
  /// Auto-incrementing integer primary key.
  IntColumn get id => integer().autoIncrement()();

  /// Name of the Supabase table this mutation targets (e.g. `tasks`).
  TextColumn get targetTable => text().named('table_name')();

  /// UUID of the affected record.
  TextColumn get recordId => text()();

  /// The type of mutation: `create`, `update`, or `delete`.
  TextColumn get operation => text()();

  /// JSON-encoded payload of the row data at the time of mutation.
  TextColumn get payload => text()();

  /// Timestamp when the mutation was queued.
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}

// =============================================================================
// DATABASE CLASS
// =============================================================================

/// The Drift database for the Mungiz app.
///
/// Usage:
/// ```dart
/// final db = AppDatabase();
/// ```
@DriftDatabase(tables: [Profiles, Tasks, SyncQueue])
class AppDatabase extends _$AppDatabase {
  /// Creates the database with the default native connection.
  AppDatabase() : super(_openConnection());

  /// Creates the database with a custom [QueryExecutor]
  /// — useful for testing.
  AppDatabase.forTesting(super.e);

  /// Bump this whenever the schema changes and add a migration strategy.
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
      },
      onUpgrade: (m, from, to) async {
        // Future migrations go here.
        // Example:
        // if (from < 2) { await m.addColumn(tasks, tasks.newColumn); }
      },
    );
  }
}

// =============================================================================
// CONNECTION HELPER
// =============================================================================

/// Opens a native SQLite connection at the app's documents directory.
///
/// `sqlite3_flutter_libs` (v0.5.x) bundles `libsqlite3.so` into the APK via
/// Gradle so Android can load it. The [LazyDatabase] defers the file-system
/// lookup until the first query, keeping startup fast.
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbDir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbDir.path, 'mungiz.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
