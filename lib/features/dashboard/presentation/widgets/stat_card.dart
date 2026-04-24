/// Animated stat card for the Dashboard feature.
///
/// Displays a single numeric KPI with:
///   - Animated roll-up counter via [TweenAnimationBuilder].
///   - Gradient background with glassmorphic layering.
///   - Icon with a softly glowing tinted container.
///   - Subtle bottom accent line matching the card's accent colour.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mungiz/core/theme/app_spacing.dart';

/// A premium, animated KPI card for the dashboard.
///
/// The numeric [value] animates from 0 to the target number using
/// [TweenAnimationBuilder] whenever the widget is first built or
/// the value changes.
class StatCard extends StatelessWidget {
  /// Creates a [StatCard].
  const StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
    required this.gradientColors,
    this.animationDelay = Duration.zero,
    super.key,
  });

  /// Arabic label shown below the number.
  final String label;

  /// The numeric value to display (animated from 0).
  final int value;

  /// Icon representing the stat category.
  final IconData icon;

  /// Accent colour used for the icon container and bottom bar.
  final Color accentColor;

  /// Gradient applied to the card background [start, end].
  final List<Color> gradientColors;

  /// Optional delay for the entrance animation.
  final Duration animationDelay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: gradientColors,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: isDark ? 0.15 : 0.18),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: accentColor.withValues(alpha: isDark ? 0.25 : 0.12),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: Stack(
          children: [
            // ── Decorative background glow ──────────────────────
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor.withValues(
                    alpha: isDark ? 0.08 : 0.06,
                  ),
                ),
              ),
            ),

            // ── Main content ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Icon container
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(
                        alpha: isDark ? 0.2 : 0.14,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      size: 20,
                      color: accentColor,
                    ),
                  ),

                  const Spacer(),

                  // Animated number
                  TweenAnimationBuilder<int>(
                    tween: IntTween(begin: 0, end: value),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (_, animatedValue, child) {
                      return Text(
                        '$animatedValue',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Inter',
                          color: theme.colorScheme.onSurface,
                          letterSpacing: -0.5,
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: AppSpacing.xs),

                  // Label
                  Text(
                    label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // ── Bottom accent bar ───────────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accentColor.withValues(alpha: 0),
                      accentColor,
                      accentColor.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    )
        .animate(delay: animationDelay)
        .fadeIn(duration: 450.ms, curve: Curves.easeOut)
        .slideY(
          begin: 0.12,
          duration: 450.ms,
          curve: Curves.easeOutCubic,
        )
        .scale(
          begin: const Offset(0.94, 0.94),
          duration: 450.ms,
          curve: Curves.easeOutBack,
        );
  }
}
