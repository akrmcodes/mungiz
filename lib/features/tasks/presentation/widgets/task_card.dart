/// Premium task card widget — glassmorphic design with micro-animations.
///
/// Displays a single task with:
///   - Animated completion checkmark with scale + colour transition.
///   - Title with animated strikethrough on completion.
///   - Colour-coded due date badge (overdue / today / upcoming).
///   - Subtle gradient overlay and premium shadow system.
///   - `flutter_animate` entrance animations.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mungiz/core/database/app_database.dart';
import 'package:mungiz/core/theme/app_spacing.dart';

/// A premium, glassmorphic task card with rich micro-animations.
class TaskCard extends StatefulWidget {
  /// Creates a [TaskCard].
  const TaskCard({
    required this.task,
    required this.onToggleComplete,
    super.key,
  });

  /// The Drift task entry to display.
  final TaskEntry task;

  /// Called when the user taps the completion checkbox.
  final VoidCallback onToggleComplete;

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _checkController;
  late final Animation<double> _checkScale;
  late final Animation<double> _checkOpacity;

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _checkScale = Tween<double>(begin: 0.6, end: 1).animate(
      CurvedAnimation(
        parent: _checkController,
        curve: Curves.elasticOut,
      ),
    );
    _checkOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _checkController,
        curve: const Interval(0, 0.6),
      ),
    );

    if (widget.task.isCompleted) {
      _checkController.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant TaskCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.task.isCompleted !=
        oldWidget.task.isCompleted) {
      if (widget.task.isCompleted) {
        unawaited(_checkController.forward());
      } else {
        unawaited(_checkController.reverse());
      }
    }
  }

  @override
  void dispose() {
    _checkController.dispose();
    super.dispose();
  }

  void _handleTap() {
    unawaited(HapticFeedback.lightImpact());
    widget.onToggleComplete();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark =
        theme.brightness == Brightness.dark;
    final isCompleted = widget.task.isCompleted;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPaddingH,
        vertical: AppSpacing.sm / 2,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          AppSpacing.cardRadius,
        ),
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: isCompleted
              ? [
                  colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.6),
                  colorScheme.surfaceContainerHigh
                      .withValues(alpha: 0.4),
                ]
              : [
                  (isDark
                          ? colorScheme.surfaceContainerHigh
                          : colorScheme.surface)
                      .withValues(alpha: 0.95),
                  (isDark
                          ? colorScheme
                              .surfaceContainerHighest
                          : colorScheme
                              .surfaceContainerLowest)
                      .withValues(alpha: 0.85),
                ],
        ),
        border: Border.all(
          color: isCompleted
              ? colorScheme.outlineVariant
                  .withValues(alpha: 0.3)
              : colorScheme.outlineVariant
                  .withValues(alpha: 0.15),
        ),
        boxShadow: isCompleted
            ? []
            : [
                BoxShadow(
                  color: colorScheme.shadow
                      .withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: colorScheme.primary
                      .withValues(alpha: 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(
          AppSpacing.cardRadius,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(
            AppSpacing.cardRadius,
          ),
          onTap: _handleTap,
          child: Padding(
            padding: const EdgeInsets.all(
              AppSpacing.cardPadding,
            ),
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                // ── Checkbox ──────────────────────
                _AnimatedCheckbox(
                  isCompleted: isCompleted,
                  scaleAnimation: _checkScale,
                  opacityAnimation: _checkOpacity,
                  colorScheme: colorScheme,
                ),
                const SizedBox(width: AppSpacing.md),

                // ── Content ──────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      // Title
                      AnimatedDefaultTextStyle(
                        duration: const Duration(
                          milliseconds: 300,
                        ),
                        style: theme
                            .textTheme.titleMedium!
                            .copyWith(
                          color: isCompleted
                              ? colorScheme
                                  .onSurfaceVariant
                                  .withValues(
                                    alpha: 0.5,
                                  )
                              : colorScheme.onSurface,
                          decoration: isCompleted
                              ? TextDecoration
                                  .lineThrough
                              : TextDecoration.none,
                          decorationColor: colorScheme
                              .onSurfaceVariant
                              .withValues(alpha: 0.4),
                        ),
                        child: Text(
                          widget.task.title,
                          maxLines: 2,
                          overflow:
                              TextOverflow.ellipsis,
                        ),
                      ),

                      // Description
                      if (widget.task.description !=
                              null &&
                          widget.task.description!
                              .isNotEmpty) ...[
                        const SizedBox(
                          height: AppSpacing.xs,
                        ),
                        Text(
                          widget.task.description!,
                          maxLines: 2,
                          overflow:
                              TextOverflow.ellipsis,
                          style: theme
                              .textTheme.bodySmall
                              ?.copyWith(
                            color: colorScheme
                                .onSurfaceVariant
                                .withValues(
                                  alpha: isCompleted
                                      ? 0.4
                                      : 0.7,
                                ),
                          ),
                        ),
                      ],

                      // Due date badge
                      if (widget.task.dueAt != null) ...[
                        const SizedBox(
                          height: AppSpacing.sm,
                        ),
                        _DueDateBadge(
                          dueAt: widget.task.dueAt!,
                          isCompleted: isCompleted,
                          colorScheme: colorScheme,
                          textTheme: theme.textTheme,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Animated checkbox
// ─────────────────────────────────────────────────────────────────────────

class _AnimatedCheckbox extends StatelessWidget {
  const _AnimatedCheckbox({
    required this.isCompleted,
    required this.scaleAnimation,
    required this.opacityAnimation,
    required this.colorScheme,
  });

  final bool isCompleted;
  final Animation<double> scaleAnimation;
  final Animation<double> opacityAnimation;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted
            ? colorScheme.primary
            : Colors.transparent,
        border: Border.all(
          color: isCompleted
              ? colorScheme.primary
              : colorScheme.outlineVariant,
          width: 2,
        ),
        boxShadow: isCompleted
            ? [
                BoxShadow(
                  color: colorScheme.primary
                      .withValues(alpha: 0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
      child: AnimatedBuilder(
        animation: scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: scaleAnimation.value,
            child: Opacity(
              opacity: opacityAnimation.value,
              child: Icon(
                Icons.check_rounded,
                size: 16,
                color: colorScheme.onPrimary,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Due date badge
// ─────────────────────────────────────────────────────────────────────────

class _DueDateBadge extends StatelessWidget {
  const _DueDateBadge({
    required this.dueAt,
    required this.isCompleted,
    required this.colorScheme,
    required this.textTheme,
  });

  final DateTime dueAt;
  final bool isCompleted;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(
      dueAt.year,
      dueAt.month,
      dueAt.day,
    );

    final isOverdue = dueDay.isBefore(today);
    final isToday = dueDay == today;

    Color badgeColor;
    Color textColor;
    IconData icon;
    String label;

    if (isCompleted) {
      badgeColor = colorScheme.surfaceContainerHighest;
      textColor = colorScheme.onSurfaceVariant
          .withValues(alpha: 0.5);
      icon = Icons.event_available_rounded;
      label = _formatDate(dueAt);
    } else if (isOverdue) {
      badgeColor = colorScheme.errorContainer;
      textColor = colorScheme.onErrorContainer;
      icon = Icons.warning_amber_rounded;
      label = 'متأخرة';
    } else if (isToday) {
      badgeColor = const Color(0xFFFFF3E0);
      textColor = const Color(0xFFF57C00);
      icon = Icons.today_rounded;
      label = 'اليوم';
    } else {
      badgeColor = colorScheme.primaryContainer
          .withValues(alpha: 0.5);
      textColor = colorScheme.onPrimaryContainer;
      icon = Icons.schedule_rounded;
      label = _formatDate(dueAt);
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .scale(
          begin: const Offset(0.9, 0.9),
          duration: 300.ms,
        );
  }

  String _formatDate(DateTime date) {
    final months = [
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
    return '${date.day} ${months[date.month - 1]}';
  }
}
