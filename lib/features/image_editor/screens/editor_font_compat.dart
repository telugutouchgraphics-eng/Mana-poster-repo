part of 'image_editor_screen.dart';

const String _legacyFontFallbackFamily = 'Anek Telugu Condensed Regular';

const Set<String> _unicodeTeluguFontFamilies = <String>{
  'Anek Telugu Condensed Regular',
  'Anek Telugu Condensed Bold',
  'Anek Telugu Condensed Extra Bold',
  'Anek Telugu Condensed Extra Light',
  'Anek Telugu Condensed Light',
  'Anek Telugu Condensed Medium',
  'Noto Sans Telugu Condensed Black',
  'Noto Sans Telugu Condensed Bold',
  'Noto Sans Telugu Condensed Extra Bold',
  'Noto Sans Telugu Condensed Extra Light',
  'Noto Sans Telugu Condensed Light',
};

enum _LegacyFontProfile { generic, pragathi, pallavi, preethi }

typedef _LegacyFontConverter = String Function(String value);

const Map<String, _LegacyFontConverter> _legacyFontConverters =
    <String, _LegacyFontConverter>{};
final Map<String, String> _legacyConversionCache = <String, String>{};
bool _legacyConversionCacheLoaded = false;
Future<void>? _legacyConversionCacheLoadFuture;
Timer? _legacyConversionCachePersistTimer;

const Map<String, _LegacyFontProfile> _legacyFontProfiles =
    <String, _LegacyFontProfile>{
      'Pragathi': _LegacyFontProfile.pragathi,
      'Pragathi Italic': _LegacyFontProfile.pragathi,
      'Pragathi Narrow': _LegacyFontProfile.pragathi,
      'Pragathi Special': _LegacyFontProfile.pragathi,
      'Pallavi Bold': _LegacyFontProfile.pallavi,
      'Pallavi Medium': _LegacyFontProfile.pallavi,
      'Pallavi Thin': _LegacyFontProfile.pallavi,
      'Preethi': _LegacyFontProfile.preethi,
    };

_LegacyFontProfile _legacyFontProfileForFamily(String family) =>
    _legacyFontProfiles[family] ?? _LegacyFontProfile.generic;

List<String> _legacyFamiliesForProfile(_LegacyFontProfile profile) {
  switch (profile) {
    case _LegacyFontProfile.pragathi:
      return const <String>[
        'Pragathi',
        'Pragathi Italic',
        'Pragathi Narrow',
        'Pragathi Special',
      ];
    case _LegacyFontProfile.pallavi:
      return const <String>['Pallavi Bold', 'Pallavi Medium', 'Pallavi Thin'];
    case _LegacyFontProfile.preethi:
      return const <String>['Preethi'];
    case _LegacyFontProfile.generic:
      return const <String>[];
  }
}

const List<String> _priorityLegacyPrewarmFonts = <String>[
  'Pragathi',
  'Pragathi Italic',
  'Pragathi Narrow',
  'Pragathi Special',
  'Pallavi Bold',
  'Pallavi Medium',
  'Pallavi Thin',
  'Preethi',
];

bool _legacyProfileUsesModernOutput(_LegacyFontProfile profile) {
  switch (profile) {
    case _LegacyFontProfile.pragathi:
    case _LegacyFontProfile.pallavi:
    case _LegacyFontProfile.preethi:
    case _LegacyFontProfile.generic:
      return true;
  }
}

Future<File> _legacyConversionCacheFile() async {
  final directory = await getApplicationSupportDirectory();
  return File(
    '${directory.path}${Platform.pathSeparator}editor_legacy_font_cache.json',
  );
}

Future<void> _ensureLegacyConversionCacheLoaded() async {
  if (_legacyConversionCacheLoaded) {
    return;
  }
  final inFlight = _legacyConversionCacheLoadFuture;
  if (inFlight != null) {
    await inFlight;
    return;
  }
  _legacyConversionCacheLoadFuture = () async {
    try {
      final file = await _legacyConversionCacheFile();
      if (!await file.exists()) {
        return;
      }
      final raw = await file.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return;
      }
      for (final entry in decoded.entries) {
        final key = entry.key;
        final value = entry.value;
        if (key is String && value is String && value.isNotEmpty) {
          _legacyConversionCache[key] = value;
        }
      }
    } catch (_) {
      _legacyConversionCache.clear();
    } finally {
      _legacyConversionCacheLoaded = true;
      _legacyConversionCacheLoadFuture = null;
    }
  }();
  await _legacyConversionCacheLoadFuture;
}

void _scheduleLegacyConversionCachePersist() {
  _legacyConversionCachePersistTimer?.cancel();
  _legacyConversionCachePersistTimer = Timer(
    const Duration(milliseconds: 250),
    () async {
      try {
        final file = await _legacyConversionCacheFile();
        await file.writeAsString(
          jsonEncode(_legacyConversionCache),
          flush: true,
        );
      } catch (_) {
        // Ignore cache persistence failures; rendering should keep working.
      }
    },
  );
}

