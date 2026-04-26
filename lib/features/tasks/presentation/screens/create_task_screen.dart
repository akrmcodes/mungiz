/// Create task screen — a premium full-screen form for new tasks.
///
/// Features:
///   - Premium floating-label text fields with Arabic placeholders.
///   - Multi-line description with character counter.
///   - Elegant date picker chip with Arabic locale.
///   - Optional "assign to" email field with async user lookup.
///   - Real-time form validation with Arabic error messages.
///   - Animated submit button with loading state.
///   - Haptic feedback on successful creation.
library;

import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mungiz/core/database/app_database.dart';
import 'package:mungiz/core/theme/app_spacing.dart';
import 'package:mungiz/features/auth/data/auth_repository.dart';
import 'package:mungiz/features/auth/data/profile_repository.dart';
import 'package:mungiz/features/tasks/presentation/providers/task_providers.dart';
import 'package:mungiz/features/tasks/presentation/widgets/task_composer_hero.dart';

/// Full-screen form for creating a new task.
class CreateTaskScreen extends ConsumerStatefulWidget {
  /// Creates a [CreateTaskScreen].
  const CreateTaskScreen({this.existingTask, super.key});

  /// The task being edited, or `null` when creating a new task.
  final TaskEntry? existingTask;

  @override
  ConsumerState<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends ConsumerState<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _assignEmailController = TextEditingController();
  final _titleFocus = FocusNode();
  final _assignEmailFocus = FocusNode();

  DateTime? _selectedDueDate;
  bool _isSubmitting = false;
  bool _isLookingUpUser = false;

  bool get _isEditing => widget.existingTask != null;

