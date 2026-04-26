/// Profile repository — user lookup and local caching.
///
/// Provides three primary operations:
///   - `findUserByEmail`: Queries Supabase `profiles` by email and caches
///     the result in the local Drift database. Requires connectivity.
///   - `updateDisplayName`: Persists the display name to Supabase and Drift.
///   - `getCachedProfile`: Reads a profile from the local Drift database
///     without any network calls.
///   - `resolveProfile`: Local-first lookup by UUID; falls back to Supabase
///     when the row is absent, caches the result, and always returns a
///     displayable string (email or display name).
///
/// Exceptions thrown by `findUserByEmail`:
///   - `UserNotFoundException` — no matching email in Supabase.
///   - `ProfileLookupException` — network/transport failure.
library;

import 'dart:developer';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mungiz/core/constants/app_constants.dart';
import 'package:mungiz/core/database/app_database.dart';
import 'package:mungiz/core/providers/database_providers.dart';
import 'package:mungiz/core/providers/supabase_providers.dart';
import 'package:mungiz/features/auth/data/auth_repository.dart';
import 'package:mungiz/features/auth/domain/user_profile.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'profile_repository.g.dart';

// ─────────────────────────────────────────────────────────────────────────
// Exceptions
// ─────────────────────────────────────────────────────────────────────────

/// Thrown when no Supabase profile matches the provided email.
class UserNotFoundException implements Exception {
  /// Creates a [UserNotFoundException].
  const UserNotFoundException([this.message = 'المستخدم غير موجود']);

  /// Arabic-friendly error message.
  final String message;

  @override
  String toString() => message;
}

/// Thrown when the profile lookup fails due to a network or transport error.
class ProfileLookupException implements Exception {
  /// Creates a [ProfileLookupException].
  const ProfileLookupException([
    this.message = 'تحتاج إلى الاتصال بالإنترنت للبحث عن مستخدم',
  ]);

  /// Arabic-friendly error message.
  final String message;

  @override
  String toString() => message;
}

// ─────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────

/// Provides the [ProfileRepository] singleton.
@Riverpod(keepAlive: true)
ProfileRepository profileRepository(Ref ref) {
  return ProfileRepository(
    client: ref.watch(supabaseClientProvider),
    db: ref.watch(appDatabaseProvider),
  );
}

/// Streams the current authenticated user's cached profile from Drift.
final StreamProvider<ProfileEntry?> currentUserProfileProvider =
    StreamProvider<ProfileEntry?>((ref) {
      final userId = ref.watch(authRepositoryProvider).currentUser?.id;
      if (userId == null) {
        return Stream<ProfileEntry?>.value(null);
      }

      final db = ref.watch(appDatabaseProvider);
      return (db.select(
        db.profiles,
      )..where((p) => p.id.equals(userId))).watchSingleOrNull();
    });

// ─────────────────────────────────────────────────────────────────────────
// Repository
// ─────────────────────────────────────────────────────────────────────────

/// Handles user profile lookup via Supabase and local caching via Drift.
class ProfileRepository {
  /// Creates a [ProfileRepository].
  const ProfileRepository({
    required SupabaseClient client,
    required AppDatabase db,
  }) : _client = client,
       _db = db;

  final SupabaseClient _client;
  final AppDatabase _db;

  // ── Remote lookup ──────────────────────────────────────────────────────

  /// Looks up a user by [email] in Supabase `profiles`.
  ///
  /// On success, the profile is **upserted** into the local Drift
  /// `Profiles` table and a [UserProfile] domain model is returned.
  ///
  /// Throws:
  ///   - [UserNotFoundException] if no profile matches the email.
  ///   - [ProfileLookupException] on network / transport failure.
  Future<UserProfile> findUserByEmail(String email) async {
    try {
      final data = await _client
          .from(SupabaseTables.profiles)
          .select()
          .ilike('email', email.trim())
          .maybeSingle();

      if (data == null) {
        throw const UserNotFoundException();
      }

      // Cache in Drift for offline access.
      await _cacheRemoteProfile(data);

      log(
        'Profile found and cached for ${data['email']}',
        name: 'ProfileRepository',
      );

      return UserProfile.fromJson(data);
    } on UserNotFoundException {
      rethrow;
    } on SocketException {
      throw const ProfileLookupException();
    } on AuthException {
      throw const ProfileLookupException();
    } on PostgrestException catch (e) {
      log(
        'Supabase query error during email lookup',
        name: 'ProfileRepository',
        error: e,
      );
      throw const ProfileLookupException();
    } on Object catch (e, st) {
      log(
        'Unexpected error during email lookup',
        name: 'ProfileRepository',
        error: e,
        stackTrace: st,
      );
      throw const ProfileLookupException();
    }
  }

