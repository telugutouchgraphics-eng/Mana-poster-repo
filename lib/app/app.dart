import 'package:flutter/material.dart';

import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/app/navigation/app_navigator.dart';
import 'package:mana_poster/app/routes/app_routes.dart';
import 'package:mana_poster/app/theme/app_theme.dart';

class ManaPosterApp extends StatefulWidget {
  const ManaPosterApp({super.key, this.initialLanguage = AppLanguage.telugu});

  final AppLanguage initialLanguage;

  @override
  State<ManaPosterApp> createState() => _ManaPosterAppState();
}

class _ManaPosterAppState extends State<ManaPosterApp> {
  static const bool _showPerformanceOverlay = bool.fromEnvironment(
    'MANA_POSTER_SHOW_PERF_OVERLAY',
    defaultValue: false,
  );
  static const bool _showRasterCheckerboard = bool.fromEnvironment(
    'MANA_POSTER_SHOW_RASTER_CHECKERBOARD',
    defaultValue: false,
  );

  late final AppLanguageController _languageController;

  @override
  void initState() {
    super.initState();
    _languageController = AppLanguageController(
      initialLanguage: widget.initialLanguage,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _languageController,
      builder: (context, _) {
        return AppLanguageScope(
          language: _languageController.language,
          controller: _languageController,
          child: MaterialApp(
            navigatorKey: AppNavigator.navigatorKey,
            debugShowCheckedModeBanner: false,
            showPerformanceOverlay: _showPerformanceOverlay,
            checkerboardRasterCacheImages: _showRasterCheckerboard,
            title: 'Mana Poster',
            theme: AppTheme.light(),
            initialRoute: AppRoutes.splash,
            routes: AppRoutes.map,
          ),
        );
      },
    );
  }
}
