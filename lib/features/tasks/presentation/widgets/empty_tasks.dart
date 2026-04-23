/// Elegant empty state widget for the task list.
///
/// Displayed when the user has zero tasks. Features a large animated
/// icon, motivational Arabic text, and a prominent CTA button to
/// create the first task.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mungiz/core/theme/app_spacing.dart';

/// A polished, animated empty state for the task list.
class EmptyTasks extends StatelessWidget {
  /// Creates an [EmptyTasks] widget.
  const EmptyTasks({required this.onCreateTask, super.key});

  /// Called when the user taps the CTA button.
  final VoidCallback onCreateTask;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Animated illustration ────────────────────
            _FloatingIcon(colorScheme: colorScheme),
            const SizedBox(height: AppSpacing.xl),

            // ── Headline ─────────────────────────────────
            Text(
              'لا توجد مهام بعد',
              textAlign: TextAlign.center,
              style:
                  theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            )
                .animate()
                .fadeIn(delay: 400.ms, duration: 500.ms)
                .slideY(
                  begin: 0.15,
                  delay: 400.ms,
                  duration: 500.ms,
                ),
            const SizedBox(height: AppSpacing.sm),

            // ── Subtitle ─────────────────────────────────
            Text(
              'ابدأ بإضافة مهمتك الأولى\nوتابع إنجازاتك بسهولة',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant
                    .withValues(alpha: 0.7),
                height: 1.8,
              ),
            )
                .animate()
                .fadeIn(delay: 550.ms, duration: 500.ms)
                .slideY(
                  begin: 0.15,
                  delay: 550.ms,
                  duration: 500.ms,
                ),
            const SizedBox(height: AppSpacing.xl),

            // ── CTA Button ───────────────────────────────
            FilledButton.icon(
              onPressed: onCreateTask,
              icon: const Icon(Icons.add_rounded),
              label: const Text('إنشاء مهمة جديدة'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppSpacing.buttonRadius,
                  ),
                ),
              ),
            )
                .animate()
                .fadeIn(delay: 700.ms, duration: 500.ms)
                .slideY(
                  begin: 0.2,
                  delay: 700.ms,
                  duration: 500.ms,
                  curve: Curves.easeOutCubic,
                ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Floating animated icon
// ─────────────────────────────────────────────────────────────────────────

class _FloatingIcon extends StatelessWidget {
  const _FloatingIcon({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer glow ring
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                colorScheme.primary
                    .withValues(alpha: 0.08),
                colorScheme.primary
                    .withValues(alpha: 0),
              ],
            ),
          ),
        )
            .animate(
              onPlay: (c) => c.repeat(reverse: true),
            )
            .scale(
              begin: const Offset(0.9, 0.9),
              end: const Offset(1.1, 1.1),
              duration: 2000.ms,
              curve: Curves.easeInOut,
            ),

        // Inner circle
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primaryContainer,
                colorScheme.primary
                    .withValues(alpha: 0.3),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary
                    .withValues(alpha: 0.2),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            Icons.checklist_rounded,
            size: 48,
            color: colorScheme.onPrimaryContainer,
          ),
        )
            .animate()
            .fadeIn(duration: 600.ms)
            .scale(
              begin: const Offset(0.5, 0.5),
              duration: 600.ms,
              curve: Curves.easeOutBack,
            )
            .then()
            .animate(
              onPlay: (c) => c.repeat(reverse: true),
            )
            .moveY(
              begin: -4,
              end: 4,
              duration: 2500.ms,
              curve: Curves.easeInOut,
            ),

        // Decorative dot — top right
        Positioned(
          top: 10,
          right: 20,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.tertiary
                  .withValues(alpha: 0.5),
            ),
          )
              .animate(
                onPlay: (c) => c.repeat(reverse: true),
              )
              .moveY(
                begin: -6,
                end: 6,
                duration: 1800.ms,
                delay: 300.ms,
                curve: Curves.easeInOut,
              )
              .fadeIn(duration: 800.ms),
        ),

        // Decorative dot — bottom left
        Positioned(
          bottom: 15,
          left: 15,
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.secondary
                  .withValues(alpha: 0.4),
            ),
          )
              .animate(
                onPlay: (c) => c.repeat(reverse: true),
              )
              .moveY(
                begin: 5,
                end: -5,
                duration: 2200.ms,
                delay: 500.ms,
                curve: Curves.easeInOut,
              )
              .fadeIn(duration: 800.ms, delay: 200.ms),
        ),
      ],
    );
  }
}