bool _isLegacyTeluguFontFamily(String family) =>
    _textFontFamilies.contains(family) &&
    !_unicodeTeluguFontFamilies.contains(family);

bool _hasLegacyTeluguConverter(String family) =>
    _legacyFontConverters.containsKey(family);

String _resolveTextRenderFontFamily(String family) {
  if (_isLegacyTeluguFontFamily(family) && !_hasLegacyTeluguConverter(family)) {
    return _legacyFontFallbackFamily;
  }
  return family;
}

String _resolveTextRenderValue({
  required String text,
  required String fontFamily,
}) {
  final converter = _legacyFontConverters[fontFamily];
  if (converter == null) {
    return text;
  }
  return converter(text);
}

String _resolveLayerRenderText(_CanvasLayer layer) {
  if (layer.legacyRenderText != null && layer.legacyRenderText!.isNotEmpty) {
    return layer.legacyRenderText!;
  }
  return _resolveTextRenderValue(
    text: layer.text ?? 'Text',
    fontFamily: layer.fontFamily,
  );
}

String _resolveLayerRenderFontFamily(_CanvasLayer layer) {
  if (layer.legacyRenderText != null && layer.legacyRenderText!.isNotEmpty) {
    return layer.fontFamily;
  }
  return _resolveTextRenderFontFamily(layer.fontFamily);
}

String _fontPickerSecondaryLabel(String family) {
  if (_unicodeTeluguFontFamilies.contains(family)) {
    return 'Unicode';
  }
  if (_isLegacyTeluguFontFamily(family)) {
    return switch (_legacyFontProfileForFamily(family)) {
      _LegacyFontProfile.pragathi => 'Legacy auto: Pragathi',
      _LegacyFontProfile.pallavi => 'Legacy auto: Pallavi',
      _LegacyFontProfile.preethi => 'Legacy auto: Preethi',
      _LegacyFontProfile.generic => 'Legacy auto',
    };
  }
  return '';
}

String _normalizeUnicodeForLegacyProfile(
  String text,
  _LegacyFontProfile profile,
) {
  var value = text
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .replaceAll('\u200c', '')
      .replaceAll('\u200d', '');
  switch (profile) {
    case _LegacyFontProfile.pragathi:
    case _LegacyFontProfile.pallavi:
    case _LegacyFontProfile.preethi:
    case _LegacyFontProfile.generic:
      return value;
  }
}

Future<String?> _fetchLegacyConvertedText(
  String text, {
  required String fontFamily,
  bool replaceSpaces = false,
}) async {
  final profile = _legacyFontProfileForFamily(fontFamily);
  final normalized = _normalizeUnicodeForLegacyProfile(text, profile).trim();
  if (normalized.isEmpty) {
    return text;
  }
  await _ensureLegacyConversionCacheLoaded();
  final outputMode = _legacyProfileUsesModernOutput(profile)
      ? 'modern'
      : 'legacy';
  final cacheKey = '${profile.name}::$outputMode::$fontFamily::$normalized';
  final cached = _legacyConversionCache[cacheKey];
  if (cached != null) {
    return cached;
  }
  for (final siblingFamily in _legacyFamiliesForProfile(profile)) {
    final siblingKey =
        '${profile.name}::$outputMode::$siblingFamily::$normalized';
    final siblingCached = _legacyConversionCache[siblingKey];
    if (siblingCached != null) {
      _legacyConversionCache[cacheKey] = siblingCached;
      return siblingCached;
    }
  }

  final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
  try {
    final convertRequest = await client.postUrl(
      Uri.parse('https://www.andhracode.com/api/convert'),
    );
    convertRequest.headers.contentType = ContentType(
      'application',
      'x-www-form-urlencoded',
      charset: 'utf-8',
    );
    final convertBody =
        'input=${Uri.encodeQueryComponent(normalized)}'
        '&replaceSpaces=$replaceSpaces'
        '&mapping=mappingA.json'
        '&commentOutLines=true'
        '&commentOutLineList=';
    convertRequest.write(convertBody);
    final convertResponse = await convertRequest.close();
    if (convertResponse.statusCode < 200 || convertResponse.statusCode >= 300) {
      return null;
    }
    final modernOutput = await utf8.decodeStream(convertResponse);
    if (modernOutput.trim().isEmpty) {
      return null;
    }

    if (_legacyProfileUsesModernOutput(profile)) {
      _legacyConversionCache[cacheKey] = modernOutput;
      for (final siblingFamily in _legacyFamiliesForProfile(profile)) {
        _legacyConversionCache['${profile.name}::$outputMode::$siblingFamily::$normalized'] =
            modernOutput;
      }
      _scheduleLegacyConversionCachePersist();
      return modernOutput;
    }

    final legacyRequest = await client.postUrl(
      Uri.parse('https://www.andhracode.com/api/legacy-convert'),
    );
    legacyRequest.headers.contentType = ContentType(
      'application',
      'x-www-form-urlencoded',
      charset: 'utf-8',
    );
    legacyRequest.write('input=${Uri.encodeQueryComponent(modernOutput)}');
    final legacyResponse = await legacyRequest.close();
    if (legacyResponse.statusCode < 200 || legacyResponse.statusCode >= 300) {
      return null;
    }
    final legacyOutput = await utf8.decodeStream(legacyResponse);
    if (legacyOutput.isEmpty) {
      return null;
    }
    _legacyConversionCache[cacheKey] = legacyOutput;
    for (final siblingFamily in _legacyFamiliesForProfile(profile)) {
      _legacyConversionCache['${profile.name}::$outputMode::$siblingFamily::$normalized'] =
          legacyOutput;
    }
    _scheduleLegacyConversionCachePersist();
    return legacyOutput;
  } catch (_) {
    return null;
  } finally {
    client.close(force: true);
  }
}

