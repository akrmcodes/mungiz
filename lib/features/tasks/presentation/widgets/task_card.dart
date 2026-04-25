/// Premium task card widget — glassmorphic design with micro-animations.
///
/// Displays a single task with:
///   - Animated completion checkmark with scale + colour transition.
///   - Title with animated strikethrough on completion.
///   - Colour-coded due date badge (overdue / today / upcoming).
///   - Assignment indicator badges (assigned-to / assigned-by).
///   - Subtle gradient overlay and premium shadow system.
///   - `flutter_animate` entrance animations.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:mungiz/core/database/app_database.dart';
import 'package:mungiz/core/theme/app_spacing.dart';

/// A premium, glassmorphic task card with rich micro-animations.
const Object _taskSlidableGroupTag = 'task-card-slidables';

/// A premium, glassmorphic task card with rich micro-animations.
class TaskCard extends StatefulWidget {
  /// Creates a [TaskCard].
  const TaskCard({
    required this.task,
    required this.onToggleComplete,
    required this.onEdit,
    required this.onDelete,
    required this.currentUserId,
    this.assigneeName,
    this.creatorName,
    super.key,
  });

  /// The Drift task entry to display.
  final TaskEntry task;

  /// Called when the user taps the completion checkbox.
  final VoidCallback onToggleComplete;

  /// Called when the user chooses to edit the task.
  final Future<void> Function() onEdit;

  /// Called after the user confirms deletion.
  final Future<void> Function() onDelete;

  /// The ID of the currently authenticated user.
  final String currentUserId;

  /// Display name or email of the user this task is assigned to.
  /// Used when the task is assigned to someone other than the creator.
  final String? assigneeName;

  /// Display name or email of the user who created this task.
  /// Used when the task was assigned to the current user by someone else.
  final String? creatorName;

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> with TickerProviderStateMixin {
  late final AnimationController _checkController;
  late final Animation<double> _checkScale;
  late final Animation<double> _checkOpacity;
  late final SlidableController _slidableController;
  bool _revealedHapticSent = false;

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
    _slidableController = SlidableController(this);
    _slidableController.animation.addListener(_handleSlidableProgressChanged);

    if (widget.task.isCompleted) {
      _checkController.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant TaskCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.task.isCompleted != oldWidget.task.isCompleted) {
      if (widget.task.isCompleted) {
        unawaited(_checkController.forward());
      } else {
        unawaited(_checkController.reverse());
      }
    }
  }

  @override
  void dispose() {
    _slidableController.animation.removeListener(
      _handleSlidableProgressChanged,
    );
    _slidableController.dispose();
    _checkController.dispose();
    super.dispose();
  }

  void _handleTap() {
    unawaited(HapticFeedback.lightImpact());
    widget.onToggleComplete();
  }

  void _handleSlidableProgressChanged() {
    final revealRatio = _slidableController.ratio.abs();
    if (revealRatio >= 0.45 && !_revealedHapticSent) {
      _revealedHapticSent = true;
      unawaited(HapticFeedback.lightImpact());
      return;
    }

    if (revealRatio <= 0.15) {
      _revealedHapticSent = false;
    }
  }

