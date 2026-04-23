/// Application entry point for the Mungiz app.
///
/// Initialises the core infrastructure in the correct order:
///   1. Flutter bindings.
///   2. Supabase (remote backend).
///   3. Runs the app inside a Riverpod [ProviderScope].
///
/// The Drift database is lazily initialised via its Riverpod provider
/// on first access — no explicit init step is needed here.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mungiz/app.dart';
import 'package:mungiz/core/constants/app_constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Application bootstrap.
///
/// Supabase URL and anon key are injected at build time via:
/// ```sh
/// flutter run --dart-define-from-file=.env
/// ```
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Supabase init ────────────────────────────────────────
  await Supabase.initialize(
    url: const String.fromEnvironment(EnvKeys.supabaseUrl),
    anonKey: const String.fromEnvironment(
      EnvKeys.supabaseAnonKey,
    ),
  );

  // ── Run app ──────────────────────────────────────────────
  runApp(
    const ProviderScope(
      child: MungizApp(),
    ),
  );
}
