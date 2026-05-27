import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class InstallSourceService {
  InstallSourceService._();

  static const MethodChannel _channel = MethodChannel(
    'mana_poster/install_source',
  );

  static bool? _cachedTrustedPlayInstall;

  static Future<bool> isTrustedPlayInstall() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    final cached = _cachedTrustedPlayInstall;
    if (cached != null) {
      return cached;
    }
    try {
      final trusted =
          await _channel.invokeMethod<bool>('isTrustedPlayInstall') ?? false;
      _cachedTrustedPlayInstall = trusted;
      return trusted;
    } on PlatformException {
      _cachedTrustedPlayInstall = false;
      return false;
    } on MissingPluginException {
      _cachedTrustedPlayInstall = false;
      return false;
    }
  }
}
