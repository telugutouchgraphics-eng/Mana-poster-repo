import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mana_poster/src/core/localization/app_language.dart';
import 'package:mana_poster/src/core/localization/localization_controller.dart';
import 'package:mana_poster/src/core/routes/app_router.dart';

class ManaPosterApp extends ConsumerWidget {
  const ManaPosterApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLanguage language = ref.watch(localizationControllerProvider);

    return MaterialApp.router(
      title: 'Mana Poster',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F9FC),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Color(0xFF1A1A1A),
        ),
      ),
      routerConfig: appRouter,
      locale: language.locale,
      supportedLocales: const <Locale>[
        Locale('te'),
        Locale('hi'),
        Locale('en'),
      ],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
