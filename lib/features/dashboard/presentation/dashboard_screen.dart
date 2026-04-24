/// Dashboard screen — visual analytics for the Mungiz app.
///
/// Displays an RTL-first, Arabic-language analytics overview with:
///   - A hero header with greeting and date.
///   - Four animated [StatCard] KPI widgets in a responsive 2×2 grid.
///   - An animated [ProgressRing] showing the overall completion rate.
///   - Staggered entrance animations via `flutter_animate`.
///
/// Data is sourced from [dashboardStatsProvider] which watches the
/// local Drift database — fully offline-compatible.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mungiz/core/theme/app_spacing.dart';
import 'package:mungiz/features/dashboard/domain/task_stats.dart';
import 'package:mungiz/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:mungiz/features/dashboard/presentation/widgets/progress_ring.dart';
import 'package:mungiz/features/dashboard/presentation/widgets/stat_card.dart';
import 'package:mungiz/features/dashboard/presentation/widgets/status_donut_chart.dart';
import 'package:mungiz/features/dashboard/presentation/widgets/weekly_bar_chart.dart';

/// The Dashboard / Analytics screen.
class DashboardScreen extends ConsumerWidget {
  /// Creates a [DashboardScreen].
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      // Transparent app bar — we build a custom hero header below.
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Hero Header ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _DashboardHeader(
              isDark: isDark,
              colorScheme: colorScheme,
              theme: theme,
            ),
          ),

          // ── Body ─────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPaddingH,
            ),
            sliver: SliverToBoxAdapter(
              child: statsAsync.when(
                data: (stats) => _DashboardContent(
                  stats: stats,
                  colorScheme: colorScheme,
                  theme: theme,
                  isDark: isDark,
                ),
                loading: () => _DashboardSkeleton(
                  colorScheme: colorScheme,
                ),
                error: (e, _) => _DashboardError(error: e),
              ),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Hero header
// ─────────────────────────────────────────────────────────────────────────

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.isDark,
    required this.colorScheme,
    required this.theme,
  });

  final bool isDark;
  final ColorScheme colorScheme;
  final ThemeData theme;

  String _arabicDate() {
    final now = DateTime.now();
    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  colorScheme.primaryContainer
                      .withValues(alpha: 0.35),
                  colorScheme.surface,
                ]
              : [
                  colorScheme.primaryContainer
                      .withValues(alpha: 0.55),
                  colorScheme.surfaceContainerLowest,
                ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPaddingH,
            AppSpacing.lg,
            AppSpacing.screenPaddingH,
            AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date chip
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm + 2,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 12,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _arabicDate(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideX(begin: 0.05, duration: 400.ms),

              const SizedBox(height: AppSpacing.md),

              // Title
              Text(
                'لوحة التحكم',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                  height: 1.1,
                ),
              )
                  .animate()
                  .fadeIn(delay: 80.ms, duration: 400.ms)
                  .slideY(
                    begin: 0.06,
                    delay: 80.ms,
                    duration: 400.ms,
                  ),

              const SizedBox(height: AppSpacing.xs),

              // Subtitle
              Text(
                'نظرة شاملة على مهامك ومستوى إنجازك',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              )
                  .animate()
                  .fadeIn(delay: 140.ms, duration: 400.ms)
                  .slideY(
                    begin: 0.06,
                    delay: 140.ms,
                    duration: 400.ms,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Main content
// ─────────────────────────────────────────────────────────────────────────

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.stats,
    required this.colorScheme,
    required this.theme,
    required this.isDark,
  });

  final TaskStats stats;
  final ColorScheme colorScheme;
  final ThemeData theme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.lg),

        // ── KPI Cards ───────────────────────────────────────────
        _SectionHeader(
          label: 'ملخص المهام',
          icon: Icons.dashboard_rounded,
          theme: theme,
          colorScheme: colorScheme,
          delay: 200.ms,
        ),

        const SizedBox(height: AppSpacing.md),

        // 2 × 2 grid of stat cards
        _StatGrid(
          stats: stats,
          isDark: isDark,
          colorScheme: colorScheme,
        ),

        const SizedBox(height: AppSpacing.xl),

        // ── Progress Section ─────────────────────────────────────
        _SectionHeader(
          label: 'معدل الإنجاز',
          icon: Icons.pie_chart_rounded,
          theme: theme,
          colorScheme: colorScheme,
          delay: 350.ms,
        ),

        const SizedBox(height: AppSpacing.lg),

        _ProgressSection(
          stats: stats,
          colorScheme: colorScheme,
          theme: theme,
          isDark: isDark,
        ),

        const SizedBox(height: AppSpacing.xl),

        // ── Weekly Bar Chart ──────────────────────────────────────
        _SectionHeader(
          label: 'الإنجاز الأسبوعي',
          icon: Icons.bar_chart_rounded,
          theme: theme,
          colorScheme: colorScheme,
          delay: 520.ms,
        ),

        const SizedBox(height: AppSpacing.lg),

        WeeklyBarChart(
          weeklyCompletions: stats.weeklyCompletions,
          animationDelay: 580.ms,
        ),

        const SizedBox(height: AppSpacing.xl),

        // ── Status Donut Chart ────────────────────────────────────
        _SectionHeader(
          label: 'توزيع المهام',
          icon: Icons.donut_large_rounded,
          theme: theme,
          colorScheme: colorScheme,
          delay: 680.ms,
        ),

        const SizedBox(height: AppSpacing.lg),

        StatusDonutChart(
          completed: stats.completed,
          pending: stats.pending,
          overdue: stats.overdueCount,
          animationDelay: 740.ms,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Section header
// ─────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.label,
    required this.icon,
    required this.theme,
    required this.colorScheme,
    this.delay = Duration.zero,
  });

  final String label;
  final IconData icon;
  final ThemeData theme;
  final ColorScheme colorScheme;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: colorScheme.primary),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(delay: delay, duration: 400.ms)
        .slideX(
          begin: 0.05,
          delay: delay,
          duration: 400.ms,
        );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Stat grid — 2 × 2 responsive layout
