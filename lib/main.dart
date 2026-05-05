import 'dart:developer' as developer;
import 'dart:async';
import 'dart:ui';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/scheduler.dart';

import 'package:mana_poster/app/app.dart';
import 'package:mana_poster/app/bootstrap/firebase_bootstrap.dart';
import 'package:mana_poster/app/localization/app_language.dart';
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

  if (_isPublicWebLandingBootstrap()) {
    runApp(const ManaPosterApp(initialLanguage: AppLanguage.english));
    unawaited(FirebaseBootstrap.ensureInitialized());
    return;
  }

  await FirebaseBootstrap.ensureInitialized();
  await _configureFirebaseMonitoring();

  if (Firebase.apps.isNotEmpty && !kIsWeb) {
    await NotificationService.instance.initialize();
    unawaited(OfflineBackgroundRemovalService.warmUp());
    unawaited(InAppPurchaseGateway().initialize());
  }
  if (Firebase.apps.isNotEmpty) {
    await DeviceSessionService.instance.start();
    unawaited(
      SubscriptionBackendService().refreshEntitlementInBackground(
        forceRefresh: true,
        clearCacheFirst: true,
      ),
    );
    _subscriptionLifecycleListener ??= AppLifecycleListener(
      onResume: () {
        unawaited(
          SubscriptionBackendService().refreshEntitlementInBackground(
            forceRefresh: true,
            clearCacheFirst: true,
          ),
        );
      },
    );
  }

  final snapshot = await AppFlowService.loadSnapshot();
  if (Firebase.apps.isNotEmpty) {
    unawaited(AppFlowService.syncStoredLanguageToRemote());
  }

  runZonedGuarded(
    () {
      runApp(ManaPosterApp(initialLanguage: snapshot.language));
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

Future<void> _configureFirebaseMonitoring() async {
  if (Firebase.apps.isEmpty) {
    return;
  }

  await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(!kDebugMode);

  if (kIsWeb) {
    return;
  }

  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
    !kDebugMode,
  );

  FlutterError.onError = (FlutterErrorDetails details) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stackTrace) {
    FirebaseCrashlytics.instance.recordError(error, stackTrace, fatal: true);
    return true;
  };
}

bool _isPublicWebLandingBootstrap() {
  if (!kIsWeb) {
    return false;
  }
  final Uri uri = Uri.base;
  final String host = uri.host.toLowerCase();
  final String path = uri.path.toLowerCase();
  final bool adminHost =
      host == 'admin.manaposter.in' ||
      host == 'webapp.manaposter.in' ||
      host == 'creator.manaposter.in' ||
      host == 'manager.manaposter.in' ||
      host == 'mana-poster-admin.web.app';
  final bool adminPath =
      path == '/website-admin' || path.startsWith('/website-admin/');
  return !adminHost && !adminPath;
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
