import 'dart:convert';

class TeluguLegacyOfflineConverter {
  TeluguLegacyOfflineConverter._();

  static final RegExp _teluguPattern = RegExp(r'[\u0C00-\u0C7F]');
  static final RegExp _legacyGlyphPattern = RegExp(r'[\uE000-\uF8FF]');
  static _LegacyMapping? _mapping;
  static _ReverseLegacyMapping? _reverseMapping;

  static String convert(String text) {
    final normalized = _normalize(text);
    if (normalized.isEmpty || !_teluguPattern.hasMatch(normalized)) {
      return normalized;
    }
    final mapping = _loadMapping();
    final runes = normalized.runes.toList(growable: false);
    final out = StringBuffer();
    var i = 0;
    while (i < runes.length) {
      final code = runes[i];
      if (code < 0x0C00 || code > 0x0C7F) {
        out.writeCharCode(code);
        i += 1;
        continue;
      }

      final vowel = mapping.vowels[code];
      if (vowel != null) {
        out.write(String.fromCharCodes(vowel));
        i += 1;
        continue;
      }

      final consonant = mapping.consonants[code];
      if (consonant == null) {
        out.writeCharCode(code);
        i += 1;
        continue;
      }

      final next = i + 1 < runes.length ? runes[i + 1] : null;
      if (next == _virama) {
        final extensionCode = i + 2 < runes.length ? runes[i + 2] : null;
        final vowelSignAfterExtension = i + 3 < runes.length
            ? runes[i + 3]
            : null;
        final extension = extensionCode == null
            ? null
            : mapping.extensions[extensionCode];
        if (extensionCode != null &&
            extension != null &&
            _isExtensionTrailingSign(vowelSignAfterExtension)) {
          final symbol =
              consonant.symbols[vowelSignAfterExtension!] ?? consonant.base;
          final combined = extensionCode == _ra
              ? <int>[...extension, ...symbol]
              : <int>[...symbol, ...extension];
          out.write(String.fromCharCodes(combined));
          i += 4;
          continue;
        }
        if (extensionCode != null &&
            extension != null &&
            mapping.consonants.containsKey(extensionCode)) {
          final combined = extensionCode == _ra
              ? <int>[...extension, ...consonant.base]
              : <int>[...consonant.base, ...extension];
          out.write(String.fromCharCodes(combined));
          i += vowelSignAfterExtension == _virama ? 4 : 3;
          continue;
        }
        out.write(
          String.fromCharCodes(consonant.symbols[_virama] ?? consonant.base),
        );
        i += 2;
        continue;
      }

      if (_isVowelSign(next)) {
        out.write(
          String.fromCharCodes(consonant.symbols[next!] ?? consonant.base),
        );
        i += 2;
        continue;
      }

      out.write(String.fromCharCodes(consonant.base));
      i += 1;
    }
    return out.toString();
  }

  static String reverseConvert(String text) {
    final normalized = _normalize(text);
    if (normalized.isEmpty || !_legacyGlyphPattern.hasMatch(normalized)) {
      return normalized;
    }
    final reverse = _loadReverseMapping();
    final direct = _decodeLegacyText(normalized, reverse, promoteAscii: false);
    final promoted = _decodeLegacyText(normalized, reverse, promoteAscii: true);
    final best = promoted.score > direct.score ? promoted : direct;
    if (best.convertedGlyphs == 0 || !_teluguPattern.hasMatch(best.text)) {
      return normalized;
    }
    return best.text;
  }

  static _LegacyDecodeResult _decodeLegacyText(
    String normalized,
    _ReverseLegacyMapping reverse, {
    required bool promoteAscii,
  }) {
    final source = promoteAscii
        ? _promotePsdAsciiLegacyGlyphs(normalized, reverse)
        : _LegacyPromotedText(normalized, null);
    final out = StringBuffer();
    var index = 0;
    var convertedGlyphs = 0;

    while (index < source.text.length) {
      String? replacement;
      var matchedLength = 0;
      for (final token in reverse.tokensByLength) {
        if (index + token.length > source.text.length) {
          continue;
        }
        if (source.text.startsWith(token, index)) {
          replacement = reverse.values[token];
          matchedLength = token.length;
          break;
        }
      }
      if (replacement != null && matchedLength > 0) {
        out.write(replacement);
        convertedGlyphs += matchedLength;
        index += matchedLength;
        continue;
      }
      out.write(source.originalCharAt(index));
      index += 1;
    }

    final converted = out.toString();
    return _LegacyDecodeResult(
      converted,
      convertedGlyphs,
      _teluguPattern.allMatches(converted).length,
    );
  }

  static _LegacyPromotedText _promotePsdAsciiLegacyGlyphs(
    String text,
    _ReverseLegacyMapping reverse,
  ) {
    final promoted = StringBuffer();
    final originals = <String>[];
    for (var index = 0; index < text.length; index += 1) {
      final code = text.codeUnitAt(index);
      if (code >= 0x21 && code <= 0x7E) {
        final legacy = String.fromCharCode(0xF000 + code);
        if (reverse.hasTokenGlyph(legacy)) {
          promoted.write(legacy);
          originals.add(text[index]);
          continue;
        }
      }
      promoted.write(text[index]);
      originals.add(text[index]);
    }
    return _LegacyPromotedText(promoted.toString(), originals);
  }

  static String _normalize(String text) {
    return text
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll('\u200c', '')
        .replaceAll('\u200d', '')
        .trim();
  }

  static bool _isVowelSign(int? code) =>
      code != null && code >= 0x0C3E && code <= 0x0C4C;

  static bool _isExtensionTrailingSign(int? code) =>
      code != null && code >= 0x0C3E && code <= 0x0C4E;

  static _LegacyMapping _loadMapping() {
    final current = _mapping;
    if (current != null) {
      return current;
    }
    final decoded =
        jsonDecode(utf8.decode(base64Decode(_mappingData)))
            as Map<String, dynamic>;
    _mapping = _LegacyMapping.fromJson(decoded);
    return _mapping!;
  }

