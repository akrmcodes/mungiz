/// Application-wide constants for the Mungiz app.
///
/// All route paths, Supabase table names, and shared configuration values
/// live here as compile-time constants to prevent typos and enable easy
/// refactoring.
library;

/// Route path constants used by `GoRouter`.
///
/// Every named route in the app references these constants rather than
/// hard-coded strings.
abstract final class RoutePaths {
  /// Home / task list — the app's default authenticated landing screen.
  static const String home = '/';

  /// Login screen.
  static const String login = '/login';

  /// Registration screen.
  static const String register = '/register';

  /// Create a new task.
  static const String createTask = '/tasks/create';

  /// Edit an existing task.
  static const String editTask = '/tasks/edit/:id';

  /// Dashboard / analytics.
  static const String dashboard = '/dashboard';

  /// Profile / account.
  static const String profile = '/profile';
}

/// Supabase remote table names, kept in sync with `supabase/schema.sql`.
abstract final class SupabaseTables {
  static const String profiles = 'profiles';
  static const String tasks = 'tasks';
}

/// Environment variable keys passed via `--dart-define-from-file=.env`.
abstract final class EnvKeys {
  static const String supabaseUrl = 'SUPABASE_URL';
  static const String supabaseAnonKey = 'SUPABASE_ANON_KEY';
}
