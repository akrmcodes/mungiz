/// Application entry point for the Mungiz app.
///
/// Initialises the core infrastructure in the correct order:
///   1. Flutter bindings.
///   2. SharedPreferences (theme persistence).
///   3. Supabase (remote backend).
///   4. Runs the app inside a Riverpod [ProviderScope].
///
/// The Drift database is lazily initialised via its Riverpod provider
/// on first access — no explicit init step is needed here.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mungiz/app.dart';
import 'package:mungiz/core/constants/app_constants.dart';
import 'package:mungiz/core/providers/shared_prefs_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Application bootstrap.
///
/// Supabase URL and anon key are injected at build time via:
/// ```sh
/// flutter run --dart-define-from-file=.env
/// ```
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  // ── Supabase init ────────────────────────────────────────
  await Supabase.initialize(
    url: const String.fromEnvironment(EnvKeys.supabaseUrl),
    anonKey: const String.fromEnvironment(
      EnvKeys.supabaseAnonKey,
    ),
  );

  // ── Run app ──────────────────────────────────────────────
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MungizApp(),
    ),
  );
}
