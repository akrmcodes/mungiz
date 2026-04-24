/// Animated status donut chart for the Dashboard.
///
/// Shows task distribution across three statuses — Completed, Pending,
/// and Overdue — using `fl_chart`'s [PieChart] widget with:
///   - Donut design (centre hole).
///   - Interactive touch — touched section expands with a radius boost.
///   - Premium colour palette aligned with the app's design system.
///   - Glowing legend below the chart.
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mungiz/core/theme/app_spacing.dart';

/// A donut chart showing task status distribution.
class StatusDonutChart extends StatefulWidget {
  /// Creates a [StatusDonutChart].
  const StatusDonutChart({
    required this.completed,
    required this.pending,
    required this.overdue,
    this.animationDelay = Duration.zero,
    super.key,
  });

  /// Count of completed tasks.
  final int completed;

  /// Count of pending (non-overdue) tasks.
  final int pending;

  /// Count of overdue tasks.
  final int overdue;

  /// Staggered entrance animation delay.
  final Duration animationDelay;

  @override
  State<StatusDonutChart> createState() => _StatusDonutChartState();
}

class _StatusDonutChartState extends State<StatusDonutChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final total =
        widget.completed + widget.pending + widget.overdue;

    // Colour palette
    const completedColor = Color(0xFF27AE60);
    const pendingColor = Color(0xFFF39C12);
    final overdueColor = colorScheme.error;

    final sections = <_DonutSection>[
      _DonutSection(
        label: 'مكتملة',
        count: widget.completed,
        color: completedColor,
        index: 0,
      ),
      _DonutSection(
        label: 'قيد التنفيذ',
        count: widget.pending,
        color: pendingColor,
        index: 1,
      ),
      _DonutSection(
        label: 'متأخرة',
        count: widget.overdue,
        color: overdueColor,
        index: 2,
      ),
    ].where((s) => s.count > 0).toList();

    // If no data, show a uniform empty ring.
    final isEmpty = total == 0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
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
        children: [
          // ── Donut ────────────────────────────────────────────
          SizedBox(
            height: 180,
            child: isEmpty
                ? _EmptyDonut(colorScheme: colorScheme)
                : PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 52,
                      startDegreeOffset: -90,
                      pieTouchData: PieTouchData(
                        touchCallback: (event, response) {
                          setState(() {
                            if (event is FlPointerHoverEvent ||
                                event is FlTapUpEvent ||
                                event is FlPanUpdateEvent) {
                              _touchedIndex = response
                                      ?.touchedSection
                                      ?.touchedSectionIndex ??
                                  -1;
                            } else {
                              _touchedIndex = -1;
                            }
                          });
                        },
                      ),
                      sections: sections.map((s) {
                        final isTouched =
                            s.index == _touchedIndex;
                        final baseRadius = isTouched ? 72.0 : 60.0;
                        final pct = total > 0
                            ? (s.count / total * 100).round()
                            : 0;

                        return PieChartSectionData(
                          value: s.count.toDouble(),
                          color: s.color,
                          radius: baseRadius,
                          title: isTouched ? '$pct%' : '',
                          titleStyle:
                              theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                          titlePositionPercentageOffset: 0.6,
                        );
                      }).toList(),
                    ),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                  ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // ── Legend ───────────────────────────────────────────
          if (!isEmpty) ...[
            _DonutLegend(
              sections: sections,
              total: total,
              theme: theme,
              colorScheme: colorScheme,
            ),
          ] else ...[
            Text(
              'لا توجد مهام بعد',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
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

// ─────────────────────────────────────────────────────────────────────────
// Legend
// ─────────────────────────────────────────────────────────────────────────

class _DonutLegend extends StatelessWidget {
  const _DonutLegend({
    required this.sections,
    required this.total,
    required this.theme,
    required this.colorScheme,
  });

  final List<_DonutSection> sections;
  final int total;
  final ThemeData theme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: sections.map((s) {
        final pct = total > 0
            ? (s.count / total * 100).round()
            : 0;

        return Column(
          children: [
            // Glowing dot
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: s.color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: s.color.withValues(alpha: 0.5),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              s.label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              '$pct%',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w800,
                fontFamily: 'Inter',
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Empty state ring
// ─────────────────────────────────────────────────────────────────────────

class _EmptyDonut extends StatelessWidget {
  const _EmptyDonut({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 120,
        height: 120,
        child: CircularProgressIndicator(
          value: 1,
          strokeWidth: 12,
          color: colorScheme.surfaceContainerHighest
              .withValues(alpha: 0.5),
          backgroundColor: Colors.transparent,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Data model
// ─────────────────────────────────────────────────────────────────────────

class _DonutSection {
  const _DonutSection({
    required this.label,
    required this.count,
    required this.color,
    required this.index,
  });

  final String label;
  final int count;
  final Color color;
  final int index;
}
