import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb, kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:mana_poster/app/bootstrap/firebase_bootstrap.dart';
import 'package:mana_poster/app/services/install_source_service.dart';
import 'package:mana_poster/features/image_editor/services/subscription_backend_service.dart';
import 'package:mana_poster/features/prehome/services/app_flow_service.dart';
import 'package:mana_poster/features/prehome/services/app_party_preference_service.dart';
import 'package:mana_poster/features/prehome/services/poster_profile_service.dart';
import 'package:mana_poster/features/prehome/services/referral_reward_service.dart';

import 'package:mana_poster/app/config/app_public_info.dart';
import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/app/navigation/app_navigator.dart';
import 'package:mana_poster/app/routes/app_routes.dart';
import 'package:mana_poster/app/startup/post_splash_startup_gate.dart';
import 'package:mana_poster/app/theme/app_theme.dart';

class ManaPosterApp extends StatefulWidget {
  const ManaPosterApp({
    super.key,
    this.initialLanguage = AppLanguage.english,
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
  static const bool _enableDebugFirebaseBindings = bool.fromEnvironment(
    'MANA_POSTER_ENABLE_PROFILE_STARTUP_SERVICES',
    defaultValue: false,
  );

  late final AppLanguageController _languageController;
  late final ThemeData _appTheme;
  FirebaseAnalyticsObserver? _analyticsObserver;
  StreamSubscription<User?>? _authUidSubscription;
  String? _lastSeenAuthUid;
  bool _firebaseBindingsAttached = false;

  @override
  void initState() {
    super.initState();
    _languageController = AppLanguageController(
      initialLanguage: widget.initialLanguage,
    );
    _appTheme = AppTheme.light();
    _attachFirebaseBindingsIfReady();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      unawaited(_awaitFirebaseAndAttachBindings());
    });
  }

  Future<void> _awaitFirebaseAndAttachBindings() async {
    if (_firebaseBindingsAttached) {
      return;
    }
    if (!kReleaseMode && !_enableDebugFirebaseBindings) {
      return;
    }
    if (!await _shouldRunFirebaseBindingsForCurrentInstall()) {
      return;
    }
    try {
      await PostSplashStartupGate.whenReady.timeout(const Duration(seconds: 6));
    } catch (_) {}
    await Future<void>.delayed(
      kReleaseMode ? const Duration(seconds: 90) : const Duration(seconds: 12),
    );
    if (!mounted) {
      return;
    }
    await FirebaseBootstrap.ensureInitialized(activateAppCheck: false);
    if (!mounted) {
      return;
    }
    if (_attachFirebaseBindingsIfReady()) {
      setState(() {});
    }
  }

  Future<bool> _shouldRunFirebaseBindingsForCurrentInstall() async {
    if (!kReleaseMode || kIsWeb) {
      return true;
    }
    if (defaultTargetPlatform != TargetPlatform.android) {
      return true;
    }
    return InstallSourceService.isTrustedPlayInstall();
  }

  bool _attachFirebaseBindingsIfReady() {
    if (_firebaseBindingsAttached || Firebase.apps.isEmpty) {
      return false;
    }
    if (kReleaseMode) {
      _analyticsObserver = FirebaseAnalyticsObserver(
        analytics: FirebaseAnalytics.instance,
      );
    }
    _attachSubscriptionEntitlementToAuth();
    if (FirebaseAuth.instance.currentUser != null) {
      unawaited(ReferralRewardService().applyInstallReferrerIfAvailable());
    }
    _firebaseBindingsAttached = true;
    return true;
  }

  void _attachSubscriptionEntitlementToAuth() {
    final auth = FirebaseAuth.instance;
    _lastSeenAuthUid = auth.currentUser?.uid;
    if (_lastSeenAuthUid?.trim().isNotEmpty == true) {
      unawaited(AppFlowService.persistLastKnownAuthUid(_lastSeenAuthUid));
    }
    _authUidSubscription = auth.authStateChanges().listen((User? user) async {
      final nextUid = user?.uid;
      if (nextUid?.trim().isNotEmpty == true) {
        unawaited(AppFlowService.persistLastKnownAuthUid(nextUid));
      }
      if (nextUid == _lastSeenAuthUid) {
        return;
      }
      final previousUid = _lastSeenAuthUid;
      _lastSeenAuthUid = nextUid;
      if (previousUid != null && previousUid.trim().isNotEmpty) {
        try {
          await PosterProfileService.clearLocalCacheForUid(previousUid);
        } catch (_) {}
      }
      try {
        await SubscriptionBackendService.resetLocalClientStateForAuthChange();
      } catch (_) {}
      if (nextUid != null) {
        unawaited(ReferralRewardService().applyInstallReferrerIfAvailable());
        unawaited(AppPartyPreferenceService.syncStoredSelectionToRemote());
        try {
          await PosterProfileService.refreshFromRemote();
        } catch (_) {}
        unawaited(
          SubscriptionBackendService().refreshEntitlementInBackground(
            forceRefresh: true,
            clearCacheFirst: false,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _authUidSubscription?.cancel();
    _languageController.dispose();
    super.dispose();
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
            theme: _appTheme,
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
