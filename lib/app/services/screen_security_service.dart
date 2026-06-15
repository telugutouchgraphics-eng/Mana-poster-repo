import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:mana_poster/app/config/app_public_info.dart';

class ScreenSecurityService {
  ScreenSecurityService._();

  static const bool _screenProtectionEnabled = true;
  static const String _adminScreenProtectionBypassEmail =
      String.fromEnvironment(
        'MANA_POSTER_SCREEN_PROTECTION_BYPASS_EMAIL',
        defaultValue: AppPublicInfo.supportEmail,
      );

  static const MethodChannel _channel = MethodChannel(
    'mana_poster/screen_security',
  );

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
      await _channel.invokeMethod<void>('disableSecure');
    } catch (_) {}
  }

  static bool _isAdminBypassUser() {
    final configuredEmail = _normalizeEmail(_adminScreenProtectionBypassEmail);
    if (configuredEmail.isEmpty) {
      return false;
    }
    final currentEmail = _normalizeEmail(
      FirebaseAuth.instance.currentUser?.email,
    );
    return currentEmail == configuredEmail;
  }

  static String _normalizeEmail(String? email) =>
      (email ?? '').trim().toLowerCase();
}
