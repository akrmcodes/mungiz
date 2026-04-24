import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mungiz/core/theme/app_theme.dart';

void main() {
  test('print theme contrast ratios', () {
    final pairs = <MapEntry<String, (Color fg, Color bg)>>[
      _pair(
        'light onSurface / surface',
        AppTheme.light.colorScheme.onSurface,
        AppTheme.light.colorScheme.surface,
      ),
      _pair(
        'light onSurfaceVariant / surfaceContainerLowest',
        AppTheme.light.colorScheme.onSurfaceVariant,
        AppTheme.light.colorScheme.surfaceContainerLowest,
      ),
      _pair(
        'light outline / surfaceContainerLowest',
        AppTheme.light.colorScheme.outline,
        AppTheme.light.colorScheme.surfaceContainerLowest,
      ),
      _pair(
        'light outlineVariant / surfaceContainerLowest',
        AppTheme.light.colorScheme.outlineVariant,
        AppTheme.light.colorScheme.surfaceContainerLowest,
      ),
      _pair(
        'light outlineVariant / surface',
        AppTheme.light.colorScheme.outlineVariant,
        AppTheme.light.colorScheme.surface,
      ),
      _pair(
        'light surfaceTint / surface',
        AppTheme.light.colorScheme.surfaceTint,
        AppTheme.light.colorScheme.surface,
      ),
      _pair(
        'light onPrimary / primary',
        AppTheme.light.colorScheme.onPrimary,
        AppTheme.light.colorScheme.primary,
      ),
      _pair(
        'light onPrimaryContainer / primaryContainer',
        AppTheme.light.colorScheme.onPrimaryContainer,
        AppTheme.light.colorScheme.primaryContainer,
      ),
      _pair(
        'light onError / error',
        AppTheme.light.colorScheme.onError,
        AppTheme.light.colorScheme.error,
      ),
      _pair(
        'dark onSurface / surface',
        AppTheme.dark.colorScheme.onSurface,
        AppTheme.dark.colorScheme.surface,
      ),
      _pair(
        'dark onSurfaceVariant / surfaceContainerHighest',
        AppTheme.dark.colorScheme.onSurfaceVariant,
        AppTheme.dark.colorScheme.surfaceContainerHighest,
      ),
      _pair(
        'dark outline / surfaceContainerHighest',
        AppTheme.dark.colorScheme.outline,
        AppTheme.dark.colorScheme.surfaceContainerHighest,
      ),
      _pair(
        'dark outlineVariant / surfaceContainerHighest',
        AppTheme.dark.colorScheme.outlineVariant,
        AppTheme.dark.colorScheme.surfaceContainerHighest,
      ),
      _pair(
        'dark outlineVariant / surface',
        AppTheme.dark.colorScheme.outlineVariant,
        AppTheme.dark.colorScheme.surface,
      ),
      _pair(
        'dark surfaceTint / surface',
        AppTheme.dark.colorScheme.surfaceTint,
        AppTheme.dark.colorScheme.surface,
      ),
      _pair(
        'dark onPrimary / primary',
        AppTheme.dark.colorScheme.onPrimary,
        AppTheme.dark.colorScheme.primary,
      ),
      _pair(
        'dark onPrimaryContainer / primaryContainer',
        AppTheme.dark.colorScheme.onPrimaryContainer,
        AppTheme.dark.colorScheme.primaryContainer,
      ),
      _pair(
        'dark onError / error',
        AppTheme.dark.colorScheme.onError,
        AppTheme.dark.colorScheme.error,
      ),
    ];

    for (final pair in pairs) {
      final fg = pair.value.$1;
      final bg = pair.value.$2;
      final ratio = _contrastRatio(fg, bg);
      debugPrint(
        '${pair.key}: ${ratio.toStringAsFixed(2)} '
        '(${_hex(fg)} on ${_hex(bg)})',
      );
    }
  });
}

MapEntry<String, (Color fg, Color bg)> _pair(
  String label,
  Color fg,
  Color bg,
) {
  return MapEntry(label, (fg, bg));
}

double _contrastRatio(Color foreground, Color background) {
  final l1 = _relativeLuminance(foreground);
  final l2 = _relativeLuminance(background);
  final lighter = l1 > l2 ? l1 : l2;
  final darker = l1 > l2 ? l2 : l1;
  return (lighter + 0.05) / (darker + 0.05);
}

double _relativeLuminance(Color color) {
  double channel(double value) {
    final normalized = value / 255;
    return normalized <= 0.03928
        ? normalized / 12.92
        : math.pow((normalized + 0.055) / 1.055, 2.4).toDouble();
  }

  final r = channel(color.r * 255.0);
  final g = channel(color.g * 255.0);
  final b = channel(color.b * 255.0);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

String _hex(Color color) =>
    '#${_componentHex(color.r)}'
    '${_componentHex(color.g)}'
    '${_componentHex(color.b)}';

String _componentHex(double value) {
  return (value * 255)
      .round()
      .clamp(0, 255)
      .toRadixString(16)
      .padLeft(2, '0')
      .toUpperCase();
}
