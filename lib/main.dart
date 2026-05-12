import 'dart:developer' as developer;
import 'dart:async';
import 'dart:ui';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/scheduler.dart';

import 'package:mana_poster/app/app.dart';
import 'package:mana_poster/app/bootstrap/firebase_bootstrap.dart';
import 'package:mana_poster/app/config/app_public_info.dart';
import 'package:mana_poster/features/image_editor/services/background_removal_service.dart';
import 'package:mana_poster/features/image_editor/services/pro_purchase_gateway.dart';
import 'package:mana_poster/features/image_editor/services/subscription_backend_service.dart';
import 'package:mana_poster/features/prehome/services/app_flow_service.dart';
import 'package:mana_poster/features/prehome/services/device_session_service.dart';
import 'package:mana_poster/features/prehome/services/notification_service.dart';
import 'package:mana_poster/app/navigation/web_url_strategy.dart';

const bool _profileFrames = bool.fromEnvironment(
  'MANA_POSTER_PROFILE_FRAMES',
  defaultValue: false,
);
AppLifecycleListener? _subscriptionLifecycleListener;

Future<void> main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      if (!kIsWeb) {
        NotificationService.registerBackgroundHandler();
      }
      if (kIsWeb) {
        configureWebUrlStrategy();
      }
      if (_profileFrames) {
        _attachFrameProfiler();
      }

      await FirebaseBootstrap.ensureInitialized();
      await _configureFirebaseMonitoring();

      final snapshot = await AppFlowService.loadSnapshot();

      runApp(ManaPosterApp(initialLanguage: snapshot.language));
      unawaited(_runPostLaunchInitialization());
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

Future<void> _runPostLaunchInitialization() async {
  if (Firebase.apps.isEmpty) {
    return;
  }

  if (!kIsWeb) {
    await _runStartupTask(
      'notification_initialize',
      NotificationService.instance.initialize,
    );
    unawaited(
      _runStartupTask(
        'background_removal_warmup',
        OfflineBackgroundRemovalService.warmUp,
      ),
    );
    unawaited(
      _runStartupTask(
        'purchase_gateway_initialize',
        InAppPurchaseGateway().initialize,
      ),
    );
    if (AppPublicInfo.hasAnyAdMobConfig) {
      unawaited(
        _runStartupTask('admob_initialize', () async {
          await MobileAds.instance.initialize();
        }),
      );
    }
  }

  await _runStartupTask(
    'device_session_start',
    DeviceSessionService.instance.start,
  );
  unawaited(
    _runStartupTask(
      'subscription_refresh_post_launch',
      () => SubscriptionBackendService().refreshEntitlementInBackground(
        forceRefresh: true,
        clearCacheFirst: true,
      ),
    ),
  );
  unawaited(
    _runStartupTask(
      'sync_stored_language',
      AppFlowService.syncStoredLanguageToRemote,
    ),
  );
  _subscriptionLifecycleListener ??= AppLifecycleListener(
    onResume: () {
      unawaited(
        _runStartupTask(
          'notification_preferences_resume_sync',
          NotificationService.instance.syncCurrentPreferences,
        ),
      );
      unawaited(
        _runStartupTask(
          'subscription_refresh_resume',
          () => SubscriptionBackendService().refreshEntitlementInBackground(
            forceRefresh: true,
            clearCacheFirst: true,
          ),
        ),
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

Future<void> _configureFirebaseMonitoring() async {
  if (Firebase.apps.isEmpty) {
    return;
  }

  try {
    await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(!kDebugMode);
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
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
      !kDebugMode,
    );

    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      if (_isRecoverableFlutterError(details)) {
        FirebaseCrashlytics.instance.recordFlutterError(details, fatal: false);
        return;
      }
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    };

    PlatformDispatcher.instance.onError = (
      Object error,
      StackTrace stackTrace,
    ) {
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
