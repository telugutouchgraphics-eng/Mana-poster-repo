import 'dart:convert';
import 'dart:io';

class TeluguLegacyTextService {
  TeluguLegacyTextService._();

  static final Map<String, String> _cache = <String, String>{};

  static Future<String?> convert(
    String text, {
    required String fontFamily,
  }) async {
    final normalized = text
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll('\u200c', '')
        .replaceAll('\u200d', '')
        .trim();
    if (normalized.isEmpty) {
      return normalized;
    }

    final profile = _profileFor(fontFamily);
    final cacheKey = '$profile::$normalized';
    final cached = _cache[cacheKey];
    if (cached != null) {
      return cached;
    }

    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      final request = await client.postUrl(
        Uri.parse('https://www.andhracode.com/api/convert'),
      );
      request.headers.contentType = ContentType(
        'application',
        'x-www-form-urlencoded',
        charset: 'utf-8',
      );
      request.write(
        'input=${Uri.encodeQueryComponent(normalized)}'
        '&replaceSpaces=false'
        '&mapping=mappingA.json'
        '&commentOutLines=true'
        '&commentOutLineList=',
      );
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }
      final converted = await utf8.decodeStream(response);
      if (converted.trim().isEmpty) {
        return null;
      }
      _cache[cacheKey] = converted;
      return converted;
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
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
