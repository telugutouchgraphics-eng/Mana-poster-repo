import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/scheduler.dart';

import 'package:mana_poster/app/app.dart';
import 'package:mana_poster/features/prehome/services/app_flow_service.dart';
import 'package:mana_poster/features/prehome/services/notification_service.dart';
import 'package:mana_poster/firebase_options.dart';

const bool _profileFrames = bool.fromEnvironment(
  'MANA_POSTER_PROFILE_FRAMES',
  defaultValue: false,
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (_profileFrames) {
    _attachFrameProfiler();
  }

  try {
    final options = DefaultFirebaseOptions.currentPlatformOrNull;
    if (options != null) {
      await Firebase.initializeApp(options: options);
    } else if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      await Firebase.initializeApp();
    }
  } catch (error, stackTrace) {
    developer.log(
      'Firebase init failed, continuing without Firebase bootstrap.',
      name: 'bootstrap.firebase',
      error: error,
      stackTrace: stackTrace,
    );
  }

  if (Firebase.apps.isNotEmpty && !kIsWeb) {
    await NotificationService.instance.initialize();
  }

  final snapshot = await AppFlowService.loadSnapshot();

  runApp(ManaPosterApp(initialLanguage: snapshot.language));
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
