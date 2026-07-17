import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ScreenSecurityService {
  ScreenSecurityService._();

  static const bool _screenProtectionEnabled = true;
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
      if (_protectedScreenDepth > 0 && !_isAdminBypassUser()) {
        await _channel.invokeMethod<void>('enableSecure');
        return;
      }
      await _channel.invokeMethod<void>('disableSecure');
    } catch (_) {}
  }

  static bool _isAdminBypassUser() {
    final currentEmail = _normalizeEmail(
      FirebaseAuth.instance.currentUser?.email,
    );
    if (currentEmail.isEmpty) {
      return false;
    }
    return _screenProtectionBypassEmails
        .map(_normalizeEmail)
        .where((email) => email.isNotEmpty)
        .contains(currentEmail);
  }

  static String _normalizeEmail(String? email) =>
      (email ?? '').trim().toLowerCase();
}