  Future<void> _closeSlidable() async {
    await _slidableController.close(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _handleEditRequested() async {
    await _closeSlidable();
    if (!mounted) return;
    await widget.onEdit();
  }

  Future<void> _handleDeleteRequested() async {
    await _closeSlidable();
    if (!mounted) return;

    final shouldDelete = await _showDeleteConfirmation();
    if (!shouldDelete || !mounted) return;

    await HapticFeedback.mediumImpact();
    await widget.onDelete();
  }

  Future<void> _showActionsSheet() async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    unawaited(HapticFeedback.lightImpact());

    final action = await showModalBottomSheet<_TaskCardMenuAction>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: colorScheme.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.sheetRadius),
        ),
      ),
      showDragHandle: true,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _TaskCardMenuSheetTile(
                icon: Icons.edit_rounded,
                title: 'تعديل المهمة',
                subtitle: 'حدّث العنوان أو الوصف أو التاريخ',
                foregroundColor: colorScheme.primary,
                backgroundColor: colorScheme.primaryContainer.withValues(
                  alpha: isDark ? 0.26 : 0.5,
                ),
                borderColor: colorScheme.primary.withValues(alpha: 0.16),
                onTap: () => Navigator.of(sheetContext).pop(
                  _TaskCardMenuAction.edit,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _TaskCardMenuSheetTile(
                icon: Icons.delete_outline_rounded,
                title: 'حذف المهمة',
                subtitle: 'سيُطلب منك التأكيد قبل الحذف',
                foregroundColor: colorScheme.error,
                backgroundColor: colorScheme.errorContainer.withValues(
                  alpha: isDark ? 0.24 : 0.45,
                ),
                borderColor: colorScheme.error.withValues(alpha: 0.16),
                onTap: () => Navigator.of(sheetContext).pop(
                  _TaskCardMenuAction.delete,
                ),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || action == null) return;

    switch (action) {
      case _TaskCardMenuAction.edit:
        await _handleEditRequested();
      case _TaskCardMenuAction.delete:
        await _handleDeleteRequested();
    }
  }

  Future<bool> _showDeleteConfirmation() async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog.adaptive(
          title: const Text('حذف المهمة'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('هل أنت متأكد من حذف هذه المهمة؟'),
              const SizedBox(height: AppSpacing.sm),
              Text(
                widget.task.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.error,
              ),
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );

    return confirmed ?? false;
  }

  /// Determines the assignment relationship for this task.
  _AssignmentType get _assignmentType {
    final task = widget.task;
    final uid = widget.currentUserId;

    if (task.createdBy == uid && task.assignedTo != uid) {
      return _AssignmentType.assignedToOther;
    }
    if (task.assignedTo == uid && task.createdBy != uid) {
      return _AssignmentType.assignedToMe;
    }
    return _AssignmentType.personal;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isCompleted = widget.task.isCompleted;
    final assignment = _assignmentType;

    return Slidable(
      controller: _slidableController,
      groupTag: _taskSlidableGroupTag,
      startActionPane: ActionPane(
        motion: const StretchMotion(),
        extentRatio: 0.24,
        children: [
          SlidableAction(
            onPressed: (_) => unawaited(_handleEditRequested()),
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            icon: Icons.edit_rounded,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const StretchMotion(),
        extentRatio: 0.24,
        children: [
          SlidableAction(
            onPressed: (_) => unawaited(_handleDeleteRequested()),
            backgroundColor: colorScheme.error,
            foregroundColor: colorScheme.onError,
            icon: Icons.delete_outline_rounded,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          ),
        ],
      ),
      child: Container(
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
                    colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                    colorScheme.surfaceContainerHigh.withValues(alpha: 0.4),
                  ]
                : [
                    (isDark
                            ? colorScheme.surfaceContainerHigh
                            : colorScheme.surface)
                        .withValues(alpha: 0.95),
                    (isDark
                            ? colorScheme.surfaceContainerHighest
                            : colorScheme.surfaceContainerLowest)
                        .withValues(alpha: 0.85),
                  ],
          ),
          border: Border.all(
            color: isCompleted
                ? colorScheme.outlineVariant.withValues(alpha: 0.3)
                : colorScheme.outlineVariant.withValues(alpha: 0.15),
          ),
          boxShadow: isCompleted
              ? []
              : [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.04),
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
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(
                  AppSpacing.cardRadius,
                ),
                onTap: _handleTap,
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    AppSpacing.cardPadding,
                    AppSpacing.cardPadding,
                    AppSpacing.cardPadding + 44,
                    AppSpacing.cardPadding,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title
                            AnimatedDefaultTextStyle(
                              duration: const Duration(
                                milliseconds: 300,
                              ),
                              style: theme.textTheme.titleMedium!.copyWith(
                                color: isCompleted
                                    ? colorScheme.onSurfaceVariant.withValues(
                                        alpha: 0.5,
                                      )
                                    : colorScheme.onSurface,
                                decoration: isCompleted
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                                decorationColor: colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.4),
                              ),
                              child: Text(
                                widget.task.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                            // Description
                            if (widget.task.description != null &&
                                widget.task.description!.isNotEmpty) ...[
                              const SizedBox(
                                height: AppSpacing.xs,
                              ),
                              Text(
                                widget.task.description!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant
                                      .withValues(
                                        alpha: isCompleted ? 0.4 : 0.7,
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

                            // ── Assignment badge ──────────
                            // Only renders once the name has resolved from the
                            // profile repository. While resolveProfile() is
                            // in-flight the badge is hidden (SizedBox.shrink),
                            // then animates in via fadeIn+scale once state
                            // updates with the real email/display-name string.
                            if (assignment != _AssignmentType.personal) ...[
                              Builder(
                                builder: (_) {
                                  final resolvedName =
                                      assignment ==
                                          _AssignmentType.assignedToOther
                                      ? widget.assigneeName
                                      : widget.creatorName;
                                  if (resolvedName == null) {
                                    return const SizedBox.shrink();
                                  }
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(
                                        height: AppSpacing.sm,
                                      ),
                                      _AssignmentBadge(
                                        type: assignment,
                                        name: resolvedName,
                                        colorScheme: colorScheme,
                                        textTheme: theme.textTheme,
                                        isDark: isDark,
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              PositionedDirectional(
                end: AppSpacing.xs,
                top: AppSpacing.xs,
                child: _TaskCardMenuButton(
                  onPressed: _showActionsSheet,
                  colorScheme: colorScheme,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _TaskCardMenuAction {
  edit,
  delete,
}

class _TaskCardMenuButton extends StatelessWidget {
  const _TaskCardMenuButton({
    required this.onPressed,
    required this.colorScheme,
  });

  final VoidCallback onPressed;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.88),
      shape: const CircleBorder(),
      child: IconButton(
        onPressed: onPressed,
        tooltip: 'المزيد',
        icon: const Icon(Icons.more_vert),
        iconSize: 20,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(
          width: 36,
          height: 36,
        ),
      ),
    );
  }
}

class _TaskCardMenuSheetTile extends StatelessWidget {
  const _TaskCardMenuSheetTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color foregroundColor;
  final Color backgroundColor;
  final Color borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: foregroundColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: foregroundColor),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Assignment types
// ─────────────────────────────────────────────────────────────────────────

enum _AssignmentType {
  /// The task is a personal task (creator == assignee).
  personal,

  /// The current user created the task and assigned it to someone else.
  assignedToOther,

  /// Someone else created the task and assigned it to the current user.
  assignedToMe,
}

// ─────────────────────────────────────────────────────────────────────────
// Assignment badge — glassmorphic chip
// ─────────────────────────────────────────────────────────────────────────

class _AssignmentBadge extends StatelessWidget {
  const _AssignmentBadge({
    required this.type,
    required this.name,
    required this.colorScheme,
    required this.textTheme,
    required this.isDark,
  });

  final _AssignmentType type;
  final String name;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final isToOther = type == _AssignmentType.assignedToOther;

    final badgeColor = isToOther
        ? colorScheme.tertiaryContainer.withValues(alpha: isDark ? 0.4 : 0.5)
        : colorScheme.secondaryContainer.withValues(alpha: isDark ? 0.4 : 0.5);

    final textColor = isToOther
        ? colorScheme.onTertiaryContainer
        : colorScheme.onSecondaryContainer;

    final icon = isToOther
        ? Icons.arrow_back_rounded
        : Icons.arrow_forward_rounded;

    final displayName = _makeBreakableProfileName(name);
    final label = isToOther
        ? 'مسندة إلى: $displayName'
        : 'بواسطة: $displayName';

    return Container(
          // Let the badge grow to fill available width so the label
          // always has the full card width to render into.
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm + 2,
            vertical: AppSpacing.xs + 2,
          ),
          decoration: BoxDecoration(
            color: badgeColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: (isToOther ? colorScheme.tertiary : colorScheme.secondary)
                  .withValues(alpha: 0.2),
            ),
          ),
          // Wrap keeps icon + label on one line when there is room,
          // and wraps the label to the next line for long email addresses.
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 2,
            children: [
              Icon(icon, size: 14, color: textColor),
              Text(
                label,
                style: textTheme.labelSmall?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
                softWrap: true,
                overflow: TextOverflow.visible,
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
}

String _makeBreakableProfileName(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty || !trimmed.contains('@')) {
    return trimmed;
  }

  return trimmed
      .replaceAll('@', '@\u200B')
      .replaceAll('.', '.\u200B')
      .replaceAll('_', '_\u200B');
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
        color: isCompleted ? colorScheme.primary : Colors.transparent,
        border: Border.all(
          color: isCompleted ? colorScheme.primary : colorScheme.outlineVariant,
          width: 2,
        ),
        boxShadow: isCompleted
            ? [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.3),
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
      textColor = colorScheme.onSurfaceVariant.withValues(alpha: 0.5);
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
      badgeColor = colorScheme.primaryContainer.withValues(alpha: 0.5);
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
