import 'dart:developer' as developer;
import 'dart:async';
import 'dart:ui';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb, kProfileMode, kReleaseMode;
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/scheduler.dart';

import 'package:mana_poster/app/app.dart';
import 'package:mana_poster/app/bootstrap/firebase_bootstrap.dart';
import 'package:mana_poster/app/config/app_public_info.dart';
import 'package:mana_poster/app/services/install_source_service.dart';
import 'package:mana_poster/app/startup/post_splash_startup_gate.dart';
import 'package:mana_poster/app/services/admob_consent_service.dart';
import 'package:mana_poster/app/services/app_temporary_cleanup_service.dart';
import 'package:mana_poster/features/image_editor/services/subscription_backend_service.dart';
import 'package:mana_poster/features/prehome/services/app_flow_service.dart';
import 'package:mana_poster/features/prehome/services/device_session_service.dart';
import 'package:mana_poster/features/prehome/services/notification_service.dart';
import 'package:mana_poster/app/navigation/web_url_strategy.dart';
import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/app/routes/app_routes.dart';

const bool _profileFrames = bool.fromEnvironment(
  'MANA_POSTER_PROFILE_FRAMES',
  defaultValue: false,
);
const bool _enableNonEssentialProfileStartupServices = bool.fromEnvironment(
  'MANA_POSTER_ENABLE_PROFILE_STARTUP_SERVICES',
  defaultValue: false,
);
AppLifecycleListener? _subscriptionLifecycleListener;
DateTime? _lastSubscriptionResumeRefreshAt;

bool get _shouldRunNonEssentialStartupServices =>
    !kProfileMode || kReleaseMode || _enableNonEssentialProfileStartupServices;

Future<bool> _shouldEnableFirebaseMonitoring() async {
  if (!kReleaseMode || kIsWeb) {
    return false;
  }
  if (defaultTargetPlatform != TargetPlatform.android) {
    return true;
  }
  return InstallSourceService.isTrustedPlayInstall();
}

Future<void> main() async {
  runZonedGuarded(
    () async {
      final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
      FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
      if (kIsWeb) {
        configureWebUrlStrategy();
      }
      if (_profileFrames) {
        _attachFrameProfiler();
      }

      await FirebaseBootstrap.ensureInitialized(activateAppCheck: false);

      AppLanguage initialLanguage = AppLanguage.telugu;
      String resolvedRoute = AppRoutes.language;
      try {
        final startupResolution =
            await AppFlowService.resolveDeterministicStartupState();
        initialLanguage = startupResolution.language;
        resolvedRoute = startupResolution.resolvedRoute;
        developer.log(
          'languageSelected=${startupResolution.languageSelected} '
          'currentUserPresent=${startupResolution.hasAuthenticatedUser} '
          'onboardingCompleted=${startupResolution.onboardingCompleted} '
          'cachedAuthUid=${startupResolution.cachedAuthUid ?? 'null'} '
          'resolvedRoute=$resolvedRoute',
          name: 'startup.resolver',
        );
      } catch (error, stackTrace) {
        developer.log(
          'Deterministic startup resolution failed, falling back to language.',
          name: 'startup.resolver',
          error: error,
          stackTrace: stackTrace,
        );
      }

      runApp(
        ManaPosterApp(
          initialLanguage: initialLanguage,
          forcedHome: AppRoutes.startupScreenFor(resolvedRoute),
          forceSingleRoute: true,
        ),
      );
      SchedulerBinding.instance.addPostFrameCallback((_) {
        FlutterNativeSplash.remove();
        if (!kIsWeb) {
          unawaited(_hideSystemUiAfterFirstFrame());
        }
        unawaited(_runDeferredPostSplashInitialization());
      });
    },
    (error, stackTrace) {
      if (Firebase.apps.isNotEmpty && !kIsWeb) {
        FirebaseCrashlytics.instance.recordError(
          error,
          stackTrace,
          fatal: true,
        );
        return;
      }
      developer.log(
        'Uncaught app error: $error',
        name: 'app.errors',
        error: error,
        stackTrace: stackTrace,
      );
    },
  );
}