bool _hasCachedLegacyRenderText({
  required String text,
  required String fontFamily,
}) {
  if (!_isLegacyTeluguFontFamily(fontFamily)) {
    return false;
  }
  final profile = _legacyFontProfileForFamily(fontFamily);
  final normalized = _normalizeUnicodeForLegacyProfile(text, profile).trim();
  if (normalized.isEmpty) {
    return false;
  }
  final outputMode = _legacyProfileUsesModernOutput(profile)
      ? 'modern'
      : 'legacy';
  final cacheKey = '${profile.name}::$outputMode::$fontFamily::$normalized';
  if (_legacyConversionCache.containsKey(cacheKey)) {
    return true;
  }
  for (final siblingFamily in _legacyFamiliesForProfile(profile)) {
    if (_legacyConversionCache.containsKey(
      '${profile.name}::$outputMode::$siblingFamily::$normalized',
    )) {
      return true;
    }
  }
  return false;
}

Future<String?> _resolveLegacyRenderTextFor({
  required String text,
  required String fontFamily,
}) async {
  if (!_isLegacyTeluguFontFamily(fontFamily)) {
    return null;
  }
  final converted = _hasLegacyTeluguConverter(fontFamily)
      ? _resolveTextRenderValue(text: text, fontFamily: fontFamily)
      : await _fetchLegacyConvertedText(text, fontFamily: fontFamily);
  if (converted == null || converted.isEmpty) {
    return null;
  }
  return converted;
}

Future<void> _prewarmLegacyFontsForText(
  String text, {
  Iterable<String>? preferredFamilies,
}) async {
  final normalized = text.trim();
  if (normalized.isEmpty) {
    return;
  }
  final queue = <String>{};
  if (preferredFamilies != null) {
    queue.addAll(preferredFamilies.where(_isLegacyTeluguFontFamily));
  }
  queue.addAll(_priorityLegacyPrewarmFonts);
  for (final family in queue) {
    await _resolveLegacyRenderTextFor(text: normalized, fontFamily: family);
  }
}

extension _EditorFontCompatState on _ImageEditorScreenState {
  Future<void> _refreshLayerLegacyRenderText(
    String layerId, {
    bool clearImmediately = false,
  }) async {
    final index = _layers.indexWhere((item) => item.id == layerId);
    if (index == -1 || !_layers[index].isText) {
      return;
    }
    final layer = _layers[index];
    if (!_isLegacyTeluguFontFamily(layer.fontFamily)) {
      if (layer.legacyRenderText != null && mounted) {
        setState(() {
          final refreshedIndex = _layers.indexWhere(
            (item) => item.id == layerId,
          );
          if (refreshedIndex != -1 && _layers[refreshedIndex].isText) {
            _layers[refreshedIndex] = _layers[refreshedIndex].copyWith(
              legacyRenderText: null,
            );
          }
        });
      }
      return;
    }

    if (clearImmediately && mounted) {
      setState(() {
        final refreshedIndex = _layers.indexWhere((item) => item.id == layerId);
        if (refreshedIndex != -1 && _layers[refreshedIndex].isText) {
          _layers[refreshedIndex] = _layers[refreshedIndex].copyWith(
            legacyRenderText: null,
          );
        }
      });
    }

    final sourceText = layer.text ?? '';
    final sourceFont = layer.fontFamily;
    final converted = await _resolveLegacyRenderTextFor(
      text: sourceText,
      fontFamily: sourceFont,
    );
    if (!mounted) {
      return;
    }
    final refreshedIndex = _layers.indexWhere((item) => item.id == layerId);
    if (refreshedIndex == -1 || !_layers[refreshedIndex].isText) {
      return;
    }
    final refreshedLayer = _layers[refreshedIndex];
    if ((refreshedLayer.text ?? '') != sourceText ||
        refreshedLayer.fontFamily != sourceFont) {
      return;
    }
    if (refreshedLayer.legacyRenderText == converted) {
      return;
    }
    setState(() {
      _layers[refreshedIndex] = refreshedLayer.copyWith(
        legacyRenderText: converted,
      );
    });
  }
}
