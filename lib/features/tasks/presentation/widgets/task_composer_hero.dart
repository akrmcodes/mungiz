/// Shared hero surface for the task composer entry point.
///
/// This wraps the task creation CTA on the task list and the matching
/// header on the create screen so the transition reads as one continuous
/// object instead of two unrelated widgets.
library;

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mungiz/core/theme/app_spacing.dart';

/// Shared tag for the task composer hero.
const String taskComposerHeroTag = 'task-composer-hero';

/// Hero wrapper for the task composer entry point.
class TaskComposerHero extends StatelessWidget {
  /// Creates a [TaskComposerHero].
  const TaskComposerHero({required this.child, super.key});

  /// The hero child to display on the current route.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: taskComposerHeroTag,
      createRectTween: (begin, end) => MaterialRectArcTween(
        begin: begin,
        end: end,
      ),
      flightShuttleBuilder: _buildFlightShuttle,
      child: child,
    );
  }
}

Widget _buildFlightShuttle(
  BuildContext flightContext,
  Animation<double> animation,
  HeroFlightDirection flightDirection,
  BuildContext fromHeroContext,
  BuildContext toHeroContext,
) {
  final colorScheme = Theme.of(flightContext).colorScheme;
  final textTheme = Theme.of(flightContext).textTheme;
  final curvedAnimation = CurvedAnimation(
    parent: animation,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeOutCubic,
  );

  return AnimatedBuilder(
    animation: curvedAnimation,
    builder: (context, child) {
      final progress = flightDirection == HeroFlightDirection.push
          ? curvedAnimation.value
          : 1 - curvedAnimation.value;

      return _TaskComposerHeroFlight(
        progress: progress,
        colorScheme: colorScheme,
        textTheme: textTheme,
      );
    },
  );
}

class TaskComposerHeroHeader extends StatelessWidget {
  /// Creates the destination header shown on the create screen.
  const TaskComposerHeroHeader({
    this.title = 'مهمة جديدة',
    this.subtitle = 'ابدأ بعنوان واضح، ثم أضف التفاصيل عندما تحتاجها.',
    super.key,
  });

  /// The heading displayed in the hero surface.
  final String title;

  /// The supporting subtitle displayed below the heading.
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surfaceContainerLowest,
      elevation: 1,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          AppSpacing.sheetRadius,
        ),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            _HeroGlyph(
              colorScheme: colorScheme,
              iconColor: colorScheme.onPrimary,
              size: 48,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskComposerHeroFlight extends StatelessWidget {
  const _TaskComposerHeroFlight({
    required this.progress,
    required this.colorScheme,
    required this.textTheme,
  });

  final double progress;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final cardProgress = Curves.easeOutCubic.transform(
      progress.clamp(0.0, 1.0),
    );

    final backgroundColor = Color.lerp(
      colorScheme.primary,
      colorScheme.surfaceContainerLowest,
      cardProgress,
    )!;
    final foregroundColor = Color.lerp(
      colorScheme.onPrimary,
      colorScheme.onSurface,
      cardProgress,
    )!;
    final borderRadius = BorderRadius.lerp(
      BorderRadius.circular(AppSpacing.cardRadius),
      BorderRadius.circular(AppSpacing.sheetRadius),
      cardProgress,
    )!;

    return Material(
      color: backgroundColor,
      elevation: lerpDouble(9, 1, cardProgress)!,
      shadowColor: colorScheme.shadow.withValues(
        alpha: lerpDouble(0.22, 0.08, cardProgress),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: BorderSide(
          color: Color.lerp(
            colorScheme.primary.withValues(alpha: 0),
            colorScheme.outlineVariant.withValues(alpha: 0.45),
            cardProgress,
          )!,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final shouldSimplify =
              constraints.maxWidth < 228 || constraints.maxHeight < 88;
          final glyphSize = lerpDouble(
            28,
            48,
            cardProgress,
          )!;

          return ClipRect(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: shouldSimplify ? AppSpacing.sm : AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              child: shouldSimplify
                  ? Center(
                      child: _HeroGlyph(
                        colorScheme: colorScheme,
                        iconColor: foregroundColor,
                        size: glyphSize,
                      ),
                    )
                  : Row(
                      children: [
                        _HeroGlyph(
                          colorScheme: colorScheme,
                          iconColor: foregroundColor,
                          size: glyphSize,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'مهمة جديدة',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.titleMedium?.copyWith(
                                  color: foregroundColor,
                                  fontWeight: FontWeight.w700,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'ابدأ بعنوان واضح ثم أضف التفاصيل.',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.bodySmall?.copyWith(
                                  color: Color.lerp(
                                    foregroundColor,
                                    colorScheme.onSurfaceVariant,
                                    0.16,
                                  ),
                                  height: 1.25,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }
}

class _HeroGlyph extends StatelessWidget {
  const _HeroGlyph({
    required this.colorScheme,
    required this.iconColor,
    required this.size,
  });

  final ColorScheme colorScheme;
  final Color iconColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Color.lerp(
          colorScheme.onPrimary.withValues(alpha: 0.12),
          colorScheme.primaryContainer,
          0.72,
        ),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.08),
        ),
      ),
      child: Icon(
        Icons.add_rounded,
        color: iconColor,
        size: size * 0.48,
      ),
    );
  }
}
