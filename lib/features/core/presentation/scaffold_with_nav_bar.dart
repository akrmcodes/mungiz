/// Shell scaffold with a premium Material 3 bottom navigation bar.
///
/// Used by the `StatefulShellRoute` in `app_router.dart` to provide
/// persistent tab-based navigation between:
///   - Tab 0: المهام  (Task List)
///   - Tab 1: الإحصائيات (Dashboard)
///
/// Design notes:
///   - Uses [NavigationBar] (M3) for modern pill-indicator tab style.
///   - Navigation bar background uses a subtle translucent blur effect.
///   - NO `flutter_animate` on this widget to prevent the black-screen
///     flash that occurs when animation controllers rebuild on every
///     tab switch.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A shell scaffold that hosts the bottom navigation bar and
/// delegates page rendering to the GoRouter [StatefulShellRoute].
class ScaffoldWithNavBar extends StatelessWidget {
  /// Creates a [ScaffoldWithNavBar].
  const ScaffoldWithNavBar({
    required this.navigationShell,
    Key? key,
  }) : super(key: key ?? const ValueKey<String>('ScaffoldWithNavBar'));

  /// The [StatefulNavigationShell] provided by [StatefulShellRoute].
  ///
  /// Wrapping it in the [Scaffold] body means GoRouter's branch
  /// management handles state preservation across tab switches.
  final StatefulNavigationShell navigationShell;

  // ── Tab definitions ──────────────────────────────────────────────────

  static const _tabs = [
    _TabDef(
      label: 'المهام',
      icon: Icons.checklist_rounded,
      selectedIcon: Icons.checklist_rounded,
    ),
    _TabDef(
      label: 'الإحصائيات',
      icon: Icons.bar_chart_outlined,
      selectedIcon: Icons.bar_chart_rounded,
    ),
  ];

  // ── Navigation helper ────────────────────────────────────────────────

  void _onTabSelected(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      // Return to branch's initial location when re-tapping the
      // current tab (standard UX pattern).
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      // The shell's page stack is the body.
      body: navigationShell,

      // ── Bottom Navigation Bar ───────────────────────────────────
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark
              ? colorScheme.surfaceContainerHigh
              : colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.25),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: isDark ? 0.3 : 0.06,
              ),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: (i) => _onTabSelected(context, i),
            elevation: 0,
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            indicatorColor: colorScheme.primaryContainer.withValues(
              alpha: isDark ? 0.55 : 0.7,
            ),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            animationDuration: const Duration(milliseconds: 300),
            destinations: _tabs
                .map(
                  (tab) => NavigationDestination(
                    icon: Icon(
                      tab.icon,
                      size: 22,
                    ),
                    selectedIcon: Icon(
                      tab.selectedIcon,
                      size: 22,
                      color: colorScheme.onPrimaryContainer,
                    ),
                    label: tab.label,
                    tooltip: tab.label,
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Tab definition data class
// ─────────────────────────────────────────────────────────────────────────

/// Holds the display data for a single navigation tab.
class _TabDef {
  const _TabDef({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
