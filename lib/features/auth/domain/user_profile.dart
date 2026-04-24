/// Freezed domain model for a user profile.
///
/// Maps 1-to-1 with both the Supabase `public.profiles` table and the
/// local Drift `Profiles` table. JSON keys use snake_case to match
/// the Supabase column naming convention.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile.freezed.dart';
part 'user_profile.g.dart';

/// Immutable representation of a user profile.
@freezed
abstract class UserProfile with _$UserProfile {
  const factory UserProfile({
    /// Supabase Auth user ID (UUID).
    required String id,

    /// User's email address.
    required String email,

    /// Timestamp when the profile was created.
    @JsonKey(name: 'created_at')
    required DateTime createdAt,

    /// Timestamp of the last profile update.
    @JsonKey(name: 'updated_at')
    required DateTime updatedAt,

    /// Optional display name set by the user.
    @JsonKey(name: 'display_name') String? displayName,

    /// Optional URL to the user's avatar image.
    @JsonKey(name: 'avatar_url') String? avatarUrl,
  }) = _UserProfile;

  /// Deserialises from a Supabase JSON row.
  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);
}
