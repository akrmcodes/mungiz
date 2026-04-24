/// Animated theme toggle button for the app bar.
///
/// Uses a tactile press scale, a circular surface, and an AnimatedSwitcher
/// transition between sun and moon icons to make theme changes feel premium.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mungiz/core/providers/theme_mode_provider.dart';

/// App-bar theme toggle with a premium sun/moon transition.
class AnimatedThemeToggle extends ConsumerStatefulWidget {
  /// Creates an [AnimatedThemeToggle].
  const AnimatedThemeToggle({super.key});

  @override
  ConsumerState<AnimatedThemeToggle> createState() =>
      _AnimatedThemeToggleState();
}

class _AnimatedThemeToggleState extends ConsumerState<AnimatedThemeToggle> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final brightness = theme.brightness;

    final effectiveMode = switch (themeMode) {
      ThemeMode.dark => ThemeMode.dark,
      ThemeMode.light => ThemeMode.light,
      ThemeMode.system =>
        brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
    };

    final isDark = effectiveMode == ThemeMode.dark;
    final nextMode = isDark ? ThemeMode.light : ThemeMode.dark;
    final tooltip = isDark
        ? 'التبديل إلى الوضع الفاتح'
        : 'التبديل إلى الوضع الداكن';

    return Semantics(
      button: true,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: AnimatedScale(
          scale: _isPressed ? 0.94 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: Material(
            color: Colors.transparent,
            child: InkResponse(
              onTapDown: (_) {
                setState(() {
                  _isPressed = true;
                });
              },
              onTapCancel: () {
                setState(() {
                  _isPressed = false;
                });
              },
              onTapUp: (_) {
                setState(() {
                  _isPressed = false;
                });
              },
              onTap: () {
                unawaited(HapticFeedback.selectionClick());
                unawaited(
                  ref.read(themeModeProvider.notifier).changeTheme(nextMode),
                );
              },
              customBorder: const CircleBorder(),
              splashColor: colorScheme.primary.withValues(alpha: 0.12),
              highlightColor: colorScheme.primary.withValues(alpha: 0.08),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? colorScheme.primaryContainer.withValues(alpha: 0.18)
                      : colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.82,
                        ),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.45),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    layoutBuilder: (currentChild, previousChildren) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          ...previousChildren,
                          currentChild ?? const SizedBox.shrink(),
                        ],
                      );
                    },
                    transitionBuilder: (child, animation) {
                      final curved = CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                        reverseCurve: Curves.easeInCubic,
                      );

                      return FadeTransition(
                        opacity: curved,
                        child: ScaleTransition(
                          scale: Tween<double>(
                            begin: 0.72,
                            end: 1,
                          ).animate(curved),
                          child: RotationTransition(
                            turns: Tween<double>(
                              begin: 0.25,
                              end: 0,
                            ).animate(curved),
                            child: child,
                          ),
                        ),
                      );
                    },
                    child: Icon(
                      isDark ? Icons.dark_mode_rounded : Icons.wb_sunny_rounded,
                      key: ValueKey<bool>(isDark),
                      size: 20,
                      color: isDark
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
