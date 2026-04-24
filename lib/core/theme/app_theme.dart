/// Material 3 theme configuration for the Mungiz app.
///
/// Provides premium light and dark [ThemeData] variants built from
/// `ColorScheme.fromSeed()` with a sophisticated indigo-teal seed colour.
/// Typography uses the Arabic-first [AppTypography] system.
library;

import 'package:flutter/material.dart';

import 'package:mungiz/core/theme/app_spacing.dart';
import 'package:mungiz/core/theme/app_typography.dart';

/// Centralised theme factory for the Mungiz app.
///
/// Usage in `MaterialApp.router`:
/// ```dart
/// theme: AppTheme.light,
/// darkTheme: AppTheme.dark,
/// ```
abstract final class AppTheme {
  // ── Seed colour ────────────────────────────────────────────────────────

  /// A deep indigo-teal — distinctive, professional, and high-contrast
  /// against both light and dark surfaces.
  static const Color _seedColor = Color(0xFF1A5276);

  // ── Light theme ────────────────────────────────────────────────────────

  /// Light [ThemeData] with Material 3 and Arabic typography.
  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
    );
    return _buildTheme(colorScheme);
  }

  // ── Dark theme ─────────────────────────────────────────────────────────

  /// Dark [ThemeData] with Material 3 and Arabic typography.
  static ThemeData get dark {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
    );
    return _buildTheme(colorScheme);
  }

  // ── Shared builder ─────────────────────────────────────────────────────

  static ThemeData _buildTheme(ColorScheme colorScheme) {
    final isDark = colorScheme.brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,

      // ── Typography ──
      textTheme: AppTypography.arabicTextTheme,
      primaryTextTheme: AppTypography.latinTextTheme,
      fontFamily: 'NotoKufiArabic',

      // ── App bar ──
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 2,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: AppTypography.arabicTextTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
        ),
      ),

      // ── Cards ──
      cardTheme: CardThemeData(
        elevation: isDark ? 2 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPaddingH,
          vertical: AppSpacing.sm,
        ),
      ),

      // ── Elevated buttons ──
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          ),
          textStyle: AppTypography.arabicTextTheme.labelLarge,
          elevation: 0,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
        ),
      ),

      // ── Outlined buttons ──
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          ),
          textStyle: AppTypography.arabicTextTheme.labelLarge,
          side: BorderSide(color: colorScheme.outline),
        ),
      ),

      // ── Text buttons ──
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: AppTypography.arabicTextTheme.labelLarge,
          foregroundColor: colorScheme.primary,
        ),
      ),

      // ── Input decoration ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? colorScheme.surfaceContainerHighest
            : colorScheme.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        labelStyle: AppTypography.arabicTextTheme.bodyMedium,
        hintStyle: AppTypography.arabicTextTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),

      // ── Floating action button ──
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: AppSpacing.fabElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
      ),

      // ── Bottom navigation ──
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        selectedLabelStyle: AppTypography.arabicTextTheme.labelSmall,
        unselectedLabelStyle: AppTypography.arabicTextTheme.labelSmall,
        elevation: 4,
      ),

      // ── Bottom sheet ──
      bottomSheetTheme: BottomSheetThemeData(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.sheetRadius),
          ),
        ),
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        showDragHandle: true,
      ),

      // ── Snackbar ──
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
        ),
        contentTextStyle: AppTypography.arabicTextTheme.bodyMedium?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
      ),

      // ── Divider ──
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        thickness: 1,
        space: AppSpacing.md,
      ),

      // ── Checkbox ──
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return Colors.transparent;
        }),
      ),

      // ── Transitions ──
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
