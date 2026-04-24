/// Riverpod provider for the preloaded SharedPreferences instance.
///
/// The instance is synchronously overridden in main.dart before runApp,
/// which avoids a first-frame theme flash.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provides the app's SharedPreferences instance.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(),
);