Future<void> _hideSystemUiAfterFirstFrame() async {
  await Future<void>.delayed(const Duration(milliseconds: 120));
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: const <SystemUiOverlay>[SystemUiOverlay.top],
  );
}

Future<void> _runDeferredPostSplashInitialization() async {
  try {
    await PostSplashStartupGate.whenReady.timeout(const Duration(seconds: 8));
  } catch (_) {}
  await Future<void>.delayed(const Duration(milliseconds: 1500));
  await _runPostFirstFrameInitialization();
}

Future<void> _runPostFirstFrameInitialization() async {
  await _runStartupTask(
    'firebase_bootstrap',
    () => FirebaseBootstrap.ensureInitialized(),
  );
  unawaited(
    _runStartupTask('firebase_monitoring_gate', () async {
      final enableMonitoring = await _shouldEnableFirebaseMonitoring();
      developer.log(
        'trustedPlayInstallMonitoring=$enableMonitoring',
        name: 'app.monitoring',
      );
      if (!enableMonitoring || Firebase.apps.isEmpty) {
        return;
      }
      await Firebase.app().setAutomaticDataCollectionEnabled(true);
      await _configureFirebaseMonitoring();
    }),
  );
  unawaited(
    _runStartupTask('post_launch_initialization', _runPostLaunchInitialization),
  );
}

Future<void> _runPostLaunchInitialization() async {
  if (Firebase.apps.isEmpty) {
    return;
  }

  if (!kIsWeb) {
    _scheduleStartupTask(
      'temp_directory_cleanup',
      AppTemporaryCleanup.runAfterColdStart,
      delay: const Duration(seconds: 3),
    );
    if (_shouldRunNonEssentialStartupServices) {
      _scheduleUiReadyStartupTask(
        'notification_register_and_initialize',
        () async {
          NotificationService.registerBackgroundHandler();
          await NotificationService.instance.initialize();
        },
        delay: const Duration(seconds: 8),
      );
    }
    if (_shouldRunNonEssentialStartupServices &&
        AppPublicInfo.hasAnyAdMobConfig) {
      _scheduleUiReadyStartupTask('admob_consent_and_initialize', () async {
        await AdMobConsentService.instance.prepareForAds();
        if (await AdMobConsentService.instance.canRequestAds()) {
          await MobileAds.instance.initialize();
        }
      }, delay: const Duration(seconds: 18));
    }
  }

  _scheduleStartupTask(
    'device_session_start',
    DeviceSessionService.instance.start,
    delay: const Duration(seconds: 2),
  );
  _scheduleStartupTask('subscription_refresh_post_launch', () async {
    final service = SubscriptionBackendService();
    await service.refreshEntitlementInBackground(
      forceRefresh: true,
      clearCacheFirst: false,
    );
    await service.recoverPendingPurchaseInBackground();
  }, delay: const Duration(seconds: 4));
  _scheduleStartupTask(
    'sync_stored_language',
    AppFlowService.syncStoredLanguageToRemote,
    delay: const Duration(seconds: 5),
  );
  _subscriptionLifecycleListener ??= AppLifecycleListener(
    onResume: () {
      unawaited(
        _runStartupTask(
          'temp_directory_cleanup_resume',
          AppTemporaryCleanup.sweepEligibleTemporaryFiles,
        ),
      );
      unawaited(
        _runStartupTask(
          'notification_preferences_resume_sync',
          NotificationService.instance.syncCurrentPreferences,
        ),
      );
      unawaited(
        _runStartupTask('subscription_refresh_resume', () async {
          final now = DateTime.now();
          final lastRun = _lastSubscriptionResumeRefreshAt;
          if (lastRun != null &&
              now.difference(lastRun) < const Duration(minutes: 2)) {
            return;
          }
          _lastSubscriptionResumeRefreshAt = now;
          final service = SubscriptionBackendService();
          await service.refreshEntitlementInBackground(
            forceRefresh: true,
            clearCacheFirst: false,
          );
          await service.recoverPendingPurchaseInBackground();
        }),
      );
    },
  );
}

