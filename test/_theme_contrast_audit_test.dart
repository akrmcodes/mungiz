import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mungiz/core/theme/app_theme.dart';

void main() {
  test('print theme contrast ratios', () {
    final pairs = <MapEntry<String, (Color fg, Color bg)>>[
      MapEntry('light onSurface / surface', (AppTheme.light.colorScheme.onSurface, AppTheme.light.colorScheme.surface)),
      MapEntry('light onSurfaceVariant / surfaceContainerLowest', (AppTheme.light.colorScheme.onSurfaceVariant, AppTheme.light.colorScheme.surfaceContainerLowest)),
      MapEntry('light outline / surfaceContainerLowest', (AppTheme.light.colorScheme.outline, AppTheme.light.colorScheme.surfaceContainerLowest)),
      MapEntry('light outlineVariant / surfaceContainerLowest', (AppTheme.light.colorScheme.outlineVariant, AppTheme.light.colorScheme.surfaceContainerLowest)),
      MapEntry('light outlineVariant / surface', (AppTheme.light.colorScheme.outlineVariant, AppTheme.light.colorScheme.surface)),
      MapEntry('light surfaceTint / surface', (AppTheme.light.colorScheme.surfaceTint, AppTheme.light.colorScheme.surface)),
      MapEntry('light onPrimary / primary', (AppTheme.light.colorScheme.onPrimary, AppTheme.light.colorScheme.primary)),
      MapEntry('light onPrimaryContainer / primaryContainer', (AppTheme.light.colorScheme.onPrimaryContainer, AppTheme.light.colorScheme.primaryContainer)),
      MapEntry('light onError / error', (AppTheme.light.colorScheme.onError, AppTheme.light.colorScheme.error)),
      MapEntry('dark onSurface / surface', (AppTheme.dark.colorScheme.onSurface, AppTheme.dark.colorScheme.surface)),
      MapEntry('dark onSurfaceVariant / surfaceContainerHighest', (AppTheme.dark.colorScheme.onSurfaceVariant, AppTheme.dark.colorScheme.surfaceContainerHighest)),
      MapEntry('dark outline / surfaceContainerHighest', (AppTheme.dark.colorScheme.outline, AppTheme.dark.colorScheme.surfaceContainerHighest)),
      MapEntry('dark outlineVariant / surfaceContainerHighest', (AppTheme.dark.colorScheme.outlineVariant, AppTheme.dark.colorScheme.surfaceContainerHighest)),
      MapEntry('dark outlineVariant / surface', (AppTheme.dark.colorScheme.outlineVariant, AppTheme.dark.colorScheme.surface)),
      MapEntry('dark surfaceTint / surface', (AppTheme.dark.colorScheme.surfaceTint, AppTheme.dark.colorScheme.surface)),
      MapEntry('dark onPrimary / primary', (AppTheme.dark.colorScheme.onPrimary, AppTheme.dark.colorScheme.primary)),
      MapEntry('dark onPrimaryContainer / primaryContainer', (AppTheme.dark.colorScheme.onPrimaryContainer, AppTheme.dark.colorScheme.primaryContainer)),
      MapEntry('dark onError / error', (AppTheme.dark.colorScheme.onError, AppTheme.dark.colorScheme.error)),
    ];

    for (final pair in pairs) {
      final fg = pair.value.$1;
      final bg = pair.value.$2;
      final ratio = _contrastRatio(fg, bg);
      // ignore: avoid_print
      print('${pair.key}: ${ratio.toStringAsFixed(2)} (${_hex(fg)} on ${_hex(bg)})');
    }
  });
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

  // ignore: no_leading_underscores_for_local_identifiers
  final r = channel(color.red.toDouble());
  // ignore: no_leading_underscores_for_local_identifiers
  final g = channel(color.green.toDouble());
  // ignore: no_leading_underscores_for_local_identifiers
  final b = channel(color.blue.toDouble());
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

String _hex(Color color) => '#${color.red.toRadixString(16).padLeft(2, '0').toUpperCase()}${color.green.toRadixString(16).padLeft(2, '0').toUpperCase()}${color.blue.toRadixString(16).padLeft(2, '0').toUpperCase()}';
