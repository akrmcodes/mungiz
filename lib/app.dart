/// Root application widget for the Mungiz app.
///
/// Configures [MaterialApp.router] with:
///   - Arabic (RTL) localisation forced via `locale: Locale('ar')`.
///   - Material 3 light and dark themes from [AppTheme].
///   - GoRouter for declarative navigation with auth guards.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mungiz/core/router/app_router.dart';
import 'package:mungiz/core/theme/app_theme.dart';

/// The root widget of the Mungiz application.
///
/// Wraps the entire app in Arabic localisation and the Material 3 theme system.
/// This widget reads the [appRouterProvider] from Riverpod to obtain the
/// router, ensuring it rebuilds when auth state changes.
class MungizApp extends ConsumerWidget {
  const MungizApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      // ── Identity ──
      title: 'مُنجِز',
      debugShowCheckedModeBanner: false,

      // ── Localisation (Arabic RTL) ──
      locale: const Locale('ar'),
      supportedLocales: const [
        Locale('ar'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // ── Theme ──
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,

      // ── Router ──
      routerConfig: router,
    );
  }
}
