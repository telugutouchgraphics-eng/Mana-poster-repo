import 'dart:developer' as developer;

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show
        TargetPlatform,
        defaultTargetPlatform,
        kDebugMode,
        kIsWeb,
        kProfileMode,
        kReleaseMode;

import 'package:mana_poster/app/services/install_source_service.dart';
import 'package:mana_poster/firebase_options.dart';

const String _androidAppCheckDebugToken = String.fromEnvironment(
  'MANA_POSTER_APP_CHECK_DEBUG_TOKEN',
  // Stable fallback so token won't rotate on each reinstall.
  defaultValue: 'df4e5e85-dfc0-4079-8b25-7f96f8f24244',
);
const bool _enableReleaseAppCheck = bool.fromEnvironment(
  'MANA_POSTER_ENABLE_RELEASE_APP_CHECK',
  defaultValue: true,
);

class FirebaseBootstrap {
  const FirebaseBootstrap._();

  static Future<void>? _appCheckActivationFuture;

  static bool get hasFirebaseApp => Firebase.apps.isNotEmpty;

  static FirebaseOptions? get currentOptions =>
      DefaultFirebaseOptions.currentPlatformOrNull;

  static Future<void> ensureInitialized({bool activateAppCheck = true}) async {
    if (Firebase.apps.isNotEmpty) {
      if (activateAppCheck) {
        await _activateAppCheckIfNeeded();
      }
      return;
    }

    try {
      final FirebaseOptions? options = currentOptions;
      if (options != null) {
        await Firebase.initializeApp(options: options);
        if (activateAppCheck) {
          await _activateAppCheckIfNeeded();
        }
        return;
      }

      if (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.iOS ||
              defaultTargetPlatform == TargetPlatform.macOS)) {
        await Firebase.initializeApp();
        if (activateAppCheck) {
          await _activateAppCheckIfNeeded();
        }
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

  static Future<void> activateAppCheckIfNeeded() async {
    if (!hasFirebaseApp) {
      return;
    }
    await _activateAppCheckIfNeeded();
  }

  static Future<void> _activateAppCheckIfNeeded() async {
    final inFlight = _appCheckActivationFuture;
    if (inFlight != null) {
      await inFlight;
      return;
    }
    if (!_shouldActivateAppCheckForCurrentBuild) {
      developer.log(
        'Skipping Firebase App Check outside debug/release builds.',
        name: 'bootstrap.firebase',
      );
      return;
    }
    final activation = _activateAppCheck();
    _appCheckActivationFuture = activation;
    try {
      await activation;
    } finally {
      if (identical(_appCheckActivationFuture, activation)) {
        _appCheckActivationFuture = activation;
      }
    }
  }

  static bool get _shouldActivateAppCheckForCurrentBuild =>
      kDebugMode || kProfileMode || (kReleaseMode && _enableReleaseAppCheck);

  static Future<void> _activateAppCheck() async {
    try {
      if (kIsWeb) {
        return;
      }

      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          final provider = await _resolveAndroidProvider();
          if (provider == null) {
            return;
          }
          await FirebaseAppCheck.instance.activate(
            providerAndroid: provider,
          );
          return;
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
          await FirebaseAppCheck.instance.activate(
            providerApple: kReleaseMode
                ? const AppleAppAttestWithDeviceCheckFallbackProvider()
                : const AppleDebugProvider(),
          );
          return;
        case TargetPlatform.windows:
        case TargetPlatform.linux:
        case TargetPlatform.fuchsia:
          return;
      }
    } catch (error, stackTrace) {
      developer.log(
        'Firebase App Check activation skipped: $error',
        name: 'bootstrap.firebase',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  static Future<AndroidAppCheckProvider?> _resolveAndroidProvider() async {
    if (!kReleaseMode) {
      return AndroidDebugProvider(
        debugToken: _androidAppCheckDebugToken.isEmpty
            ? null
            : _androidAppCheckDebugToken,
      );
    }

    final trustedPlayInstall = await InstallSourceService.isTrustedPlayInstall();
    if (trustedPlayInstall) {
      developer.log(
        'Using Play Integrity provider for trusted Play install.',
        name: 'bootstrap.firebase',
      );
      return const AndroidPlayIntegrityProvider();
    }

    developer.log(
      'Skipping App Check on sideloaded release install to avoid false attestation failures during local validation. Play installs still use Play Integrity.',
      name: 'bootstrap.firebase',
    );
    return null;
  }
}
