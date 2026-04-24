/// Animated weekly bar chart for the Dashboard.
///
/// Shows the number of tasks completed for each of the last 7 days,
/// using `fl_chart`'s [BarChart] widget with:
///   - Rounded gradient rods.
///   - Clean design: no grid lines, no borders.
///   - Arabic weekday labels on the X-axis.
///   - Interactive touch tooltips.
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mungiz/core/theme/app_spacing.dart';

/// A sleek weekly completion bar chart.
///
/// [weeklyCompletions] must have exactly 7 integers where index 0
/// represents 6 days ago and index 6 represents today.
class WeeklyBarChart extends StatefulWidget {
  /// Creates a [WeeklyBarChart].
  const WeeklyBarChart({
    required this.weeklyCompletions,
    this.animationDelay = Duration.zero,
    super.key,
  });

  /// 7-element list: index 0 = 6 days ago, index 6 = today.
  final List<int> weeklyCompletions;

  /// Staggered entrance animation delay.
  final Duration animationDelay;

  @override
  State<WeeklyBarChart> createState() => _WeeklyBarChartState();
}

class _WeeklyBarChartState extends State<WeeklyBarChart> {
  int _touchedIndex = -1;

  // ── Helpers ──────────────────────────────────────────────────────────

  /// Maps chart index (0–6) to Arabic weekday names.
  ///
  /// Index 0 = 6 days ago; we compute the actual weekday from today.
  String _arabicDay(int chartIndex) {
    const arabic = [
      'الأحد',
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
    ];
    final daysAgo = 6 - chartIndex;
    final date = DateTime.now().subtract(Duration(days: daysAgo));
    // Flutter weekday: 1=Mon…7=Sun. Map to 0-based where 0=Sun.
    return arabic[date.weekday % 7];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Compute maxY as a proper double — clamp returns num.
    final maxRaw = widget.weeklyCompletions
        .fold<int>(0, (a, b) => a > b ? a : b)
        .toDouble();
    final maxY = (maxRaw < 1.0 ? 1.0 : maxRaw) + 1.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        color: isDark
            ? colorScheme.surfaceContainerHigh
            : colorScheme.surface,
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chart legend header
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.tertiary,
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'مهام مكتملة',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Bar chart
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                barTouchData: BarTouchData(
                  touchCallback: (event, response) {
                    setState(() {
                      if (event is FlPointerHoverEvent ||
                          event is FlTapUpEvent ||
                          event is FlPanUpdateEvent) {
                        _touchedIndex =
                            response?.spot?.touchedBarGroupIndex ??
                                -1;
                      } else {
                        _touchedIndex = -1;
                      }
                    });
                  },
                  touchTooltipData: BarTouchTooltipData(
                    tooltipRoundedRadius: 8,
                    getTooltipColor: (_) => isDark
                        ? colorScheme.surfaceContainerHighest
                        : colorScheme.primaryContainer
                            .withValues(alpha: 0.95),
                    tooltipPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    getTooltipItem: (group, groupIndex, rod, _) {
                      final count = rod.toY.round();
                      return BarTooltipItem(
                        '$count\nمهام',
                        theme.textTheme.labelSmall!.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  leftTitles: const AxisTitles(),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final idx = value.round();
                        if (idx < 0 || idx > 6) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(
                            top: AppSpacing.xs,
                          ),
                          child: Text(
                            _arabicDay(idx),
                            style: theme.textTheme.labelSmall
                                ?.copyWith(
                              fontSize: 9,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                // No borders, no grid lines.
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                barGroups: List.generate(7, (i) {
                  final isTouched = i == _touchedIndex;
                  final value =
                      widget.weeklyCompletions[i].toDouble();

                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: value,
                        width: isTouched ? 18 : 14,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: isTouched
                              ? [
                                  colorScheme.tertiary,
                                  colorScheme.primary,
                                ]
                              : [
                                  colorScheme.primary
                                      .withValues(alpha: 0.6),
                                  colorScheme.primary,
                                ],
                        ),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxY,
                          color: colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.3),
                        ),
                      ),
                    ],
                  );
                }),
              ),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
            ),
          ),
        ],
      ),
    )
        .animate(delay: widget.animationDelay)
        .fadeIn(duration: 500.ms, curve: Curves.easeOut)
        .slideY(
          begin: 0.1,
          duration: 500.ms,
          curve: Curves.easeOutCubic,
        );
  }
}
