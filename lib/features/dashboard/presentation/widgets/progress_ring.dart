/// Animated circular progress ring for the Dashboard.
///
/// Renders a smooth, animated arc using [CustomPainter] driven by
/// a [TweenAnimationBuilder] that interpolates the completion rate
/// from 0 → target every time the value changes.
///
/// Design features:
///   - Thick track arc with low-opacity accent colour.
///   - Filled progress arc with gradient stroke via [Paint.shader].
///   - Animated percentage label at the centre.
///   - Animated entrance via `flutter_animate`.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mungiz/core/theme/app_spacing.dart';

/// An animated circular progress ring showing [completionRate].
///
/// [completionRate] must be in [0, 1]. The ring animates whenever
/// the value changes.
class ProgressRing extends StatelessWidget {
  /// Creates a [ProgressRing].
  const ProgressRing({
    required this.completionRate,
    required this.label,
    this.size = 160,
    this.strokeWidth = 14,
    this.animationDelay = Duration.zero,
    super.key,
  });

  /// Completion rate in the range [0, 1].
  final double completionRate;

  /// Arabic subtitle shown below the percentage.
  final String label;

  /// Outer diameter of the ring in logical pixels.
  final double size;

  /// Thickness of the progress arc.
  final double strokeWidth;

  /// Optional delay for the staggered entrance animation.
  final Duration animationDelay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final pct = (completionRate.clamp(0, 1) * 100).round();

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: completionRate.clamp(0, 1)),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (context, animated, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Ring ───────────────────────────────────────────
            SizedBox(
              width: size,
              height: size,
              child: CustomPaint(
                painter: _RingPainter(
                  progress: animated,
                  trackColor: colorScheme.outlineVariant
                      .withValues(alpha: 0.3),
                  progressColors: [
                    colorScheme.primary,
                    colorScheme.tertiary,
                  ],
                  strokeWidth: strokeWidth,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Animated percentage text
                      TweenAnimationBuilder<int>(
                        tween: IntTween(begin: 0, end: pct),
                        duration: const Duration(
                          milliseconds: 1200,
                        ),
                        curve: Curves.easeOutCubic,
                        builder: (_, v, child) {
                          return Text(
                            '$v%',
                            style: theme.textTheme.headlineSmall
                                ?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Inter',
                              color: colorScheme.onSurface,
                              letterSpacing: -1,
                            ),
                          );
                        },
                      ),
                      Text(
                        'إنجاز',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            // ── Label ───────────────────────────────────────────
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        );
      },
    )
        .animate(delay: animationDelay)
        .fadeIn(duration: 500.ms, curve: Curves.easeOut)
        .scale(
          begin: const Offset(0.85, 0.85),
          duration: 600.ms,
          curve: Curves.easeOutBack,
        );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Custom painter
// ─────────────────────────────────────────────────────────────────────────

/// Draws the track and progress arcs for the [ProgressRing].
class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColors,
    required this.strokeWidth,
  });

  final double progress;
  final Color trackColor;
  final List<Color> progressColors;
  final double strokeWidth;

  // Full circle starts at the top (−π/2) and sweeps clockwise.
  static const double _startAngle = -math.pi / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // ── Track arc (full circle) ──────────────────────────────
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = trackColor;

    canvas.drawCircle(center, radius, trackPaint);

    // ── Progress arc ────────────────────────────────────────
    if (progress <= 0) return;

    final sweepAngle = 2 * math.pi * progress;

    // Build a gradient shader aligned to the bounding rect.
    final sweepGradient = SweepGradient(
      startAngle: _startAngle,
      endAngle: _startAngle + sweepAngle,
      colors: progressColors,
    );

    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = sweepGradient.createShader(rect);

    canvas.drawArc(
      rect,
      _startAngle,
      sweepAngle,
      false,
      progressPaint,
    );

    // ── Glowing tip dot ──────────────────────────────────────
    if (progress > 0.02) {
      final tipAngle = _startAngle + sweepAngle;
      final tipX = center.dx + radius * math.cos(tipAngle);
      final tipY = center.dy + radius * math.sin(tipAngle);

      final dotPaint = Paint()
        ..color = progressColors.last
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

      canvas.drawCircle(
        Offset(tipX, tipY),
        strokeWidth / 2 + 1,
        dotPaint,
      );

      // Solid dot on top.
      final solidDot = Paint()..color = progressColors.last;
      canvas.drawCircle(
        Offset(tipX, tipY),
        strokeWidth / 2,
        solidDot,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.strokeWidth != strokeWidth;
}