  static _ReverseLegacyMapping _loadReverseMapping() {
    final current = _reverseMapping;
    if (current != null) {
      return current;
    }
    final values = <String, String>{};
    void add(String legacy, String unicode) {
      if (legacy.isEmpty || unicode.isEmpty || legacy == unicode) {
        return;
      }
      values.putIfAbsent(legacy, () => unicode);
    }

    final mapping = _loadMapping();
    for (final entry in mapping.vowels.entries) {
      add(String.fromCharCodes(entry.value), String.fromCharCode(entry.key));
    }
    for (final entry in mapping.extensions.entries) {
      add(String.fromCharCodes(entry.value), String.fromCharCode(entry.key));
    }
    for (final entry in mapping.consonants.entries) {
      final consonantCode = entry.key;
      final consonant = entry.value;
      final base = String.fromCharCode(consonantCode);
      add(String.fromCharCodes(consonant.base), base);
      for (final symbolEntry in consonant.symbols.entries) {
        final sign = symbolEntry.key;
        final unicode = sign == _virama
            ? String.fromCharCodes(<int>[consonantCode, _virama])
            : String.fromCharCodes(<int>[consonantCode, sign]);
        add(String.fromCharCodes(symbolEntry.value), unicode);
      }
      for (final sign in _vowelSigns) {
        add(
          convert('$base${String.fromCharCode(sign)}'),
          '$base${String.fromCharCode(sign)}',
        );
      }
    }

    final consonants = mapping.consonants.keys.toList(growable: false);
    final signs = <int?>[null, _virama, ..._vowelSigns];
    for (final first in consonants) {
      for (final second in consonants) {
        for (final sign in signs) {
          final codes = <int>[first, _virama, second];
          if (sign != null) {
            codes.add(sign);
          }
          final unicode = String.fromCharCodes(codes);
          add(convert(unicode), unicode);
        }
      }
    }
    _addPsdLegacyAliases(add);

    final tokens = values.keys.toList(growable: false)
      ..sort((a, b) {
        final lengthCompare = b.length.compareTo(a.length);
        if (lengthCompare != 0) {
          return lengthCompare;
        }
        return a.compareTo(b);
      });
    _reverseMapping = _ReverseLegacyMapping(values, tokens);
    return _reverseMapping!;
  }

  static void _addPsdLegacyAliases(void Function(String, String) add) {
    String legacy(List<int> codes) => String.fromCharCodes(codes);

    add(legacy(<int>[0xF0BF, 0xF0A3, 0xF0D8]), 'క్క');
    add(legacy(<int>[0xF0BF, 0xF0A3]), 'క');
    add(legacy(<int>[0xF0BF, 0xF0B1]), 'కా');
    add(legacy(<int>[0xF0BF, 0xF0EC, 0xF08C]), 'క్షి');
    add(legacy(<int>[0xF0C5, 0xF0A3, 0xF094]), 'కు');
    add(legacy(<int>[0xF073, 0xF0C1]), 'ర');
  }

  static const int _virama = 0x0C4D;
  static const int _ra = 0x0C30;
  static const List<int> _vowelSigns = <int>[
    0x0C3E,
    0x0C3F,
    0x0C40,
    0x0C41,
    0x0C42,
    0x0C43,
    0x0C44,
    0x0C46,
    0x0C47,
    0x0C48,
    0x0C4A,
    0x0C4B,
    0x0C4C,
  ];