  @override
  void initState() {
    super.initState();
    final existingTask = widget.existingTask;
    if (existingTask != null) {
      _titleController.text = existingTask.title;
      _descriptionController.text = existingTask.description ?? '';
      _selectedDueDate = existingTask.dueAt;

      final currentUserId = ref.read(authRepositoryProvider).currentUser?.id;
      if (existingTask.assignedTo != currentUserId) {
        unawaited(_prefillAssigneeEmail(existingTask.assignedTo));
      }
    }

    // Auto-focus the title field after the entrance animation.
    Future.delayed(600.ms, () {
      if (mounted) _titleFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _assignEmailController.dispose();
    _titleFocus.dispose();
    _assignEmailFocus.dispose();
    super.dispose();
  }

  Future<void> _prefillAssigneeEmail(String userId) async {
    final cachedProfile = await ref
        .read(profileRepositoryProvider)
        .getCachedProfile(userId);

    if (!mounted || cachedProfile == null) return;

    final email = cachedProfile.email.trim();
    if (email.isEmpty || _assignEmailController.text.isNotEmpty) return;

    setState(() {
      _assignEmailController.text = email;
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final currentUserId = ref.read(authRepositoryProvider).currentUser?.id;
      String? assignedToId;

      // ── Async email lookup ──────────────────────────────────
      final email = _assignEmailController.text.trim();
      if (email.isNotEmpty) {
        setState(() => _isLookingUpUser = true);
        try {
          final profile = await ref
              .read(profileRepositoryProvider)
              .findUserByEmail(email);
          assignedToId = profile.id;
        } on UserNotFoundException catch (e) {
          if (!mounted) return;
          _showErrorSnackBar(e.message);
          return;
        } on ProfileLookupException catch (e) {
          if (!mounted) return;
          _showErrorSnackBar(e.message);
          return;
        } finally {
          if (mounted) {
            setState(() => _isLookingUpUser = false);
          }
        }
      } else if (_isEditing) {
        assignedToId = widget.existingTask!.assignedTo;
      } else {
        assignedToId = currentUserId;
      }

      if (!_isEditing && currentUserId == null) {
        if (!mounted) return;
        _showErrorSnackBar('تعذر تحديد المستخدم الحالي');
        return;
      }

      final title = _titleController.text.trim();
      final description = _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim();

      if (_isEditing) {
        await ref
            .read(taskActionsProvider)
            .updateTask(
              taskId: widget.existingTask!.id,
              title: title,
              description: description,
              dueAt: _selectedDueDate,
              assignedTo: assignedToId ?? widget.existingTask!.assignedTo,
            );
      } else {
        await ref
            .read(taskActionsProvider)
            .addTask(
              title: title,
              description: description,
              dueAt: _selectedDueDate,
              assignedTo: assignedToId,
            );
      }

      if (!mounted) return;

      await HapticFeedback.mediumImpact();

      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'تم تحديث المهمة بنجاح ✓'
                  : 'تم إنشاء المهمة بنجاح ✓',
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      context.pop();
    } on Object catch (e, st) {
      log(
        _isEditing ? 'Task Update Failed' : 'Task Creation Failed',
        name: 'CreateTaskScreen',
        error: e,
        stackTrace: st,
      );
      if (mounted) {
        _showErrorSnackBar(
          _isEditing ? 'فشل في تحديث المهمة' : 'فشل في إنشاء المهمة',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _isLookingUpUser = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: Theme.of(context).colorScheme.onError,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onError,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppSpacing.inputRadius,
            ),
          ),
          margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPaddingH,
            vertical: AppSpacing.sm,
          ),
        ),
      );
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
      locale: const Locale('ar'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            datePickerTheme: DatePickerThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  AppSpacing.sheetRadius,
                ),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        _selectedDueDate ?? now,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context),
          child: child!,
        );
      },
    );

    if (!mounted) return;

    setState(() {
      _selectedDueDate = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? 9,
        time?.minute ?? 0,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isBusy = _isSubmitting || _isLookingUpUser;

    return Scaffold(
      // ── App bar ─────────────────────────────────────────
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const SizedBox.shrink(),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: _isEditing ? 'إلغاء التعديل' : 'إغلاق',
          onPressed: () => context.pop(),
        ),
      ),

      // ── Body ────────────────────────────────────────────
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPaddingH,
            vertical: AppSpacing.screenPaddingV,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSpacing.maxContentWidth,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TaskComposerHero(
                    child: TaskComposerHeroHeader(
                      title: _isEditing ? 'تعديل المهمة' : 'مهمة جديدة',
                      subtitle: _isEditing
                          ? 'راجع التفاصيل ثم احفظ التغييرات.'
                          : 'ابدأ بعنوان واضح، ثم أضف التفاصيل عندما تحتاجها.',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Title field ─────────────────
                  TextFormField(
                        controller: _titleController,
                        focusNode: _titleFocus,
                        textInputAction: TextInputAction.next,
                        maxLength: 100,
                        decoration: InputDecoration(
                          labelText: 'عنوان المهمة *',
                          hintText: 'مثال: مراجعة التقرير الأسبوعي',
                          prefixIcon: const Icon(
                            Icons.title_rounded,
                          ),
                          counterText: '',
                          filled: true,
                          fillColor: colorScheme.surfaceContainerLowest,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'يرجى إدخال عنوان المهمة';
                          }
                          if (value.trim().length < 2) {
                            return 'العنوان يجب أن يكون حرفين على الأقل';
                          }
                          return null;
                        },
                      )
                      .animate()
                      .fadeIn(
                        delay: 200.ms,
                        duration: 450.ms,
                      )
                      .slideY(
                        begin: 0.08,
                        delay: 200.ms,
                        duration: 450.ms,
                      ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Description field ───────────
                  TextFormField(
                        controller: _descriptionController,
                        maxLines: 4,
                        maxLength: 500,
                        textInputAction: TextInputAction.newline,
                        decoration: InputDecoration(
                          labelText: 'الوصف (اختياري)',
                          hintText: 'أضف تفاصيل إضافية عن المهمة...',
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(
                              bottom: 60,
                            ),
                            child: Icon(
                              Icons.description_outlined,
                            ),
                          ),
                          alignLabelWithHint: true,
                          filled: true,
                          fillColor: colorScheme.surfaceContainerLowest,
                        ),
                      )
                      .animate()
                      .fadeIn(
                        delay: 300.ms,
                        duration: 450.ms,
                      )
                      .slideY(
                        begin: 0.08,
                        delay: 300.ms,
                        duration: 450.ms,
                      ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Due date picker ─────────────
                  _DueDateSelector(
                        selectedDate: _selectedDueDate,
                        onTap: _pickDueDate,
                        onClear: () => setState(
                          () => _selectedDueDate = null,
                        ),
                        colorScheme: colorScheme,
                        theme: theme,
                      )
                      .animate()
                      .fadeIn(
                        delay: 400.ms,
                        duration: 450.ms,
                      )
                      .slideY(
                        begin: 0.08,
                        delay: 400.ms,
                        duration: 450.ms,
                      ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Assign-to email field ───────
                  _AssignToField(
                        controller: _assignEmailController,
                        focusNode: _assignEmailFocus,
                        isLoading: _isLookingUpUser,
                        helperText: _isEditing
                            ? 'اتركه فارغًا للحفاظ على التكليف الحالي'
                            : null,
                        colorScheme: colorScheme,
                        theme: theme,
                      )
                      .animate()
                      .fadeIn(
                        delay: 450.ms,
                        duration: 450.ms,
                      )
                      .slideY(
                        begin: 0.08,
                        delay: 450.ms,
                        duration: 450.ms,
                      ),
                  const SizedBox(
                    height: AppSpacing.xxl,
                  ),

                  // ── Submit button ───────────────
                  SizedBox(
                        height: 56,
                        child: FilledButton(
                          onPressed: isBusy ? null : _handleSubmit,
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSpacing.buttonRadius,
                              ),
                            ),
                          ),
                          child: isBusy
                              ? SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: colorScheme.onPrimary,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.check_circle_outline_rounded,
                                    ),
                                    const SizedBox(
                                      width: AppSpacing.sm,
                                    ),
                                    Text(
                                      _isEditing
                                          ? 'حفظ التغييرات'
                                          : 'إنشاء المهمة',
                                      style: theme.textTheme.labelLarge
                                          ?.copyWith(
                                            color: colorScheme.onPrimary,
                                          ),
                                    ),
                                  ],
                                ),
                        ),
                      )
                      .animate()
                      .fadeIn(
                        delay: 500.ms,
                        duration: 500.ms,
                      )
                      .slideY(
                        begin: 0.15,
                        delay: 500.ms,
                        duration: 500.ms,
                        curve: Curves.easeOutCubic,
                      ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Assign-to email field
// ─────────────────────────────────────────────────────────────────────────

class _AssignToField extends StatelessWidget {
  const _AssignToField({
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.helperText,
    required this.colorScheme,
    required this.theme,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final String? helperText;
  final ColorScheme colorScheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section label
        Row(
          children: [
            Icon(
              Icons.person_add_alt_1_rounded,
              size: 18,
              color: colorScheme.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'تعيين المهمة لشخص آخر',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          textDirection: TextDirection.ltr,
          decoration: InputDecoration(
            labelText: 'تعيين إلى (البريد الإلكتروني)',
            hintText: 'example@email.com',
            hintTextDirection: TextDirection.ltr,
            prefixIcon: const Icon(Icons.alternate_email_rounded),
            helperText: helperText,
            helperMaxLines: 2,
            suffixIcon: isLoading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(
                      Icons.clear_rounded,
                      size: 20,
                    ),
                    onPressed: () {
                      controller.clear();
                      // Force rebuild to hide the
                      // clear button.
                      (context as Element).markNeedsBuild();
                    },
                  )
                : null,
            filled: true,
            fillColor: colorScheme.surfaceContainerLowest,
            helperStyle: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return null; // Optional field
            }
            // Basic email format check.
            final emailRegex = RegExp(
              r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
            );
            if (!emailRegex.hasMatch(value.trim())) {
              return 'يرجى إدخال بريد إلكتروني صحيح';
            }
            return null;
          },
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Due date selector chip
// ─────────────────────────────────────────────────────────────────────────

class _DueDateSelector extends StatelessWidget {
  const _DueDateSelector({
    required this.selectedDate,
    required this.onTap,
    required this.onClear,
    required this.colorScheme,
    required this.theme,
  });

  final DateTime? selectedDate;
  final VoidCallback onTap;
  final VoidCallback onClear;
  final ColorScheme colorScheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final hasDate = selectedDate != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(
        AppSpacing.inputRadius,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
            AppSpacing.inputRadius,
          ),
          color: hasDate
              ? colorScheme.primaryContainer.withValues(alpha: 0.3)
              : colorScheme.surfaceContainerLowest,
          border: Border.all(
            color: hasDate
                ? colorScheme.primary.withValues(alpha: 0.4)
                : colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            Icon(
              hasDate
                  ? Icons.event_available_rounded
                  : Icons.calendar_today_rounded,
              color: hasDate
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
              size: 22,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'تاريخ الاستحقاق (اختياري)',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (hasDate) ...[
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(selectedDate!),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (hasDate)
              IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
                onPressed: onClear,
                tooltip: 'إزالة التاريخ',
              )
            else
              Icon(
                Icons.chevron_left_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
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
    final timeStr =
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
    return '${date.day} ${months[date.month - 1]} ${date.year} — $timeStr';
  }
}
