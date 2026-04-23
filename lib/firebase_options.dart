import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions? get currentPlatformOrNull {
    if (kIsWeb) {
      return web;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return null;
      case TargetPlatform.macOS:
        return null;
      case TargetPlatform.windows:
        return null;
      case TargetPlatform.linux:
        return null;
      case TargetPlatform.fuchsia:
        return null;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBc_SrDCjsg-DmWGP3A7Gq6dqTj7AH9q5w',
    appId: '1:1093335255199:android:2b3e0d1f5edfb17c1bfaaa',
    messagingSenderId: '1093335255199',
    projectId: 'mana-poster-ap',
    storageBucket: 'mana-poster-ap.firebasestorage.app',
    databaseURL: 'https://mana-poster-ap-default-rtdb.firebaseio.com',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBc_SrDCjsg-DmWGP3A7Gq6dqTj7AH9q5w',
    appId: '1:1093335255199:web:mana_poster_web',
    messagingSenderId: '1093335255199',
    projectId: 'mana-poster-ap',
    authDomain: 'mana-poster-ap.firebaseapp.com',
    storageBucket: 'mana-poster-ap.firebasestorage.app',
    databaseURL: 'https://mana-poster-ap-default-rtdb.firebaseio.com',
  );

  static const String androidPackageName = 'com.manaposter.app';
  static const String webClientId =
      '1093335255199-b1ivtd5u83bchcv22hvqes7dsounkui2.apps.googleusercontent.com';
  static const String iosClientId =
      '1093335255199-ar6eh077lj97rhbfhvak4vi2dftr1bdl.apps.googleusercontent.com';
  static const String iosBundleId = 'com.manaposter.app';
}