  static const String _mappingData =
      'eyJ2b3dlbHMiOnsiMzA3NCI6WzYxNDgzXSwiMzA3NyI6WzYxNTUwXSwiMzA3OCI6WzYxNTY4XSwiMzA3OSI6WzYxNTcwXSwiMzA4'
      'MCI6WzYxNTc1XSwiMzA4MSI6WzYxNTkwXSwiMzA4MiI6WzYxNTY1XSwiMzA4NiI6WzYxNTM4XSwiMzA4NyI6WzYxNTA0XSwiMzA4'
      'OCI6WzYxNjU1XSwiMzA5MCI6WzYxNjk1XSwiMzA5MSI6WzYxNTYyXSwiMzA5MiI6WzYxNTI3XX0sImV4dGVuc2lvbnMiOnsiMzA5'
      'MyI6WzYxNjU2XSwiMzA5NCI6WzYxNTc3XSwiMzA5NSI6WzYxNTMwXSwiMzA5NiI6WzYxNjczXSwiMzA5NyI6WzYxNTM1XSwiMzA5'
      'OCI6WzYxNjQ0XSwiMzA5OSI6WzYxNjQ0LDYxNjU5XSwiMzEwMCI6WzYxNjA4XSwiMzEwMSI6WzYxNTM1XSwiMzEwMiI6WzYxNjY3'
      'XSwiMzEwMyI6WzYxNjI4XSwiMzEwNCI6WzYxNjg3XSwiMzEwNSI6WzYxNjA2XSwiMzEwNiI6WzYxNTM1XSwiMzEwNyI6WzYxNTg2'
      'XSwiMzEwOCI6WzYxNjc5XSwiMzEwOSI6WzYxNTk2XSwiMzExMCI6WzYxNjYxXSwiMzExMSI6WzYxNjM4XSwiMzExMiI6WzYxNTg5'
      'XSwiMzExMyI6W10sIjMxMTQiOls2MTY0Nl0sIjMxMTUiOls2MTY0Niw2MTY1OV0sIjMxMTYiOls2MTY1MF0sIjMxMTciOls2MTY1'
      'MCw2MTY1OV0sIjMxMTgiOls2MTU3Nl0sIjMxMTkiOls2MTYxMV0sIjMxMjAiOls2MTY3MV0sIjMxMjEiOls2MTUzNV0sIjMxMjIi'
      'Ols2MTYwMl0sIjMxMjMiOls2MTY2M10sIjMxMjQiOltdLCIzMTI1IjpbNjE2MzldLCIzMTI2IjpbNjE2ODRdLCIzMTI3IjpbNjE2'
      'OTJdLCIzMTI4IjpbNjE2NjRdLCIzMTI5IjpbNjE2MjldfSwiY29uc29uYW50cyI6eyIzMDkzIjp7ImJhc2UiOls2MTYzNyw2MTYy'
      'M10sInN5bWJvbHMiOnsiMzEzNCI6WzYxNjM3LDYxNTg1XSwiMzEzNSI6WzYxNjM3LDYxNTgxXSwiMzEzNiI6WzYxNjM3LDYxNjAx'
      'XSwiMzEzNyI6WzYxNjM3LDYxNjIzLDYxNTg4XSwiMzEzOCI6WzYxNjM3LDYxNjIzLDYxNTE2XSwiMzE0MiI6WzYxNjM0LDYxNjMx'
      'XSwiMzE0MyI6WzYxNjI1LDYxNjMxXSwiMzE0NCI6WzYxNjM0LDYxNjMxLDYxNjUzXSwiMzE0NiI6WzYxNjMxLDYxNTAxXSwiMzE0'
      'NyI6WzYxNjMxLDYxNjM1XSwiMzE0OCI6WzYxNjMxLDYxNTk0XSwiMzE0OSI6WzYxNjMxLDYxNjg5XX19LCIzMDk0Ijp7ImJhc2Ui'
      'Ols2MTUxNV0sInN5bWJvbHMiOnsiMzEzNCI6WzYxNTI1LDYxNjE4XSwiMzEzNSI6WzYxNjQ3XSwiMzEzNiI6WzYxNTEwXSwiMzEz'
      'NyI6WzYxNTE1LDYxNTI0XSwiMzEzOCI6WzYxNTE1LDYxNjU0XSwiMzE0MiI6WzYxNTI1LDYxNjQxLDYxNjUzXSwiMzE0MyI6WzYx'
      'NTI1LDYxNjgxXSwiMzE0NCI6WzYxNTI1LDYxNjQxLDYxNjUzXSwiMzE0NiI6WzYxNTI1LDYxNjA0XSwiMzE0NyI6WzYxNTI1LDYx'
      'NjQzXSwiMzE0OCI6WzYxNTI1LDYxNTczXSwiMzE0OSI6WzYxNTI1LDYxNjU3XX19LCIzMDk1Ijp7ImJhc2UiOls2MTUwMiw2MTYy'
      'M10sInN5bWJvbHMiOnsiMzEzNCI6WzYxNTAyLDYxNjE3XSwiMzEzNSI6WzYxNjQ4XSwiMzEzNiI6WzYxNTM0XSwiMzEzNyI6WzYx'
      'NTAyLDYxNjIzLDYxNTI0XSwiMzEzOCI6WzYxNTAyLDYxNjIzLDYxNjU0XSwiMzE0MiI6WzYxNjM0LDYxNTAyXSwiMzE0MyI6WzYx'
      'NjI1LDYxNTAyXSwiMzE0NCI6WzYxNjM0LDYxNTAyLDYxNjUzXSwiMzE0NiI6WzYxNTAyLDYxNTAxXSwiMzE0NyI6WzYxNTAyLDYx'
      'NjM1XSwiMzE0OCI6WzYxNTAyLDYxNTk0XSwiMzE0OSI6WzYxNTAyLDYxNjIwXX19LCIzMDk2Ijp7ImJhc2UiOls2MTU2NCw2MTU5'
      'Miw2MTU5OSw2MTUyNF0sInN5bWJvbHMiOnsiMzEzNCI6WzYxNTY0LDYxNTkyLDYxNTk5LDYxNjU0XSwiMzEzNSI6WzYxNTY0LDYx'
      'NTkyLDYxNjMwLDYxNTI0XSwiMzEzNiI6WzYxNTY0LDYxNTkyLDYxNjUxLDYxNTI0XSwiMzEzNyI6WzYxNTY0LDYxNTkyLDYxNTk5'
      'LDYxNTI0LDYxNTI0XSwiMzEzOCI6WzYxNTY0LDYxNTkyLDYxNTk5LDYxNTI0LDYxNjU0XSwiMzE0MiI6WzYxNTkzLDYxNTY0LDYx'
      'NTkyLDYxNTI0XSwiMzE0MyI6WzYxNTk3LDYxNTY0LDYxNTkyLDYxNTI0XSwiMzE0NCI6WzYxNTkzLDYxNTY0LDYxNTkyLDYxNTI0'
      'LDYxNjE0XSwiMzE0NiI6WzYxNTY0LDYxNTkyLDYxNTk5LDYxNTI0LDYxNjA0XSwiMzE0NyI6WzYxNTY0LDYxNTkyLDYxNTk5LDYx'
      'NTI0LDYxNjQzXSwiMzE0OCI6WzYxNTY0LDYxNTkyLDYxNTk5LDYxNTI0LDYxNjgyXSwiMzE0OSI6WzYxNTY0LDYxNTkyLDYxNTU2'
      'LDYxNTI0XX19LCIzMDk4Ijp7ImJhc2UiOls2MTQ3NSw2MTY2NV0sInN5bWJvbHMiOnsiMzEzNCI6WzYxNDc1LDYxNTg0XSwiMzEz'
      'NSI6WzYxNjI2XSwiMzEzNiI6WzYxNTE4XSwiMzEzNyI6WzYxNDc1LDYxNjY1LDYxNTI0XSwiMzEzOCI6WzYxNDc1LDYxNjY1LDYx'
      'NjU0XSwiMzE0MiI6WzYxNDc1LDYxNjc4XSwiMzE0MyI6WzYxNDc1LDYxNjkxXSwiMzE0NCI6WzYxNDc1LDYxNjc4LDYxNjUzXSwi'
      'MzE0NiI6WzYxNDc1LDYxNTAxXSwiMzE0NyI6WzYxNDc1LDYxNjM1XSwiMzE0OCI6WzYxNDc1LDYxNjc0XSwiMzE0OSI6WzYxNDc1'
      'LDYxNTI5XX19LCIzMDk5Ijp7ImJhc2UiOls2MTQ3NSw2MTY4Myw2MTY2NV0sInN5bWJvbHMiOnsiMzEzNCI6WzYxNDc1LDYxNjgz'
      'LDYxNTg0XSwiMzEzNSI6WzYxNjI2LDYxNjgzXSwiMzEzNiI6WzYxNTE4LDYxNjgzXSwiMzEzNyI6WzYxNDc1LDYxNjgzLDYxNjY1'
      'LDYxNTI0XSwiMzEzOCI6WzYxNDc1LDYxNjgzLDYxNjY1LDYxNjU0XSwiMzE0MiI6WzYxNDc1LDYxNjgzLDYxNjc4XSwiMzE0MyI6'
      'WzYxNDc1LDYxNjgzLDYxNjkxXSwiMzE0NCI6WzYxNDc1LDYxNjgzLDYxNjc4LDYxNjUzXSwiMzE0NiI6WzYxNDc1LDYxNjgzLDYx'
      'NTAxXSwiMzE0NyI6WzYxNDc1LDYxNjgzLDYxNjM1XSwiMzE0OCI6WzYxNDc1LDYxNjgzLDYxNjc0XSwiMzE0OSI6WzYxNDc1LDYx'
      'NjgzLDYxNTI5XX19LCIzMTAwIjp7ImJhc2UiOls2MTY0MF0sInN5bWJvbHMiOnsiMzEzNCI6WzYxNTA3LDYxNjE4XSwiMzEzNSI6'
      'WzYxNTk1XSwiMzEzNiI6WzYxNTE0XSwiMzEzNyI6WzYxNTA5XSwiMzEzOCI6WzYxNTUyXSwiMzE0MiI6WzYxNTA3LDYxNjQxXSwi'
      'MzE0MyI6WzYxNTA3LDYxNjgxXSwiMzE0NCI6WzYxNTA3LDYxNjQxLDYxNjUzXSwiMzE0NiI6WzYxNTA3LDYxNjA0XSwiMzE0NyI6'
      'WzYxNTA3LDYxNjQzXSwiMzE0OCI6WzYxNTA3LDYxNTczXSwiMzE0OSI6WzYxNTA3LDYxNjU3XX19LCIzMTAxIjp7ImJhc2UiOls2'
      'MTU1NSw2MTYzMyw2MTUzN10sInN5bWJvbHMiOnsiMzEzNCI6WzYxNTU1LDYxNjMzLDYxNTM3LDYxNTUwXSwiMzEzNSI6WzYxNTMz'
      'LDYxNTM3XSwiMzEzNiI6WzYxNjE1LDYxNTM3XSwiMzEzNyI6WzYxNTU1LDYxNjMzLDYxNTM3LDYxNTI0XSwiMzEzOCI6WzYxNTU1'
      'LDYxNjMzLDYxNTM3LDYxNjU0XSwiMzE0MiI6WzYxNjM0LDYxNTU1LDYxNTM3XSwiMzE0MyI6WzYxNjI1LDYxNTU1LDYxNTM3XSwi'
      'MzE0NCI6WzYxNjM0LDYxNTU1LDYxNTM3LDYxNjE0XSwiMzE0NiI6WzYxNjM0LDYxNTU1LDYxNTM3LDYxNTI0XSwiMzE0NyI6WzYx'
      'NjM0LDYxNTU1LDYxNTM3LDYxNjE4XSwiMzE0OCI6WzYxNTU1LDYxNjMzLDYxNTM3LDYxNjgyXSwiMzE0OSI6WzYxNTU1LDYxNTI5'
      'LDYxNTM3XX19LCIzMTAzIjp7ImJhc2UiOls2MTU0Ml0sInN5bWJvbHMiOnsiMzEzNCI6WzYxNTYzLDYxNjE4XSwiMzEzNSI6WzYx'
      'NTYzLDYxNjc2XSwiMzEzNiI6WzYxNTYzLDYxNjAxXSwiMzEzNyI6WzYxNjE5LDYxNTI0XSwiMzEzOCI6WzYxNjE5LDYxNjU0XSwi'
      'MzE0MiI6WzYxNTQyLDYxNjQxXSwiMzE0MyI6WzYxNTQyLDYxNjgxXSwiMzE0NCI6WzYxNTQyLDYxNjQxLDYxNjE0XSwiMzE0NiI6'
      'WzYxNTYzLDYxNjA0XSwiMzE0NyI6WzYxNTYzLDYxNjQzXSwiMzE0OCI6WzYxNTYzLDYxNTczXSwiMzE0OSI6WzYxNTYzLDYxNjU3'
      'XX19LCIzMTA0Ijp7ImJhc2UiOls2MTU1NSw2MTYzNiw2MTYzM10sInN5bWJvbHMiOnsiMzEzNCI6WzYxNTU1LDYxNjM2LDYxNTg0'
      'XSwiMzEzNSI6WzYxNTMzLDYxNjM2XSwiMzEzNiI6WzYxNjE1LDYxNjM2XSwiMzEzNyI6WzYxNTU1LDYxNjM2LDYxNjMzLDYxNTI0'
      'XSwiMzEzOCI6WzYxNTU1LDYxNjM2LDYxNjMzLDYxNjU0XSwiMzE0MiI6WzYxNjM0LDYxNTU1LDYxNjM2XSwiMzE0MyI6WzYxNjI1'
      'LDYxNTU1LDYxNjM2XSwiMzE0NCI6WzYxNjM0LDYxNTU1LDYxNjM2LDYxNjUzXSwiMzE0NiI6WzYxNTU1LDYxNjM2LDYxNTAxXSwi'
      'MzE0NyI6WzYxNTU1LDYxNjM2LDYxNjM1XSwiMzE0OCI6WzYxNTU1LDYxNjM2LDYxNTk0XSwiMzE0OSI6WzYxNTU1LDYxNjM2LDYx'
      'NTI5XX19LCIzMTA1Ijp7ImJhc2UiOls2MTQ3OCw2MTY2NV0sInN5bWJvbHMiOnsiMzEzNCI6WzYxNDc4LDYxNTc0XSwiMzEzNSI6'
      'WzYxNDc4LDYxNTgxXSwiMzEzNiI6WzYxNDc4LDYxNTk4XSwiMzEzNyI6WzYxNDc4LDYxNTcxLDYxNTI0XSwiMzEzOCI6WzYxNDc4'
      'LDYxNTcxLDYxNjU0XSwiMzE0MiI6WzYxNDc4LDYxNjc4XSwiMzE0MyI6WzYxNDc4LDYxNjkxXSwiMzE0NCI6WzYxNDc4LDYxNjc4'
      'LDYxNjUzXSwiMzE0NiI6WzYxNDc4LDYxNTAxXSwiMzE0NyI6WzYxNDc4LDYxNjM1XSwiMzE0OCI6WzYxNDc4LDYxNjc0XSwiMzE0'
      'OSI6WzYxNDc4LDYxNTgyXX19LCIzMTA2Ijp7ImJhc2UiOls2MTQ3OCw2MTY4Myw2MTU3MV0sInN5bWJvbHMiOnsiMzEzNCI6WzYx'
      'NDc4LDYxNjgzLDYxNTc0XSwiMzEzNSI6WzYxNDc4LDYxNjgzLDYxNTgxXSwiMzEzNiI6WzYxNDc4LDYxNjgzLDYxNTk4XSwiMzEz'
      'NyI6WzYxNDc4LDYxNjgzLDYxNTcxLDYxNTI0XSwiMzEzOCI6WzYxNDc4LDYxNjgzLDYxNTcxLDYxNjU0XSwiMzE0MiI6WzYxNDc4'
      'LDYxNjgzLDYxNjc4XSwiMzE0MyI6WzYxNDc4LDYxNjgzLDYxNjkxXSwiMzE0NCI6WzYxNDc4LDYxNjgzLDYxNjc4LDYxNjUzXSwi'
      'MzE0NiI6WzYxNDc4LDYxNjgzLDYxNTAxXSwiMzE0NyI6WzYxNDc4LDYxNjgzLDYxNjM1XSwiMzE0OCI6WzYxNDc4LDYxNjgzLDYx'
      'Njc0XSwiMzE0OSI6WzYxNDc4LDYxNjgzLDYxNTgyXX19LCIzMTA3Ijp7ImJhc2UiOls2MTUwOF0sInN5bWJvbHMiOnsiMzEzNCI6'
      'WzYxNTA4LDYxNjE4XSwiMzEzNSI6WzYxNTA4LDYxNjc2XSwiMzEzNiI6WzYxNTA4LDYxNjAxXSwiMzEzNyI6WzYxNTA4LDYxNTI0'
      'XSwiMzEzOCI6WzYxNTA4LDYxNjU0XSwiMzE0MiI6WzYxNTA4LDYxNjQxXSwiMzE0MyI6WzYxNTA4LDYxNjgxXSwiMzE0NCI6WzYx'
      'NTA4LDYxNjQxLDYxNjE0XSwiMzE0NiI6WzYxNTA4LDYxNTAxXSwiMzE0NyI6WzYxNTA4LDYxNjM1XSwiMzE0OCI6WzYxNTA4LDYx'
      'NTczXSwiMzE0OSI6WzYxNTA4LDYxNTI5XX19LCIzMTA4Ijp7ImJhc2UiOls2MTY1Miw2MTY2NV0sInN5bWJvbHMiOnsiMzEzNCI6'
      'WzYxNjUyLDYxNTg0XSwiMzEzNSI6WzYxNjYwXSwiMzEzNiI6WzYxNTU0XSwiMzEzNyI6WzYxNjUyLDYxNjY1LDYxNTI0XSwiMzEz'
      'OCI6WzYxNjUyLDYxNjY1LDYxNjU0XSwiMzE0MiI6WzYxNjUyLDYxNjc4XSwiMzE0MyI6WzYxNjUyLDYxNjkxXSwiMzE0NCI6WzYx'
      'NjUyLDYxNjc4LDYxNjUzXSwiMzE0NiI6WzYxNjUyLDYxNTAxXSwiMzE0NyI6WzYxNjUyLDYxNjM1XSwiMzE0OCI6WzYxNjUyLDYx'
      'Njc0XSwiMzE0OSI6WzYxNjUyLDYxNTI5XX19LCIzMTA5Ijp7ImJhc2UiOls2MTUwMCw2MTYyNCw2MTY2NV0sInN5bWJvbHMiOnsi'
      'MzEzNCI6WzYxNTAwLDYxNjI0LDYxNTg1XSwiMzEzNSI6WzYxNTY2LDYxNjI0XSwiMzEzNiI6WzYxNTA2LDYxNjI0XSwiMzEzNyI6'
      'WzYxNTAwLDYxNjI0LDYxNTc4LDYxNTI0XSwiMzEzOCI6WzYxNTAwLDYxNjI0LDYxNTc4LDYxNjU0XSwiMzE0MiI6WzYxNTAwLDYx'
      'NjI0LDYxNjc4XSwiMzE0MyI6WzYxNTAwLDYxNjI0LDYxNjkxXSwiMzE0NCI6WzYxNTAwLDYxNjI0LDYxNjc4LDYxNjUzXSwiMzE0'
      'NiI6WzYxNTAwLDYxNjI0LDYxNTAxXSwiMzE0NyI6WzYxNTAwLDYxNjI0LDYxNjM1XSwiMzE0OCI6WzYxNTAwLDYxNjI0LDYxNjc0'
      'XSwiMzE0OSI6WzYxNTAwLDYxNjI0LDYxNTgyXX19LCIzMTEwIjp7ImJhc2UiOls2MTUwMCw2MTU3OF0sInN5bWJvbHMiOnsiMzEz'
      'NCI6WzYxNTAwLDYxNTg1XSwiMzEzNSI6WzYxNTY2XSwiMzEzNiI6WzYxNTA2XSwiMzEzNyI6WzYxNTAwLDYxNTc4LDYxNTI0XSwi'
      'MzEzOCI6WzYxNTAwLDYxNTc4LDYxNjU0XSwiMzE0MiI6WzYxNTAwLDYxNjc4XSwiMzE0MyI6WzYxNTAwLDYxNjkxXSwiMzE0NCI6'
      'WzYxNTAwLDYxNjc4LDYxNjUzXSwiMzE0NiI6WzYxNTAwLDYxNTAxXSwiMzE0NyI6WzYxNTAwLDYxNjM1XSwiMzE0OCI6WzYxNTAw'
      'LDYxNjc0XSwiMzE0OSI6WzYxNTAwLDYxNTgyXX19LCIzMTExIjp7ImJhc2UiOls2MTUwMCw2MTY4Myw2MTU3OF0sInN5bWJvbHMi'
      'OnsiMzEzNCI6WzYxNTAwLDYxNjgzLDYxNTg1XSwiMzEzNSI6WzYxNTY2LDYxNjgzXSwiMzEzNiI6WzYxNTA2LDYxNjgzXSwiMzEz'
      'NyI6WzYxNTAwLDYxNjgzLDYxNTc4LDYxNTI0XSwiMzEzOCI6WzYxNTAwLDYxNjgzLDYxNTc4LDYxNjU0XSwiMzE0MiI6WzYxNTAw'
      'LDYxNjgzLDYxNjc4XSwiMzE0MyI6WzYxNTAwLDYxNjgzLDYxNjkxXSwiMzE0NCI6WzYxNTAwLDYxNjgzLDYxNjc4LDYxNjUzXSwi'
      'MzE0NiI6WzYxNTAwLDYxNjgzLDYxNTAxXSwiMzE0NyI6WzYxNTAwLDYxNjgzLDYxNjM1XSwiMzE0OCI6WzYxNTAwLDYxNjgzLDYx'
      'Njc0XSwiMzE0OSI6WzYxNTAwLDYxNjgzLDYxNTgyXX19LCIzMTEyIjp7ImJhc2UiOls2MTU1M10sInN5bWJvbHMiOnsiMzEzNCI6'
      'WzYxNTEyLDYxNTg0XSwiMzEzNSI6WzYxNTg3XSwiMzEzNiI6WzYxNjkwXSwiMzEzNyI6WzYxNTUzLDYxNTI0XSwiMzEzOCI6WzYx'
      'NTUzLDYxNjU0XSwiMzE0MiI6WzYxNTEyLDYxNjc4XSwiMzE0MyI6WzYxNTEyLDYxNjkxXSwiMzE0NCI6WzYxNTEyLDYxNjc4LDYx'
      'NjUzXSwiMzE0NiI6WzYxNTEyLDYxNTAxXSwiMzE0NyI6WzYxNTEyLDYxNjM1XSwiMzE0OCI6WzYxNTEyLDYxNjc0XSwiMzE0OSI6'
      'WzYxNTEyLDYxNTgyXX19LCIzMTE0Ijp7ImJhc2UiOls2MTU2NCw2MTU5OV0sInN5bWJvbHMiOnsiMzEzNCI6WzYxNTM4LDYxNjQ1'
      'XSwiMzEzNSI6WzYxNTY0LDYxNjMwXSwiMzEzNiI6WzYxNTY0LDYxNjUxXSwiMzEzNyI6WzYxNTY0LDYxNTk5LDYxNjU4XSwiMzEz'
      'OCI6WzYxNTY0LDYxNTk5LDYxNTIwXSwiMzE0MiI6WzYxNTkzLDYxNTY0XSwiMzE0MyI6WzYxNTk3LDYxNTY0XSwiMzE0NCI6WzYx'
      'NTkzLDYxNTY0LDYxNjUzXSwiMzE0NiI6WzYxNTM4LDYxNjg1XSwiMzE0NyI6WzYxNTM4LDYxNjk0XSwiMzE0OCI6WzYxNTM4LDYx'
      'NjY5XSwiMzE0OSI6WzYxNTY0LDYxNTU2XX19LCIzMTE1Ijp7ImJhc2UiOls2MTU2NCw2MTU5Miw2MTU5OV0sInN5bWJvbHMiOnsi'
      'MzEzNCI6WzYxNTM4LDYxNTkyLDYxNjQ1XSwiMzEzNSI6WzYxNTY0LDYxNTkyLDYxNjMwXSwiMzEzNiI6WzYxNTY0LDYxNTkyLDYx'
      'NjUxXSwiMzEzNyI6WzYxNTY0LDYxNTkyLDYxNTk5LDYxNjU4XSwiMzEzOCI6WzYxNTY0LDYxNTkyLDYxNTk5LDYxNTIwXSwiMzE0'
      'MiI6WzYxNTkzLDYxNTY0LDYxNTkyXSwiMzE0MyI6WzYxNTk3LDYxNTY0LDYxNTkyXSwiMzE0NCI6WzYxNTkzLDYxNTY0LDYxNTky'
      'LDYxNjUzXSwiMzE0NiI6WzYxNTM4LDYxNTkyLDYxNjg1XSwiMzE0NyI6WzYxNTM4LDYxNTkyLDYxNjk0XSwiMzE0OCI6WzYxNTM4'
      'LDYxNTkyLDYxNjY5XSwiMzE0OSI6WzYxNTY0LDYxNTkyLDYxNTU2XX19LCIzMTE2Ijp7ImJhc2UiOls2MTU3OV0sInN5bWJvbHMi'
      'OnsiMzEzNCI6WzYxNTU3LDYxNjE4XSwiMzEzNSI6WzYxNTM1XSwiMzEzNiI6WzYxNDk5XSwiMzEzNyI6WzYxNTc5LDYxNTI0XSwi'
      'MzEzOCI6WzYxNTc5LDYxNjU0XSwiMzE0MiI6WzYxNTU3LDYxNjQxXSwiMzE0MyI6WzYxNTU3LDYxNjgxXSwiMzE0NCI6WzYxNTU3'
      'LDYxNjQxLDYxNjUzXSwiMzE0NiI6WzYxNTU3LDYxNjA0XSwiMzE0NyI6WzYxNTU3LDYxNjQzXSwiMzE0OCI6WzYxNTU3LDYxNTcz'
      'XSwiMzE0OSI6WzYxNTc5LDYxNjQyXX19LCIzMTE3Ijp7ImJhc2UiOls2MTU1Nyw2MTY4Myw2MTU3Ml0sInN5bWJvbHMiOnsiMzEz'
      'NCI6WzYxNTU3LDYxNjgzLDYxNjE4XSwiMzEzNSI6WzYxNTM1LDYxNjgzXSwiMzEzNiI6WzYxNDk5LDYxNjgzXSwiMzEzNyI6WzYx'
      'NTU3LDYxNjgzLDYxNTcyLDYxNTI0XSwiMzEzOCI6WzYxNTU3LDYxNjgzLDYxNTcyLDYxNjU0XSwiMzE0MiI6WzYxNTU3LDYxNjgz'
      'LDYxNjQxXSwiMzE0MyI6WzYxNTU3LDYxNjgzLDYxNjgxXSwiMzE0NCI6WzYxNTU3LDYxNjgzLDYxNjQxLDYxNjUzXSwiMzE0NiI6'
      'WzYxNTU3LDYxNjgzLDYxNjA0XSwiMzE0NyI6WzYxNTU3LDYxNjgzLDYxNjQzXSwiMzE0OCI6WzYxNTU3LDYxNjgzLDYxNTczXSwi'
      'MzE0OSI6WzYxNTU3LDYxNjgzLDYxNTcyLDYxNjQyXX19LCIzMTE4Ijp7ImJhc2UiOls2MTU0MSw2MTUyNF0sInN5bWJvbHMiOnsi'
      'MzEzNCI6WzYxNTQxLDYxNjU0XSwiMzEzNSI6WzYxNDc2LDYxNTI0XSwiMzEzNiI6WzYxNTE3LDYxNTI0XSwiMzEzNyI6WzYxNTQx'
      'LDYxNTI0LDYxNTI0XSwiMzEzOCI6WzYxNTQxLDYxNTI0LDYxNjU0XSwiMzE0MiI6WzYxNTYxLDYxNjc4LDYxNTI0XSwiMzE0MyI6'
      'WzYxNTYxLDYxNjkxLDYxNTI0XSwiMzE0NCI6WzYxNTYxLDYxNjc4LDYxNTI0LDYxNjE0XSwiMzE0NiI6WzYxNTYxLDYxNjc4LDYx'
      'NTI0LDYxNTI0XSwiMzE0NyI6WzYxNTYxLDYxNjc4LDYxNjU0XSwiMzE0OCI6WzYxNTQxLDYxNTI0LDYxNjgyXSwiMzE0OSI6WzYx'
      'NTYxLDYxNTgyLDYxNTI0XX19LCIzMTE5Ijp7ImJhc2UiOls2MTU0Niw2MTY2NSw2MTYwN10sInN5bWJvbHMiOnsiMzEzNCI6WzYx'
      'NTQ2LDYxNjY1LDYxNjU0XSwiMzEzNSI6WzYxNTU1LDYxNTI0LDYxNTI0XSwiMzEzNiI6WzYxNTU1LDYxNTI0LDYxNjU0XSwiMzEz'
      'NyI6WzYxNTQ2LDYxNjY1LDYxNTI0LDYxNTI0XSwiMzEzOCI6WzYxNTQ2LDYxNjY1LDYxNTI0LDYxNjU0XSwiMzE0MiI6WzYxNTQ2'
      'LDYxNjc4LDYxNTI0XSwiMzE0MyI6WzYxNTQ2LDYxNjkxLDYxNTI0XSwiMzE0NCI6WzYxNTQ2LDYxNjc4LDYxNjE0LDYxNTI0XSwi'
      'MzE0NiI6WzYxNTQ2LDYxNjc4LDYxNTI0LDYxNTI0XSwiMzE0NyI6WzYxNTQ2LDYxNjc4LDYxNjU0XSwiMzE0OCI6WzYxNTQ2LDYx'
      'NjY1LDYxNTI0LDYxNjgyXSwiMzE0OSI6WzYxNTQ2LDYxNTI5LDYxNTI0XX19LCIzMTIwIjp7ImJhc2UiOls2MTU1NSw2MTY2NV0s'
      'InN5bWJvbHMiOnsiMzEzNCI6WzYxNTU1LDYxNTg0XSwiMzEzNSI6WzYxNTMzXSwiMzEzNiI6WzYxNjE1XSwiMzEzNyI6WzYxNTU1'
      'LDYxNjMzLDYxNTI0XSwiMzEzOCI6WzYxNTU1LDYxNjMzLDYxNjU0XSwiMzE0MiI6WzYxNjM0LDYxNTU1XSwiMzE0MyI6WzYxNjI1'
      'LDYxNTU1XSwiMzE0NCI6WzYxNjM0LDYxNTU1LDYxNjUzXSwiMzE0NiI6WzYxNTU1LDYxNTAxXSwiMzE0NyI6WzYxNTU1LDYxNjM1'
      'XSwiMzE0OCI6WzYxNTU1LDYxNTk0XSwiMzE0OSI6WzYxNTU1LDYxNTI5XX19LCIzMTIyIjp7ImJhc2UiOls2MTUzMl0sInN5bWJv'
      'bHMiOnsiMzEzNCI6WzYxNjkzLDYxNjE4XSwiMzEzNSI6WzYxNDgyXSwiMzEzNiI6WzYxNjA5XSwiMzEzNyI6WzYxNTMyLDYxNTI0'
      'XSwiMzEzOCI6WzYxNTMyLDYxNjU0XSwiMzE0MiI6WzYxNjkzLDYxNjQxXSwiMzE0MyI6WzYxNjkzLDYxNjgxXSwiMzE0NCI6WzYx'
      'NjkzLDYxNjQxLDYxNjUzXSwiMzE0NiI6WzYxNjkzLDYxNjA0XSwiMzE0NyI6WzYxNjkzLDYxNjQzXSwiMzE0OCI6WzYxNjkzLDYx'
      'NTczXSwiMzE0OSI6WzYxNjkzLDYxNjU3XX19LCIzMTIzIjp7ImJhc2UiOls2MTY2Miw2MTY4OF0sInN5bWJvbHMiOnsiMzEzNCI6'
      'WzYxNjYyLDYxNjE4XSwiMzEzNSI6WzYxNTMxXSwiMzEzNiI6WzYxNjE2XSwiMzEzNyI6WzYxNjYyLDYxNjg4LDYxNTkxXSwiMzEz'
      'OCI6WzYxNjYyLDYxNjg4LDYxNTIzXSwiMzE0MiI6WzYxNjYyLDYxNjcyXSwiMzE0MyI6WzYxNjYyLDYxNjY2XSwiMzE0NCI6WzYx'
      'NjYyLDYxNjcyLDYxNjUzXSwiMzE0NiI6WzYxNjYyLDYxNjA0XSwiMzE0NyI6WzYxNjYyLDYxNjQzXSwiMzE0OCI6WzYxNjYyLDYx'
      'NTczXSwiMzE0OSI6WzYxNjYyLDYxNjU3XX19LCIzMTI1Ijp7ImJhc2UiOls2MTU0MV0sInN5bWJvbHMiOnsiMzEzNCI6WzYxNTYx'
      'LDYxNTg0XSwiMzEzNSI6WzYxNDc2XSwiMzEzNiI6WzYxNTE3XSwiMzEzNyI6WzYxNTQxLDYxNjU4XSwiMzEzOCI6WzYxNTQxLDYx'
      'NjU4XSwiMzE0MiI6WzYxNTYxLDYxNjc4XSwiMzE0MyI6WzYxNTYxLDYxNjkxXSwiMzE0NCI6WzYxNTYxLDYxNjc4LDYxNjUzXSwi'
      'MzE0NiI6WzYxNTYxLDYxNTAxXSwiMzE0NyI6WzYxNTYxLDYxNjM1XSwiMzE0OCI6WzYxNTYxLDYxNjc0XSwiMzE0OSI6WzYxNTYx'
      'LDYxNTgyXX19LCIzMTI2Ijp7ImJhc2UiOls2MTUyOCw2MTY4OF0sInN5bWJvbHMiOnsiMzEzNCI6WzYxNTI4LDYxNjcwXSwiMzEz'
      'NSI6WzYxNjA1XSwiMzEzNiI6WzYxNTUxXSwiMzEzNyI6WzYxNTI4LDYxNjg4LDYxNTkxXSwiMzEzOCI6WzYxNTI4LDYxNjg4LDYx'
      'NTIzXSwiMzE0MiI6WzYxNTI4LDYxNjcyXSwiMzE0MyI6WzYxNTI4LDYxNjY2XSwiMzE0NCI6WzYxNTI4LDYxNjcyLDYxNjUzXSwi'
      'MzE0NiI6WzYxNTI4LDYxNjA0XSwiMzE0NyI6WzYxNTI4LDYxNjQzXSwiMzE0OCI6WzYxNTI4LDYxNTczXSwiMzE0OSI6WzYxNTI4'
      'LDYxNjU3XX19LCIzMTI3Ijp7ImJhc2UiOls2MTU1OSw2MTU5OV0sInN5bWJvbHMiOnsiMzEzNCI6WzYxNTM5LDYxNjQ1XSwiMzEz'
      'NSI6WzYxNTU5LDYxNjMwXSwiMzEzNiI6WzYxNTU5LDYxNjUxXSwiMzEzNyI6WzYxNTU5LDYxNTk5LDYxNjA3XSwiMzEzOCI6WzYx'
      'NTU5LDYxNTk5LDYxNTE5XSwiMzE0MiI6WzYxNTkzLDYxNTU5XSwiMzE0MyI6WzYxNTk3LDYxNTU5XSwiMzE0NCI6WzYxNTkzLDYx'
      'NTU5LDYxNjUzXSwiMzE0NiI6WzYxNTM5LDYxNjg1XSwiMzE0NyI6WzYxNTM5LDYxNjk0XSwiMzE0OCI6WzYxNTM5LDYxNjY5XSwi'
      'MzE0OSI6WzYxNTU5LDYxNTU2XX19LCIzMTI4Ijp7ImJhc2UiOls2MTU0MCw2MTU5OV0sInN5bWJvbHMiOnsiMzEzNCI6WzYxNTQ3'
      'LDYxNjQ1XSwiMzEzNSI6WzYxNTQwLDYxNjMwXSwiMzEzNiI6WzYxNTQwLDYxNjUxXSwiMzEzNyI6WzYxNTQwLDYxNTk5LDYxNTI0'
      'XSwiMzEzOCI6WzYxNTQwLDYxNTk5LDYxNjU0XSwiMzE0MiI6WzYxNTkzLDYxNTQwXSwiMzE0MyI6WzYxNTk3LDYxNTQwXSwiMzE0'
      'NCI6WzYxNTkzLDYxNTQwLDYxNjUzXSwiMzE0NiI6WzYxNTQ3LDYxNjg1XSwiMzE0NyI6WzYxNTQ3LDYxNjk0XSwiMzE0OCI6WzYx'
      'NTQ3LDYxNjY5XSwiMzE0OSI6WzYxNTQwLDYxNTU2XX19LCIzMTI5Ijp7ImJhc2UiOls2MTUyNiw2MTU5OSw2MTYxOF0sInN5bWJv'
      'bHMiOnsiMzEzNCI6WzYxNTI2LDYxNTk5LDYxNjY4XSwiMzEzNSI6WzYxNTI2LDYxNjMwLDYxNjE4XSwiMzEzNiI6WzYxNTI2LDYx'
      'NjUxLDYxNjE4XSwiMzEzNyI6WzYxNTI2LDYxNTk5LDYxNTIxXSwiMzEzOCI6WzYxNTI2LDYxNTk5LDYxNTA1XSwiMzE0MiI6WzYx'
      'NTkzLDYxNTI2LDYxNjE4XSwiMzE0MyI6WzYxNTk3LDYxNTI2LDYxNjE4XSwiMzE0NCI6WzYxNTkzLDYxNTI2LDYxNjUzLDYxNjE4'
      'XSwiMzE0NiI6WzYxNTI2LDYxNTk5LDYxNjE4LDYxNTAxXSwiMzE0NyI6WzYxNTI2LDYxNTk5LDYxNjE4LDYxNjM1XSwiMzE0OCI6'
      'WzYxNTI2LDYxNTk5LDYxNjE4LDYxNTczXSwiMzE0OSI6WzYxNTI2LDYxNTU2LDYxNjE4XX19fX0=';
}

