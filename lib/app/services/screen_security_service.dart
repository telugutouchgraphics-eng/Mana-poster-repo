import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mana_poster/app/bootstrap/firebase_bootstrap.dart';

class ScreenSecurityService {
  ScreenSecurityService._();

  static const bool _screenProtectionEnabled = !kDebugMode;
  static const Set<String> _screenProtectionBypassEmails = <String>{
    'manaposter2026@gmail.com',
    'supportmanaposter@gmail.com',
    String.fromEnvironment(
      'MANA_POSTER_SCREEN_PROTECTION_BYPASS_EMAIL',
      defaultValue: '',
    ),
  };

  static const MethodChannel _channel = MethodChannel(
    'mana_poster/screen_security',
  );

  static int _protectedScreenDepth = 0;
  static StreamSubscription<User?>? _authSubscription;
  static Future<void>? _firebaseReadyFuture;

  static Future<void> protectScreen() async {
    _ensureAuthListener();
    _protectedScreenDepth++;
    await enableSecure();
  }

  static Future<void> unprotectScreen() async {
    if (_protectedScreenDepth > 0) {
      _protectedScreenDepth--;
    }
    await disableSecure();
  }

  static void _ensureAuthListener() {
    if (Firebase.apps.isEmpty) {
      return;
    }
    _authSubscription ??= FirebaseAuth.instance.authStateChanges().listen((
      User? _,
    ) {
      if (_protectedScreenDepth > 0) {
        unawaited(enableSecure());
      } else {
        unawaited(disableSecure());
      }
    });
  }

  static Future<void> enableSecure() async {
    if (kIsWeb || !_screenProtectionEnabled) {
      return;
    }
    try {
      await _ensureFirebaseReadyForBypass();
      if (_isAdminBypassUser()) {
        await _channel.invokeMethod<void>('disableSecure');
        return;
      }
      await _channel.invokeMethod<void>('enableSecure');
    } catch (_) {}
  }

  static Future<void> disableSecure() async {
    if (kIsWeb || !_screenProtectionEnabled) {
      return;
    }
    try {
      await _ensureFirebaseReadyForBypass();
      if (_protectedScreenDepth > 0 && !_isAdminBypassUser()) {
        await _channel.invokeMethod<void>('enableSecure');
        return;
      }
      await _channel.invokeMethod<void>('disableSecure');
    } catch (_) {}
  }

  static bool _isAdminBypassUser() {
    if (Firebase.apps.isEmpty) {
      return false;
    }
    final user = FirebaseAuth.instance.currentUser;
    final currentEmails = <String>{
      _normalizeEmail(user?.email),
      ...?user?.providerData.map((provider) => _normalizeEmail(provider.email)),
    }..removeWhere((email) => email.isEmpty);
    if (currentEmails.isEmpty) {
      return false;
    }
    final bypassEmails = _screenProtectionBypassEmails
        .map(_normalizeEmail)
        .where((email) => email.isNotEmpty)
        .toSet();
    return currentEmails.any(bypassEmails.contains);
  }

  static String _normalizeEmail(String? email) =>
      (email ?? '').trim().toLowerCase();

  static Future<void> _ensureFirebaseReadyForBypass() async {
    if (Firebase.apps.isEmpty) {
      final inFlight = _firebaseReadyFuture;
      if (inFlight != null) {
        await inFlight;
      } else {
        final future = FirebaseBootstrap.ensureInitialized(
          activateAppCheck: false,
        );
        _firebaseReadyFuture = future;
        try {
          await future;
        } finally {
          _firebaseReadyFuture = null;
        }
      }
    }
    _ensureAuthListener();
  }
}
