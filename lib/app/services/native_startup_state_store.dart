import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class NativeStartupStateStore {
  NativeStartupStateStore._();

  static const MethodChannel _channel = MethodChannel(
    'mana_poster/startup_state',
  );

  static Future<Map<String, Object?>> readAll() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return <String, Object?>{};
    }
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>('readState');
      if (result == null) {
        return <String, Object?>{};
      }
      return Map<String, Object?>.from(result);
    } catch (_) {
      return <String, Object?>{};
    }
  }

  static Future<bool> writeEntries(Map<String, Object?> entries) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return true;
    }
    try {
      final result = await _channel.invokeMethod<bool>('writeState', <String, Object?>{
        'entries': entries,
      });
      return result ?? false;
    } catch (_) {
      return false;
    }
  }
}
