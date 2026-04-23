import 'dart:developer' as developer;
import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/scheduler.dart';

import 'package:mana_poster/app/app.dart';
import 'package:mana_poster/app/bootstrap/firebase_bootstrap.dart';
import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/features/prehome/services/app_flow_service.dart';
import 'package:mana_poster/features/prehome/services/device_session_service.dart';
import 'package:mana_poster/features/prehome/services/notification_service.dart';
import 'package:mana_poster/app/navigation/web_url_strategy.dart';

const bool _profileFrames = bool.fromEnvironment(
  'MANA_POSTER_PROFILE_FRAMES',
  defaultValue: false,
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

  if (Firebase.apps.isNotEmpty && !kIsWeb) {
    await NotificationService.instance.initialize();
  }
  if (Firebase.apps.isNotEmpty) {
    await DeviceSessionService.instance.start();
  }

  final snapshot = await AppFlowService.loadSnapshot();

  runApp(ManaPosterApp(initialLanguage: snapshot.language));
}

bool _isPublicWebLandingBootstrap() {
  if (!kIsWeb) {
    return false;
  }
  final Uri uri = Uri.base;
  final String host = uri.host.toLowerCase();
  final String path = uri.path.toLowerCase();
  final bool adminHost = host == 'admin.manaposter.in' ||
      host == 'webapp.manaposter.in' ||
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
