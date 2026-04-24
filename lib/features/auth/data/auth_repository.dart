/// Authentication repository — bridges Supabase Auth with the
/// local Drift database.
///
/// All auth operations (sign up, sign in, sign out) go through
/// Supabase, and successful results are cached locally in the Drift
/// `Profiles` table for offline access.
library;

import 'dart:developer';

import 'package:drift/drift.dart';
import 'package:mungiz/core/constants/app_constants.dart';
import 'package:mungiz/core/database/app_database.dart';
import 'package:mungiz/core/providers/database_providers.dart';
import 'package:mungiz/core/providers/supabase_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'auth_repository.g.dart';

/// Provides the [AuthRepository] singleton.
@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  return AuthRepository(
    client: ref.watch(supabaseClientProvider),
    db: ref.watch(appDatabaseProvider),
  );
}

/// Handles authentication and local profile caching.
class AuthRepository {
  /// Creates an [AuthRepository].
  const AuthRepository({
    required SupabaseClient client,
    required AppDatabase db,
  })  : _client = client,
        _db = db;

  final SupabaseClient _client;
  final AppDatabase _db;

  // ── Sign Up ──────────────────────────────────────────────

  /// Registers a new user with [email] and [password].
  ///
  /// Supabase Auth creates the user, and the database trigger
  /// auto-creates the `profiles` row. We then fetch and cache
  /// that profile locally.
  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
    );

    final user = response.user;
    if (user != null) {
      await _cacheProfile(user.id);
    }
  }

  // ── Sign In ──────────────────────────────────────────────

  /// Authenticates an existing user with [email] and [password].
  ///
  /// On success, fetches the profile from Supabase and caches
  /// it in the local Drift database.
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    final response =
        await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final user = response.user;
    if (user != null) {
      await _cacheProfile(user.id);
    }
  }

  // ── Sign Out ─────────────────────────────────────────────

  /// Signs out the current user and clears locally cached
  /// profile data.
  Future<void> signOut() async {
    final userId = _client.auth.currentUser?.id;

    await _client.auth.signOut();

    // Clear cached profile from Drift.
    if (userId != null) {
      await (_db.delete(_db.profiles)
            ..where((p) => p.id.equals(userId)))
          .go();
    }
  }

  // ── Current User ─────────────────────────────────────────

  /// Returns the currently authenticated [User], or `null`.
  User? get currentUser => _client.auth.currentUser;

  // ── Internals ────────────────────────────────────────────

  /// Fetches the profile from Supabase and upserts it into
  /// the local Drift `profiles` table.
  Future<void> _cacheProfile(String userId) async {
    try {
      final data = await _client
          .from(SupabaseTables.profiles)
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (data == null) return;

      await _db.into(_db.profiles).insertOnConflictUpdate(
            ProfilesCompanion(
              id: Value(data['id'] as String),
              email: Value(data['email'] as String),
              displayName: Value(
                data['display_name'] as String?,
              ),
              avatarUrl: Value(
                data['avatar_url'] as String?,
              ),
            ),
          );
    } on Object catch (e, st) {
      // Caching failure is non-fatal — the user is still
      // authenticated. The sync engine will retry later.
      // However, we log it so it's visible in the console.
      log(
        '_cacheProfile failed for $userId',
        name: 'AuthRepository',
        error: e,
        stackTrace: st,
      );
    }
  }
}
