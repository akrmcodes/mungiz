/// Premium profile screen — display name editing with glassmorphism.
library;

import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:mungiz/core/constants/app_constants.dart';
import 'package:mungiz/core/database/app_database.dart';
import 'package:mungiz/core/theme/app_spacing.dart';
import 'package:mungiz/features/auth/data/auth_repository.dart';
import 'package:mungiz/features/auth/data/profile_repository.dart';

/// Profile screen for editing the user's display name.
class ProfileScreen extends ConsumerStatefulWidget {
  /// Creates a [ProfileScreen].
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _displayNameController;

  bool _hasSeededInitialName = false;
  bool _isSaving = false;
  bool _isLoggingOut = false;
  bool _isLogoutPressed = false;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _saveDisplayName(ProfileEntry? profile) async {
    if (_isSaving) {
      return;
    }

    final currentUser = ref.read(authRepositoryProvider).currentUser;
    if (currentUser == null) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final nextDisplayName = _displayNameController.text.trim();
    final currentDisplayName = profile?.displayName?.trim() ?? '';
    if (nextDisplayName == currentDisplayName) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: const Text('الاسم محفوظ بالفعل'),
            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          ),
        );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    try {
      await ref
          .read(profileRepositoryProvider)
          .updateDisplayName(currentUser.id, nextDisplayName);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              nextDisplayName.isEmpty
                  ? 'تمت إزالة الاسم المعروض'
                  : 'تم حفظ الاسم المعروض',
            ),
          ),
        );
    } on ProfileLookupException catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
    } on Object {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: const Text('حدث خطأ أثناء حفظ الاسم'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _logout() async {
    if (_isLoggingOut) {
      return;
    }

    setState(() {
      _isLoggingOut = true;
      _isLogoutPressed = false;
    });

    try {
      await ref.read(authRepositoryProvider).signOut();
      if (mounted) {
        context.go(RoutePaths.login);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoggingOut = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentUser = ref.watch(authRepositoryProvider).currentUser;
    final profileAsync = ref.watch(currentUserProfileProvider);
    final profile = profileAsync.asData?.value;

    if (!_hasSeededInitialName && profile != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _hasSeededInitialName) {
          return;
        }

        final nextDisplayName = profile.displayName?.trim() ?? '';
        _displayNameController.text = nextDisplayName;
        _displayNameController.selection = TextSelection.collapsed(
          offset: nextDisplayName.length,
        );
        _hasSeededInitialName = true;
      });
    }

    if (currentUser == null) {
      return const Scaffold(
        body: SizedBox.shrink(),
      );
    }

    final displayLabel = profile?.displayLabel ?? currentUser.email ?? 'حسابي';
    final avatarInitials = _avatarInitials(displayLabel);

    return Scaffold(
      body: Stack(
        children: [
          _ProfileBackdrop(colorScheme: colorScheme),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPaddingH,
                    vertical: AppSpacing.lg,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _ProfileHeroCard(
                                displayLabel: displayLabel,
                                email: currentUser.email ?? '',
                                avatarInitials: avatarInitials,
                                colorScheme: colorScheme,
                                theme: theme,
                              )
                              .animate()
                              .fadeIn(duration: 520.ms)
                              .slideY(
                                begin: 0.08,
                                duration: 620.ms,
                                curve: Curves.easeOutCubic,
                              ),
                          const Gap(AppSpacing.lg),
                          _GlassSurface(
                                child: Padding(
                                  padding: const EdgeInsets.all(
                                    AppSpacing.cardPadding,
                                  ),
                                  child: Form(
                                    key: _formKey,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              width: 36,
                                              height: 36,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                gradient: LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [
                                                    colorScheme.primary,
                                                    colorScheme.tertiary,
                                                  ],
                                                ),
                                              ),
                                              child: Icon(
                                                Icons.edit_rounded,
                                                color: colorScheme.onPrimary,
                                                size: 18,
                                              ),
                                            ),
                                            const Gap(AppSpacing.sm),
                                            Text(
                                              'الاسم المعروض',
                                              style: theme.textTheme.titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                            ),
                                          ],
                                        ),
                                        const Gap(AppSpacing.md),
                                        TextFormField(
                                          controller: _displayNameController,
                                          textInputAction: TextInputAction.done,
                                          textCapitalization:
                                              TextCapitalization.words,
                                          onFieldSubmitted: (_) {
                                            unawaited(
                                              _saveDisplayName(profile),
                                            );
                                          },
                                          decoration: InputDecoration(
                                            labelText: 'الاسم',
                                            hintText:
                                                'اكتب الاسم الذي يظهر '
                                                'في المهام',
                                            prefixIcon: const Icon(
                                              Icons.badge_outlined,
                                            ),
                                            filled: true,
                                            fillColor: colorScheme.surface
                                                .withValues(
                                                  alpha: 0.18,
                                                ),
                                          ),
                                          validator: (value) {
                                            final trimmed = value?.trim() ?? '';
                                            if (trimmed.length > 48) {
                                              return 'الاسم طويل جدًا';
                                            }
                                            return null;
                                          },
                                        ),
                                        const Gap(AppSpacing.sm),
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Icon(
                                              Icons.info_outline_rounded,
                                              size: 18,
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                            ),
                                            const Gap(AppSpacing.xs),
                                            Expanded(
                                              child: Text(
                                                'إذا تركته فارغًا، سيظهر بريدك '
                                                'الإلكتروني في بطاقات المهام.',
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                      color: colorScheme
                                                          .onSurfaceVariant,
                                                      height: 1.4,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const Gap(AppSpacing.lg),
                                        FilledButton.icon(
                                          onPressed: _isSaving
                                              ? null
                                              : () => _saveDisplayName(profile),
                                          icon: _isSaving
                                              ? SizedBox(
                                                  width: 18,
                                                  height: 18,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2.2,
                                                        color: colorScheme
                                                            .onPrimary,
                                                      ),
                                                )
                                              : const Icon(Icons.save_rounded),
                                          label: Text(
                                            _isSaving
                                                ? 'جارٍ الحفظ...'
                                                : 'حفظ الاسم',
                                          ),
                                          style: FilledButton.styleFrom(
                                            minimumSize: const Size.fromHeight(
                                              54,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                              .animate()
                              .fadeIn(
                                delay: 130.ms,
                                duration: 500.ms,
                              )
                              .slideY(
                                begin: 0.08,
                                delay: 130.ms,
                                duration: 550.ms,
                                curve: Curves.easeOutCubic,
                              ),
                          const Spacer(),
                          const Gap(AppSpacing.lg),
                          _SpringLogoutButton(
                                isBusy: _isLoggingOut,
                                isPressed: _isLogoutPressed,
                                onTapDown: () {
                                  if (_isLoggingOut) {
                                    return;
                                  }

                                  setState(() => _isLogoutPressed = true);
                                },
                                onTapCancel: () {
                                  if (_isLoggingOut) {
                                    return;
                                  }

                                  setState(() => _isLogoutPressed = false);
                                },
                                onTapUp: () {
                                  if (_isLoggingOut) {
                                    return;
                                  }

                                  setState(() => _isLogoutPressed = false);
                                },
                                onTap: () {
                                  if (_isLoggingOut) {
                                    return;
                                  }

                                  unawaited(HapticFeedback.mediumImpact());
                                  unawaited(_logout());
                                },
                                colorScheme: colorScheme,
                                theme: theme,
                              )
                              .animate()
                              .fadeIn(
                                delay: 220.ms,
                                duration: 520.ms,
                              )
                              .slideY(
                                begin: 0.12,
                                delay: 220.ms,
                                duration: 560.ms,
                                curve: Curves.easeOutCubic,
                              ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileBackdrop extends StatelessWidget {
  const _ProfileBackdrop({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface,
              colorScheme.surfaceContainerLowest.withValues(alpha: 0.92),
              colorScheme.primaryContainer.withValues(
                alpha: isDark ? 0.18 : 0.34,
              ),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -90,
              left: -50,
              child: _GlowBlob(
                color: colorScheme.primary.withValues(
                  alpha: isDark ? 0.24 : 0.18,
                ),
              ),
            ),
            Positioned(
              top: 180,
              right: -70,
              child: _GlowBlob(
                color: colorScheme.tertiary.withValues(
                  alpha: isDark ? 0.18 : 0.16,
                ),
                size: 180,
              ),
            ),
            Positioned(
              bottom: 110,
              left: -40,
              child: _GlowBlob(
                color: colorScheme.secondary.withValues(
                  alpha: isDark ? 0.16 : 0.12,
                ),
                size: 220,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({
    required this.color,
    this.size = 240,
  });

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 90,
            spreadRadius: 20,
          ),
        ],
      ),
    );
  }
}

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({
    required this.displayLabel,
    required this.email,
    required this.avatarInitials,
    required this.colorScheme,
    required this.theme,
  });

  final String displayLabel;
  final String email;
  final String avatarInitials;
  final ColorScheme colorScheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;

    return _GlassSurface(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          children: [
            Container(
              width: 124,
              height: 124,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primary,
                    colorScheme.tertiary,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.28),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  avatarInitials,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
            const Gap(AppSpacing.lg),
            Text(
              displayLabel,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
              ),
            ),
            const Gap(AppSpacing.xs),
            Text(
              email,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const Gap(AppSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color:
                    (isDark
                            ? colorScheme.surfaceContainerHigh
                            : colorScheme.surfaceContainerLowest)
                        .withValues(alpha: 0.76),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.22),
                ),
              ),
              child: Text(
                'الاسم يُعرض أولاً، ثم البريد إذا كان الاسم فارغًا',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassSurface extends StatelessWidget {
  const _GlassSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius * 1.35),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color:
                (isDark
                        ? colorScheme.surfaceContainerHigh
                        : colorScheme.surface)
                    .withValues(alpha: 0.58),
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius * 1.35),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.22),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.06),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _SpringLogoutButton extends StatelessWidget {
  const _SpringLogoutButton({
    required this.isBusy,
    required this.isPressed,
    required this.onTapDown,
    required this.onTapCancel,
    required this.onTapUp,
    required this.onTap,
    required this.colorScheme,
    required this.theme,
  });

  final bool isBusy;
  final bool isPressed;
  final VoidCallback onTapDown;
  final VoidCallback onTapCancel;
  final VoidCallback onTapUp;
  final VoidCallback onTap;
  final ColorScheme colorScheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedScale(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      scale: isPressed ? 0.97 : 1,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.buttonRadius + 6),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius + 6),
          onTapDown: (_) => onTapDown(),
          onTapCancel: onTapCancel,
          onTapUp: (_) => onTapUp(),
          onTap: isBusy ? null : onTap,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.buttonRadius + 6),
              gradient: LinearGradient(
                colors: [
                  colorScheme.error,
                  colorScheme.errorContainer,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.error.withValues(alpha: 0.24),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  AppSpacing.buttonRadius + 6,
                ),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.white.withValues(alpha: 0.18),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isBusy) ...[
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: colorScheme.onError,
                      ),
                    ),
                  ] else ...[
                    Icon(
                      Icons.logout_rounded,
                      color: colorScheme.onError,
                    ),
                  ],
                  const Gap(AppSpacing.sm),
                  Text(
                    isBusy ? 'جارٍ تسجيل الخروج...' : 'تسجيل الخروج',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.onError,
                      fontWeight: FontWeight.w700,
                    ),
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

String _avatarInitials(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return 'M';
  }

  final words = trimmed
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();

  if (words.isEmpty) {
    return trimmed.substring(0, trimmed.length >= 2 ? 2 : 1).toUpperCase();
  }

  if (words.length == 1) {
    final firstWord = words.first;
    if (firstWord.contains('@')) {
      final localPart = firstWord.split('@').first;
      return localPart.isNotEmpty
          ? localPart.substring(0, 1).toUpperCase()
          : 'M';
    }

    return firstWord
        .substring(
          0,
          firstWord.length >= 2 ? 2 : 1,
        )
        .toUpperCase();
  }

  final first = words.first.substring(0, 1).toUpperCase();
  final second = words[1].substring(0, 1).toUpperCase();
  return '$first$second';
}
