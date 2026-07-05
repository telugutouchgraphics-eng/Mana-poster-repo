import 'package:mana_poster/features/prehome/services/telugu_legacy_offline_converter.dart';

class TeluguLegacyTextService {
  TeluguLegacyTextService._();

  static final Map<String, String> _cache = <String, String>{};

  static Future<String?> convert(
    String text, {
    required String fontFamily,
  }) async {
    return convertSync(text, fontFamily: fontFamily);
  }

  static String? convertSync(String text, {required String fontFamily}) {
    final normalized = _normalize(text);
    if (normalized.isEmpty) {
      return normalized;
    }

    final profile = _profileFor(fontFamily);
    final cacheKey = '$profile::$normalized';
    final cached = _cache[cacheKey];
    if (cached != null) {
      return cached;
    }

    try {
      final converted = TeluguLegacyOfflineConverter.convert(normalized);
      if (converted.trim().isEmpty) {
        return null;
      }
      _cache[cacheKey] = converted;
      return converted;
    } catch (_) {
      return null;
    }
  }

  static String reverseConvertSync(String text) {
    final normalized = _normalize(text);
    if (normalized.isEmpty) {
      return normalized;
    }
    try {
      return TeluguLegacyOfflineConverter.reverseConvert(normalized);
    } catch (_) {
      return normalized;
    }
  }

  static String? cachedValue(String text, {required String fontFamily}) {
    final normalized = _normalize(text);
    if (normalized.isEmpty) {
      return normalized;
    }
    final profile = _profileFor(fontFamily);
    return _cache['$profile::$normalized'];
  }

  static String _normalize(String text) {
    return text
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll('\u200c', '')
        .replaceAll('\u200d', '')
        .trim();
  }

  static String _profileFor(String fontFamily) {
    switch (fontFamily) {
      case 'Pragathi':
      case 'Brahma':
      case 'Pridhvi':
      case 'Kranthi':
        return 'name';
      case 'Pallavi Medium':
      case 'Pallavi Bold':
      case 'Pallavi Thin':
        return 'pallavi';
      default:
        return fontFamily;
    }
  }
}