  /// Updates the user's display name in Supabase and the local Drift cache.
  Future<void> updateDisplayName(
    String userId,
    String displayName,
  ) async {
    final normalizedDisplayName = _normalizeDisplayName(displayName);
    final now = DateTime.now();
    final cachedProfile = await getCachedProfile(userId);
    final email =
        cachedProfile?.email ?? _client.auth.currentUser?.email ?? userId;

    try {
      await _client
          .from(SupabaseTables.profiles)
          .update({
            'display_name': normalizedDisplayName,
            'updated_at': now.toIso8601String(),
          })
          .eq('id', userId);

      await _db
          .into(_db.profiles)
          .insertOnConflictUpdate(
            ProfilesCompanion(
              id: Value(userId),
              email: Value(email),
              displayName: Value(normalizedDisplayName),
              avatarUrl: cachedProfile?.avatarUrl != null
                  ? Value(cachedProfile!.avatarUrl)
                  : const Value.absent(),
              updatedAt: Value(now),
            ),
          );

      log(
        'Display name updated for $userId',
        name: 'ProfileRepository',
      );
    } on SocketException {
      throw const ProfileLookupException();
    } on AuthException {
      throw const ProfileLookupException();
    } on PostgrestException catch (e) {
      log(
        'Supabase update error during display name change',
        name: 'ProfileRepository',
        error: e,
      );
      throw const ProfileLookupException();
    } on Object catch (e, st) {
      log(
        'Unexpected error during display name update',
        name: 'ProfileRepository',
        error: e,
        stackTrace: st,
      );
      throw const ProfileLookupException();
    }
  }

  // ── Local lookup ───────────────────────────────────────────────────────

  /// Returns a locally cached profile by [userId], or `null` if not found.
  ///
  /// This never hits the network — it reads exclusively from Drift.
  Future<ProfileEntry?> getCachedProfile(String userId) async {
    return (_db.select(
      _db.profiles,
    )..where((p) => p.id.equals(userId))).getSingleOrNull();
  }

  // ── Resolve (local-first, remote fallback) ────────────────────────────

  /// Resolves the best available display string for [userId].
  ///
  /// Strategy:
  ///   1. Check the local Drift `profiles` table.
  ///   2. If absent, query Supabase by UUID and cache the result locally.
  ///   3. Return `displayName ?? email`, or `null` if both lookups fail.
  ///
  /// Unlike [getCachedProfile] this method **will** make a network call
  /// when the local row is missing. Callers should handle errors gracefully.
  Future<String?> resolveProfile(String userId) async {
    // 1 — Local hit.
    final cached = await getCachedProfile(userId);
    if (cached != null) {
      return cached.displayLabel;
    }

    // 2 — Remote fallback: query Supabase by the auth UUID.
    try {
      final data = await _client
          .from(SupabaseTables.profiles)
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (data == null) return null;

      // Cache so future calls are instant.
      await _cacheRemoteProfile(data);

      log(
        'Profile resolved from remote for $userId',
        name: 'ProfileRepository',
      );

      return _resolveDisplayLabel(
        displayName: data['display_name'] as String?,
        email: data['email'] as String?,
      );
    } on Object catch (e, st) {
      log(
        'resolveProfile failed for $userId',
        name: 'ProfileRepository',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  Future<void> _cacheRemoteProfile(Map<String, dynamic> data) async {
    await _db
        .into(_db.profiles)
        .insertOnConflictUpdate(
          ProfilesCompanion(
            id: Value(data['id'] as String),
            email: Value(data['email'] as String),
            displayName: Value(
              _normalizeDisplayName(data['display_name'] as String?),
            ),
            avatarUrl: data['avatar_url'] != null
                ? Value(data['avatar_url'] as String?)
                : const Value.absent(),
          ),
        );
  }

  String? _resolveDisplayLabel({
    required String? displayName,
    required String? email,
  }) {
    final normalizedDisplayName = _normalizeDisplayName(displayName);
    if (normalizedDisplayName != null) {
      return normalizedDisplayName;
    }

    final normalizedEmail = email?.trim();
    if (normalizedEmail != null && normalizedEmail.isNotEmpty) {
      return normalizedEmail;
    }

    return null;
  }

  String? _normalizeDisplayName(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }
}
