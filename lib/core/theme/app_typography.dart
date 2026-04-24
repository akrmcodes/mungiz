/// Typography system for the Mungiz app — optimised for Arabic (RTL).
///
/// Uses the locally bundled **Noto Kufi Arabic** as the primary typeface for
/// all Arabic UI text, with **Inter** as fallback for Latin characters
/// (emails, timestamps, numbers).
///
/// Font files are declared in `pubspec.yaml` and bundled in `assets/fonts/`.
library;

import 'package:flutter/material.dart';

/// Provides Arabic-optimised [TextTheme] configurations.
///
/// Both [arabicTextTheme] and [latinTextTheme] are applied via
/// `ThemeData.textTheme` and `ThemeData.primaryTextTheme` in `AppTheme`.
abstract final class AppTypography {
  // ── Font family names (must match pubspec.yaml declarations) ───────────

  /// Primary Arabic typeface — Noto Kufi Arabic.
  static const String _arabicFamily = 'NotoKufiArabic';

  /// Secondary Latin typeface — Inter (for emails, numbers, code).
  static const String _latinFamily = 'Inter';

  // ── Arabic Text Theme ──────────────────────────────────────────────────

  /// Material 3 text theme using Noto Kufi Arabic.
  ///
  /// Slightly increased letter spacing and line height for Arabic readability.
  static TextTheme get arabicTextTheme => const TextTheme(
        // ── Display ──
        displayLarge: TextStyle(
          fontFamily: _arabicFamily,
          fontSize: 57,
          fontWeight: FontWeight.w700,
          height: 1.3,
          letterSpacing: -0.25,
        ),
        displayMedium: TextStyle(
          fontFamily: _arabicFamily,
          fontSize: 45,
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),
        displaySmall: TextStyle(
          fontFamily: _arabicFamily,
          fontSize: 36,
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),

        // ── Headline ──
        headlineLarge: TextStyle(
          fontFamily: _arabicFamily,
          fontSize: 32,
          fontWeight: FontWeight.w700,
          height: 1.35,
        ),
        headlineMedium: TextStyle(
          fontFamily: _arabicFamily,
          fontSize: 28,
          fontWeight: FontWeight.w600,
          height: 1.35,
        ),
        headlineSmall: TextStyle(
          fontFamily: _arabicFamily,
          fontSize: 24,
          fontWeight: FontWeight.w600,
          height: 1.35,
        ),

        // ── Title ──
        titleLarge: TextStyle(
          fontFamily: _arabicFamily,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
        titleMedium: TextStyle(
          fontFamily: _arabicFamily,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          height: 1.4,
          letterSpacing: 0.15,
        ),
        titleSmall: TextStyle(
          fontFamily: _arabicFamily,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 1.4,
          letterSpacing: 0.1,
        ),

        // ── Body ──
        bodyLarge: TextStyle(
          fontFamily: _arabicFamily,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 1.6,
          letterSpacing: 0.15,
        ),
        bodyMedium: TextStyle(
          fontFamily: _arabicFamily,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.6,
          letterSpacing: 0.25,
        ),
        bodySmall: TextStyle(
          fontFamily: _arabicFamily,
          fontSize: 12,
          fontWeight: FontWeight.w400,
          height: 1.5,
          letterSpacing: 0.4,
        ),

        // ── Label ──
        labelLarge: TextStyle(
          fontFamily: _arabicFamily,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 1.4,
          letterSpacing: 0.1,
        ),
        labelMedium: TextStyle(
          fontFamily: _arabicFamily,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          height: 1.4,
          letterSpacing: 0.5,
        ),
        labelSmall: TextStyle(
          fontFamily: _arabicFamily,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          height: 1.4,
          letterSpacing: 0.5,
        ),
      );

  // ── Latin fallback theme (emails, numbers) ─────────────────────────────

  /// Inter-based text theme used as `primaryTextTheme` and for Latin content.
  static TextTheme get latinTextTheme => const TextTheme(
        bodyLarge: TextStyle(
          fontFamily: _latinFamily,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontFamily: _latinFamily,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontFamily: _latinFamily,
          fontSize: 12,
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
        labelLarge: TextStyle(
          fontFamily: _latinFamily,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
        labelMedium: TextStyle(
          fontFamily: _latinFamily,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          height: 1.4,
        ),
        labelSmall: TextStyle(
          fontFamily: _latinFamily,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          height: 1.4,
        ),
      );
}
