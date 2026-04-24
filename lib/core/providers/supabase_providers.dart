/// Riverpod providers for Supabase services.
///
/// These providers expose the [SupabaseClient] and a reactive stream of
/// authentication state changes. They are `keepAlive` because the Supabase
/// client must persist for the lifetime of the app.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'supabase_providers.g.dart';

/// Provides the global [SupabaseClient] singleton.
///
/// Supabase must already be initialised in `main()` before this provider
/// is read.
@Riverpod(keepAlive: true)
SupabaseClient supabaseClient(Ref ref) {
  return Supabase.instance.client;
}

/// Emits the current [AuthState] every time the user's authentication
/// status changes (sign-in, sign-out, token refresh, etc.).
///
/// Downstream consumers should use
/// `ref.watch(authStateChangesProvider)` to reactively rebuild on
/// auth transitions.
@Riverpod(keepAlive: true)
Stream<AuthState> authStateChanges(Ref ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.auth.onAuthStateChange;
}