Future<void> _runStartupTask(
  String taskName,
  Future<void> Function() task,
) async {
  try {
    await task();
  } catch (error, stackTrace) {
    developer.log(
      'Startup task skipped: $taskName: $error',
      name: 'app.startup',
      error: error,
      stackTrace: stackTrace,
    );
    if (Firebase.apps.isNotEmpty && !kIsWeb) {
      try {
        await FirebaseCrashlytics.instance.recordError(
          error,
          stackTrace,
          reason: 'nonfatal_startup_task:$taskName',
          fatal: false,
        );
      } catch (_) {}
    }
  }
}

void _scheduleStartupTask(
  String taskName,
  Future<void> Function() task, {
  Duration delay = Duration.zero,
}) {
  unawaited(() async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    await _runStartupTask(taskName, task);
  }());
}

void _scheduleUiReadyStartupTask(
  String taskName,
  Future<void> Function() task, {
  Duration delay = Duration.zero,
}) {
  unawaited(() async {
    try {
      await PostSplashStartupGate.whenReady.timeout(
        const Duration(seconds: 20),
      );
    } catch (_) {}
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    await _runStartupTask(taskName, task);
  }());
}

Future<void> _configureFirebaseMonitoring() async {
  if (Firebase.apps.isEmpty || !kReleaseMode) {
    return;
  }

  try {
    await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
  } catch (error, stackTrace) {
    developer.log(
      'Analytics monitoring setup skipped: $error',
      name: 'app.monitoring',
      error: error,
      stackTrace: stackTrace,
    );
  }

  if (kIsWeb) {
    return;
  }

  try {
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      if (_isRecoverableFlutterError(details)) {
        FirebaseCrashlytics.instance.recordFlutterError(details, fatal: false);
        return;
      }
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    };

    PlatformDispatcher.instance.onError =
        (Object error, StackTrace stackTrace) {
          FirebaseCrashlytics.instance.recordError(
            error,
            stackTrace,
            fatal: !_isRecoverableError(error),
          );
          return true;
        };
  } catch (error, stackTrace) {
    developer.log(
      'Crashlytics monitoring setup skipped: $error',
      name: 'app.monitoring',
      error: error,
      stackTrace: stackTrace,
    );
  }
}

bool _isRecoverableFlutterError(FlutterErrorDetails details) {
  return _isRecoverableError(details.exception) ||
      _containsRecoverableSignal(details.exceptionAsString()) ||
      _containsRecoverableSignal(details.stack?.toString() ?? '');
}

bool _isRecoverableError(Object error) {
  return _containsRecoverableSignal(error.toString());
}

bool _containsRecoverableSignal(String value) {
  final normalized = value.toLowerCase();
  return normalized.contains('httpexception: invalid statuscode') ||
      normalized.contains('imagecodec') ||
      normalized.contains('failed host lookup') ||
      normalized.contains('permission-denied') ||
      normalized.contains('already_active') ||
      normalized.contains('zone mismatch') ||
      normalized.contains('connection closed') ||
      normalized.contains('connection reset') ||
      normalized.contains('connection timed out') ||
      normalized.contains('socketexception');
}

void _attachFrameProfiler() {
  SchedulerBinding.instance.addTimingsCallback((timings) {
    for (final timing in timings) {
      final buildMs = timing.buildDuration.inMicroseconds / 1000;
      final rasterMs = timing.rasterDuration.inMicroseconds / 1000;
      final isJanky = buildMs > 16.7 || rasterMs > 16.7;
      if (isJanky) {
        developer.log(
          'JANK frame detected: build=${buildMs.toStringAsFixed(2)}ms '
          'raster=${rasterMs.toStringAsFixed(2)}ms',
          name: 'perf.frame',
        );
      }
    }
  });
}