// ─────────────────────────────────────────────────────────────────────────

class _StatGrid extends StatelessWidget {
  const _StatGrid({
    required this.stats,
    required this.isDark,
    required this.colorScheme,
  });

  final TaskStats stats;
  final bool isDark;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    // Card definitions — colour palette hand-picked for harmony.
    final cards = <_CardDef>[
      _CardDef(
        label: 'إجمالي المهام',
        value: stats.totalTasks,
        icon: Icons.checklist_rounded,
        accent: colorScheme.primary,
        gradient: [
          colorScheme.primaryContainer.withValues(
            alpha: isDark ? 0.35 : 0.5,
          ),
          colorScheme.surface,
        ],
        delay: 250.ms,
      ),
      _CardDef(
        label: 'مكتملة',
        value: stats.completed,
        icon: Icons.check_circle_rounded,
        accent: const Color(0xFF27AE60),
        gradient: [
          const Color(0xFF27AE60).withValues(
            alpha: isDark ? 0.18 : 0.12,
          ),
          colorScheme.surface,
        ],
        delay: 330.ms,
      ),
      _CardDef(
        label: 'قيد التنفيذ',
        value: stats.pending,
        icon: Icons.pending_actions_rounded,
        accent: const Color(0xFFF39C12),
        gradient: [
          const Color(0xFFF39C12).withValues(
            alpha: isDark ? 0.18 : 0.12,
          ),
          colorScheme.surface,
        ],
        delay: 410.ms,
      ),
      _CardDef(
        label: 'متأخرة',
        value: stats.overdueCount,
        icon: Icons.warning_amber_rounded,
        accent: colorScheme.error,
        gradient: [
          colorScheme.errorContainer.withValues(
            alpha: isDark ? 0.35 : 0.45,
          ),
          colorScheme.surface,
        ],
        delay: 490.ms,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth =
            (constraints.maxWidth - AppSpacing.md) / 2;
        const cardHeight = 148.0;

        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: cards.map((def) {
            return SizedBox(
              width: cardWidth,
              height: cardHeight,
              child: StatCard(
                label: def.label,
                value: def.value,
                icon: def.icon,
                accentColor: def.accent,
                gradientColors: def.gradient,
                animationDelay: def.delay,
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

/// Internal card definition data class.
class _CardDef {
  const _CardDef({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    required this.gradient,
    required this.delay,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color accent;
  final List<Color> gradient;
  final Duration delay;
}

// ─────────────────────────────────────────────────────────────────────────
// Progress section
// ─────────────────────────────────────────────────────────────────────────

class _ProgressSection extends StatelessWidget {
  const _ProgressSection({
    required this.stats,
    required this.colorScheme,
    required this.theme,
    required this.isDark,
  });

  final TaskStats stats;
  final ColorScheme colorScheme;
  final ThemeData theme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: isDark
              ? [
                  colorScheme.surfaceContainerHigh
                      .withValues(alpha: 0.9),
                  colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.7),
                ]
              : [
                  colorScheme.surface,
                  colorScheme.surfaceContainerLowest,
                ],
        ),
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
      child: Row(
        children: [
          // Progress ring — centred
          Expanded(
            flex: 2,
            child: Center(
              child: ProgressRing(
                completionRate: stats.completionRate,
                label: 'معدل إتمام المهام',
                animationDelay: 400.ms,
              ),
            ),
          ),

          const SizedBox(width: AppSpacing.lg),

          // Legend + detail column
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تفاصيل الإنجاز',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _LegendRow(
                  color: const Color(0xFF27AE60),
                  label: 'مكتملة',
                  value: stats.completed,
                  total: stats.totalTasks,
                  theme: theme,
                  delay: 500.ms,
                ),
                const SizedBox(height: AppSpacing.sm),
                _LegendRow(
                  color: const Color(0xFFF39C12),
                  label: 'قيد التنفيذ',
                  value: stats.pending,
                  total: stats.totalTasks,
                  theme: theme,
                  delay: 580.ms,
                ),
                const SizedBox(height: AppSpacing.sm),
                _LegendRow(
                  color: colorScheme.error,
                  label: 'متأخرة',
                  value: stats.overdueCount,
                  total: stats.totalTasks,
                  theme: theme,
                  delay: 660.ms,
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 450.ms, duration: 500.ms)
        .slideY(
          begin: 0.08,
          delay: 450.ms,
          duration: 500.ms,
          curve: Curves.easeOutCubic,
        );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Legend row
// ─────────────────────────────────────────────────────────────────────────

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.label,
    required this.value,
    required this.total,
    required this.theme,
    this.delay = Duration.zero,
  });

  final Color color;
  final String label;
  final int value;
  final int total;
  final ThemeData theme;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (value / total * 100).round() : 0;

    return Row(
      children: [
        // Colour dot
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          '$value ($pct%)',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w700,
            fontFamily: 'Inter',
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(delay: delay, duration: 350.ms)
        .slideX(
          begin: 0.06,
          delay: delay,
          duration: 350.ms,
        );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Loading skeleton
// ─────────────────────────────────────────────────────────────────────────

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final shimmerColor =
        colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);

    return Column(
      children: [
        const SizedBox(height: AppSpacing.lg),
        // 4 card placeholders in 2×2
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: List.generate(4, (i) {
            return Container(
              width: (MediaQuery.sizeOf(context).width -
                      AppSpacing.screenPaddingH * 2 -
                      AppSpacing.md) /
                  2,
              height: 148,
              decoration: BoxDecoration(
                color: shimmerColor,
                borderRadius:
                    BorderRadius.circular(AppSpacing.cardRadius),
              ),
            )
                .animate(onPlay: (c) => c.repeat())
                .shimmer(
                  duration: 1200.ms,
                  delay: Duration(milliseconds: i * 120),
                  color: colorScheme.surfaceContainerHigh
                      .withValues(alpha: 0.6),
                );
          }),
        ),
        const SizedBox(height: AppSpacing.xl),
        // Ring placeholder
        Container(
          height: 220,
          decoration: BoxDecoration(
            color: shimmerColor,
            borderRadius:
                BorderRadius.circular(AppSpacing.cardRadius),
          ),
        )
            .animate(onPlay: (c) => c.repeat())
            .shimmer(
              duration: 1200.ms,
              delay: 480.ms,
              color: colorScheme.surfaceContainerHigh
                  .withValues(alpha: 0.6),
            ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Error state
// ─────────────────────────────────────────────────────────────────────────

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: Column(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'تعذّر تحميل الإحصائيات',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '$error',
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
