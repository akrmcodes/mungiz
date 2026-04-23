/// Spacing and dimension constants for the Mungiz design system.
///
/// Uses a 4-pt base grid for consistent spatial rhythm across all screens.
/// Named semantically so designers and developers share the same vocabulary.
library;

/// Spacing tokens based on a 4-pt grid.
///
/// Usage:
/// ```dart
/// Padding(padding: EdgeInsets.all(AppSpacing.md))
/// SizedBox(height: AppSpacing.lg)
/// ```
abstract final class AppSpacing {
  // ── Base grid ──────────────────────────────────────────────────────────

  /// 4 pt — hairline spacing (icon–label gap, divider padding).
  static const double xs = 4;

  /// 8 pt — tight spacing (between related elements).
  static const double sm = 8;

  /// 16 pt — default spacing (card padding, section gaps).
  static const double md = 16;

  /// 24 pt — generous spacing (between sections).
  static const double lg = 24;

  /// 32 pt — major section breaks.
  static const double xl = 32;

  /// 48 pt — extra-large (screen-level top/bottom padding).
  static const double xxl = 48;

  // ── Screen-level layout ────────────────────────────────────────────────

  /// Horizontal padding for screen content.
  static const double screenPaddingH = 20;

  /// Vertical padding for screen content (top safe area supplement).
  static const double screenPaddingV = 24;

  // ── Component-specific ─────────────────────────────────────────────────

  /// Card inner padding.
  static const double cardPadding = 16;

  /// Card border radius.
  static const double cardRadius = 16;

  /// Button border radius.
  static const double buttonRadius = 12;

  /// Input field border radius.
  static const double inputRadius = 12;

  /// Bottom sheet border radius (top corners).
  static const double sheetRadius = 24;

  /// FAB elevation.
  static const double fabElevation = 4;

  // ── Responsive breakpoints ─────────────────────────────────────────────

  /// Compact phone (≤ 360 dp).
  static const double breakpointCompact = 360;

  /// Standard phone (≤ 390 dp).
  static const double breakpointPhone = 390;

  /// Tablet (≤ 768 dp).
  static const double breakpointTablet = 768;

  /// Max content width on web/tablet.
  static const double maxContentWidth = 600;
}