class _ReverseLegacyMapping {
  _ReverseLegacyMapping(this.values, this.tokensByLength)
    : tokenGlyphs = _tokenGlyphs(tokensByLength);

  final Map<String, String> values;
  final List<String> tokensByLength;
  final Set<String> tokenGlyphs;

  bool hasTokenGlyph(String value) => tokenGlyphs.contains(value);

  static Set<String> _tokenGlyphs(List<String> tokens) {
    final glyphs = <String>{};
    for (final token in tokens) {
      for (var index = 0; index < token.length; index += 1) {
        glyphs.add(token[index]);
      }
    }
    return glyphs;
  }
}

class _LegacyPromotedText {
  const _LegacyPromotedText(this.text, this._originals);

  final String text;
  final List<String>? _originals;

  String originalCharAt(int index) {
    final originals = _originals;
    if (originals == null || index < 0 || index >= originals.length) {
      return text[index];
    }
    return originals[index];
  }
}

class _LegacyDecodeResult {
  const _LegacyDecodeResult(this.text, this.convertedGlyphs, this.teluguChars);

  final String text;
  final int convertedGlyphs;
  final int teluguChars;

  int get score => (convertedGlyphs * 4) + teluguChars;
}

class _LegacyMapping {
  const _LegacyMapping({
    required this.vowels,
    required this.extensions,
    required this.consonants,
  });

