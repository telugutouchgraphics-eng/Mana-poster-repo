import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:mana_poster/app/config/app_public_info.dart';
import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/app/navigation/app_navigator.dart';
import 'package:mana_poster/app/routes/app_routes.dart';
import 'package:mana_poster/app/theme/app_theme.dart';

class ManaPosterApp extends StatefulWidget {
  const ManaPosterApp({
    super.key,
    this.initialLanguage = AppLanguage.telugu,
    this.forcedHome,
    this.forceSingleRoute = false,
  });

  final AppLanguage initialLanguage;
  final Widget? forcedHome;
  final bool forceSingleRoute;

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
  FirebaseAnalyticsObserver? _analyticsObserver;

  @override
  void initState() {
    super.initState();
    _languageController = AppLanguageController(
      initialLanguage: widget.initialLanguage,
    );
    if (Firebase.apps.isNotEmpty) {
      _analyticsObserver = FirebaseAnalyticsObserver(
        analytics: FirebaseAnalytics.instance,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _languageController,
      builder: (context, _) {
        final analyticsObserver = _analyticsObserver;
        return AppLanguageScope(
          language: _languageController.language,
          controller: _languageController,
          child: MaterialApp(
            navigatorKey: AppNavigator.navigatorKey,
            debugShowCheckedModeBanner: false,
            showPerformanceOverlay: _showPerformanceOverlay,
            checkerboardRasterCacheImages: _showRasterCheckerboard,
            title: AppPublicInfo.appName,
            theme: AppTheme.light(),
            navigatorObservers: <NavigatorObserver>[
              AppNavigator.routeObserver,
              ?analyticsObserver,
            ],
            home: widget.forceSingleRoute ? null : widget.forcedHome,
            initialRoute: widget.forcedHome == null
                ? AppRoutes.initialRoute
                : null,
            onGenerateInitialRoutes:
                widget.forceSingleRoute && widget.forcedHome != null
                ? (String _) => <Route<dynamic>>[
                    MaterialPageRoute<void>(
                      builder: (_) => widget.forcedHome!,
                      settings: const RouteSettings(name: '/'),
                    ),
                  ]
                : null,
            routes: AppRoutes.map,
            onGenerateRoute: AppRoutes.resolveDynamicRoute,
          ),
        );
      },
    );
  }
}
