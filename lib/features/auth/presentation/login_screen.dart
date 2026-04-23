/// Login screen — premium Arabic RTL authentication UI.
///
/// Provides email/password sign-in with full form validation,
/// async loading states, and graceful error handling via
/// Arabic-language snackbars.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mungiz/core/constants/app_constants.dart';
import 'package:mungiz/core/theme/app_spacing.dart';
import 'package:mungiz/features/auth/data/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Authentication login screen.
class LoginScreen extends ConsumerStatefulWidget {
  /// Creates a [LoginScreen].
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(authRepositoryProvider).signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      if (mounted) {
        context.go(RoutePaths.home);
      }
    } on AuthException catch (e) {
      if (mounted) {
        _showError(_mapAuthError(e.message));
      }
    } on Object {
      if (mounted) {
        _showError('حدث خطأ غير متوقع. حاول مرة أخرى.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              Theme.of(context).colorScheme.error,
        ),
      );
  }

  String _mapAuthError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('invalid login credentials') ||
        lower.contains('invalid_credentials')) {
      return 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
    }
    if (lower.contains('email not confirmed')) {
      return 'يرجى تأكيد بريدك الإلكتروني أولاً';
    }
    if (lower.contains('too many requests')) {
      return 'محاولات كثيرة. انتظر قليلاً ثم حاول مجدداً';
    }
    return 'خطأ في تسجيل الدخول: $message';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPaddingH,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSpacing.maxContentWidth,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                  children: [
                    // ── Logo / Brand ───────────────
                    Icon(
                      Icons.task_alt_rounded,
                      size: 72,
                      color: colorScheme.primary,
                    )
                        .animate()
                        .fadeIn(duration: 600.ms)
                        .scale(
                          begin: const Offset(0.8, 0.8),
                          duration: 600.ms,
                          curve: Curves.easeOutBack,
                        ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'مُنجِز',
                      textAlign: TextAlign.center,
                      style:
                          theme.textTheme.headlineLarge
                              ?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                        .animate()
                        .fadeIn(
                          delay: 200.ms,
                          duration: 500.ms,
                        ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'سجّل دخولك للمتابعة',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    )
                        .animate()
                        .fadeIn(
                          delay: 350.ms,
                          duration: 500.ms,
                        ),
                    const SizedBox(height: AppSpacing.xxl),

                    // ── Email Field ────────────────
                    TextFormField(
                      controller: _emailController,
                      keyboardType:
                          TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      textDirection: TextDirection.ltr,
                      decoration: const InputDecoration(
                        labelText: 'البريد الإلكتروني',
                        prefixIcon:
                            Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return 'يرجى إدخال البريد'
                              ' الإلكتروني';
                        }
                        if (!_isValidEmail(value.trim())) {
                          return 'صيغة البريد الإلكتروني'
                              ' غير صحيحة';
                        }
                        return null;
                      },
                    )
                        .animate()
                        .fadeIn(
                          delay: 400.ms,
                          duration: 500.ms,
                        )
                        .slideY(
                          begin: 0.1,
                          delay: 400.ms,
                          duration: 500.ms,
                        ),
                    const SizedBox(height: AppSpacing.md),

                    // ── Password Field ────────────
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      textDirection: TextDirection.ltr,
                      onFieldSubmitted: (_) =>
                          _handleSignIn(),
                      decoration: InputDecoration(
                        labelText: 'كلمة المرور',
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons
                                    .visibility_off_outlined,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword =
                                !_obscurePassword,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty) {
                          return 'يرجى إدخال كلمة المرور';
                        }
                        if (value.length < 6) {
                          return 'كلمة المرور يجب أن تكون'
                              ' 6 أحرف على الأقل';
                        }
                        return null;
                      },
                    )
                        .animate()
                        .fadeIn(
                          delay: 500.ms,
                          duration: 500.ms,
                        )
                        .slideY(
                          begin: 0.1,
                          delay: 500.ms,
                          duration: 500.ms,
                        ),
                    const SizedBox(height: AppSpacing.lg),

                    // ── Sign In Button ─────────────
                    ElevatedButton(
                      onPressed:
                          _isLoading ? null : _handleSignIn,
                      child: _isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text('تسجيل الدخول'),
                    )
                        .animate()
                        .fadeIn(
                          delay: 600.ms,
                          duration: 500.ms,
                        ),
                    const SizedBox(height: AppSpacing.md),

                    // ── Register Link ──────────────
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Text(
                          'ليس لديك حساب؟',
                          style: theme.textTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () => context.go(
                                    RoutePaths.register,
                                  ),
                          child: const Text('إنشاء حساب'),
                        ),
                      ],
                    )
                        .animate()
                        .fadeIn(
                          delay: 700.ms,
                          duration: 500.ms,
                        ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _isValidEmail(String email) {
    return RegExp(
      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
    ).hasMatch(email);
  }
}
