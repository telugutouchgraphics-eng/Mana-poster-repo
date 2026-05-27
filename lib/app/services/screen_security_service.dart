import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ScreenSecurityService {
  ScreenSecurityService._();

  static const bool _screenProtectionEnabled = true;

  static const MethodChannel _channel = MethodChannel(
    'mana_poster/screen_security',
  );

  static Future<void> enableSecure() async {
    if (kIsWeb || !_screenProtectionEnabled) {
      return;
    }
    try {
      await _channel.invokeMethod<void>('enableSecure');
    } catch (_) {}
  }

  static Future<void> disableSecure() async {
    if (kIsWeb || !_screenProtectionEnabled) {
      return;
    }
    try {
      // Native side keeps protection permanently enabled.
      await _channel.invokeMethod<void>('disableSecure');
    } catch (_) {}
  }
}
