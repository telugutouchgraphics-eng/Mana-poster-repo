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
      final converted = TeluguLegacyOfflineConverter.convert(
        normalized,
        trailingRaVattu: usesTrailingRaVattu(fontFamily),
        trailingKsaTtaVattu: usesTrailingKsaTtaVattu(fontFamily),
      );
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
        .replaceAll(RegExp('\u0C4D{2,}'), '\u0C4D')
        .trim();
  }

  static String _profileFor(String fontFamily) {
    final rakaram = usesTrailingRaVattu(fontFamily) ? 'trailing' : 'leading';
    final ksaTta = usesTrailingKsaTtaVattu(fontFamily)
        ? 'andhra-kst'
        : 'separated-kst';
    final baseProfile = switch (fontFamily) {
      'Pragathi' || 'Brahma' || 'Pridhvi' || 'Kranthi' => 'name',
      'Pallavi Medium' || 'Pallavi Bold' || 'Pallavi Thin' => 'pallavi',
      _ => fontFamily,
    };
    return '$baseProfile::$rakaram::$ksaTta';
  }

  static bool usesTrailingRaVattu(String fontFamily) {
    switch (fontFamily) {
      case 'Aaradhana':
      case 'Amrutha':
      case 'Bapu Brush':
      case 'Bapu Bold':
      case 'Bapu Script':
      case 'Brahma Script':
      case 'Chandra Script':
      case 'Kusuma':
      case 'Maanasa':
      case 'Madhubala':
      case 'Ramana Brush':
      case 'Ramana Script':
      case 'Ramana Script Medium':
      case 'Saagari':
      case 'Subhadra':
        return true;
      default:
        return false;
    }
  }

  static bool usesTrailingKsaTtaVattu(String fontFamily) {
    return false;
  }
}
