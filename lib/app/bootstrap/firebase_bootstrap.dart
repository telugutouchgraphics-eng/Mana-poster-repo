import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

import 'package:mana_poster/firebase_options.dart';

class FirebaseBootstrap {
  const FirebaseBootstrap._();

  static bool get hasFirebaseApp => Firebase.apps.isNotEmpty;

  static FirebaseOptions? get currentOptions =>
      DefaultFirebaseOptions.currentPlatformOrNull;

  static Future<void> ensureInitialized() async {
    if (Firebase.apps.isNotEmpty) {
      return;
    }

    try {
      final FirebaseOptions? options = currentOptions;
      if (options != null) {
        await Firebase.initializeApp(options: options);
        return;
      }

      if (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.iOS ||
              defaultTargetPlatform == TargetPlatform.macOS)) {
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
  }
}