  final Map<int, List<int>> vowels;
  final Map<int, List<int>> extensions;
  final Map<int, _LegacyConsonant> consonants;

  factory _LegacyMapping.fromJson(Map<String, dynamic> json) {
    return _LegacyMapping(
      vowels: _readUnitMap(json['vowels']),
      extensions: _readUnitMap(json['extensions']),
      consonants: _readConsonants(json['consonants']),
    );
  }

  static Map<int, List<int>> _readUnitMap(Object? raw) {
    final result = <int, List<int>>{};
    if (raw is! Map) {
      return result;
    }
    for (final entry in raw.entries) {
      final key = int.tryParse('${entry.key}');
      final value = entry.value;
      if (key == null || value is! List) {
        continue;
      }
      result[key] = value.whereType<num>().map((item) => item.toInt()).toList();
    }
    return result;
  }

  static Map<int, _LegacyConsonant> _readConsonants(Object? raw) {
    final result = <int, _LegacyConsonant>{};
    if (raw is! Map) {
      return result;
    }
    for (final entry in raw.entries) {
      final key = int.tryParse('${entry.key}');
      final value = entry.value;
      if (key == null || value is! Map) {
        continue;
      }
      result[key] = _LegacyConsonant(
        base: _readUnits(value['base']),
        symbols: _readUnitMap(value['symbols']),
      );
    }
    return result;
  }

  static List<int> _readUnits(Object? raw) {
    if (raw is! List) {
      return const <int>[];
    }
    return raw.whereType<num>().map((item) => item.toInt()).toList();
  }
}

class _LegacyConsonant {
  const _LegacyConsonant({required this.base, required this.symbols});

  final List<int> base;
  final Map<int, List<int>> symbols;
}
