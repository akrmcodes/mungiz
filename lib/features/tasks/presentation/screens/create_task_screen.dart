/// Create task screen — a premium full-screen form for new tasks.
///
/// Features:
///   - Premium floating-label text fields with Arabic placeholders.
///   - Multi-line description with character counter.
///   - Elegant date picker chip with Arabic locale.
///   - Real-time form validation with Arabic error messages.
///   - Animated submit button with loading state.
///   - Haptic feedback on successful creation.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mungiz/core/theme/app_spacing.dart';
import 'package:mungiz/features/tasks/presentation/providers/task_providers.dart';

/// Full-screen form for creating a new task.
class CreateTaskScreen extends ConsumerStatefulWidget {
  /// Creates a [CreateTaskScreen].
  const CreateTaskScreen({super.key});

  @override
  ConsumerState<CreateTaskScreen> createState() =>
      _CreateTaskScreenState();
}

class _CreateTaskScreenState
    extends ConsumerState<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController =
      TextEditingController();
  final _titleFocus = FocusNode();

  DateTime? _selectedDueDate;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Auto-focus the title field after the entrance animation.
    Future.delayed(600.ms, () {
      if (mounted) _titleFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _titleFocus.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await ref.read(taskActionsProvider).addTask(
            title: _titleController.text.trim(),
            description: _descriptionController
                    .text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            dueAt: _selectedDueDate,
          );

      if (!mounted) return;

      await HapticFeedback.mediumImpact();

      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content:
                const Text('تم إنشاء المهمة بنجاح ✓'),
            backgroundColor: Theme.of(context)
                .colorScheme
                .primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      context.pop();
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content:
                  const Text('فشل في إنشاء المهمة'),
              backgroundColor: Theme.of(context)
                  .colorScheme
                  .error,
            ),
          );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
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

    return Scaffold(
      // ── App bar ─────────────────────────────────────────
      appBar: AppBar(
        title: const Text('مهمة جديدة'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
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
                crossAxisAlignment:
                    CrossAxisAlignment.stretch,
                children: [
                  // ── Section header ──────────────
                  Text(
                    'أضف تفاصيل مهمتك',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideY(
                        begin: 0.1,
                        duration: 400.ms,
                      ),
                  const SizedBox(
                    height: AppSpacing.xs,
                  ),
                  Text(
                    'العنوان مطلوب، والباقي اختياري',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(
                      color:
                          colorScheme.onSurfaceVariant,
                    ),
                  )
                      .animate()
                      .fadeIn(
                        delay: 100.ms,
                        duration: 400.ms,
                      ),
                  const SizedBox(height: AppSpacing.xl),

                  // ── Title field ─────────────────
                  TextFormField(
                    controller: _titleController,
                    focusNode: _titleFocus,
                    textInputAction:
                        TextInputAction.next,
                    maxLength: 100,
                    decoration: InputDecoration(
                      labelText: 'عنوان المهمة *',
                      hintText:
                          'مثال: مراجعة التقرير الأسبوعي',
                      prefixIcon: const Icon(
                        Icons.title_rounded,
                      ),
                      counterText: '',
                      filled: true,
                      fillColor: colorScheme
                          .surfaceContainerLowest,
                    ),
                    validator: (value) {
                      if (value == null ||
                          value.trim().isEmpty) {
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
                    textInputAction:
                        TextInputAction.newline,
                    decoration: InputDecoration(
                      labelText: 'الوصف (اختياري)',
                      hintText:
                          'أضف تفاصيل إضافية عن المهمة...',
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
                      fillColor: colorScheme
                          .surfaceContainerLowest,
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
                  const SizedBox(
                    height: AppSpacing.xxl,
                  ),

                  // ── Submit button ───────────────
                  SizedBox(
                    height: 56,
                    child: FilledButton(
                      onPressed: _isSubmitting
                          ? null
                          : _handleSubmit,
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            AppSpacing.buttonRadius,
                          ),
                        ),
                      ),
                      child: _isSubmitting
                          ? SizedBox(
                              height: 22,
                              width: 22,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: colorScheme
                                    .onPrimary,
                              ),
                            )
                          : Row(
                              mainAxisAlignment:
                                  MainAxisAlignment
                                      .center,
                              children: [
                                const Icon(
                                  Icons
                                      .check_circle_outline_rounded,
                                ),
                                const SizedBox(
                                  width: AppSpacing.sm,
                                ),
                                Text(
                                  'إنشاء المهمة',
                                  style: theme.textTheme
                                      .labelLarge
                                      ?.copyWith(
                                    color: colorScheme
                                        .onPrimary,
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
              ? colorScheme.primaryContainer
                  .withValues(alpha: 0.3)
              : colorScheme.surfaceContainerLowest,
          border: Border.all(
            color: hasDate
                ? colorScheme.primary
                    .withValues(alpha: 0.4)
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
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'تاريخ الاستحقاق (اختياري)',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(
                      color:
                          colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (hasDate) ...[
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(selectedDate!),
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(
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
