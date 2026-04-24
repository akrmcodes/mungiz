/// Riverpod state controller for persisted theme mode selection.
///
/// Reads SharedPreferences synchronously at build time and persists every
/// change immediately so the app never flashes the wrong theme on launch.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mungiz/core/providers/shared_prefs_provider.dart';

/// Exposes the app-wide [ThemeMode].
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

/// Persists the selected [ThemeMode] in SharedPreferences.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const String _storageKey = 'theme_mode';

  @override
  ThemeMode build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final storedMode = prefs.getString(_storageKey);

    return switch (storedMode) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.system,
    };
  }

  Future<void> changeTheme(ThemeMode mode) async {
    state = mode;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_storageKey, mode.name);
  }
}
