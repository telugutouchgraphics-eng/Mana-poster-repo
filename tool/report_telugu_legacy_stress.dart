import 'dart:convert';
import 'dart:io';

import 'package:mana_poster/features/prehome/services/telugu_legacy_offline_converter.dart';

void main() {
  final entries =
      (jsonDecode(
                File(
                  'test/data/telugu_legacy_stress_dataset.json',
                ).readAsStringSync(),
              )
              as List)
          .cast<Map<String, Object?>>();
  stdout.writeln('Unicode,Pass,First mismatch,Our hex,AndhraCode hex');
  for (final entry in entries) {
    final unicode = entry['unicode']! as String;
    final expected = entry['legacy']! as String;
    final actual = TeluguLegacyOfflineConverter.convert(unicode);
    final mismatch = _firstMismatch(expected, actual);
    stdout.writeln(
      [
        _csv(unicode),
        actual == expected ? 'PASS' : 'FAIL',
        mismatch == null ? '' : '${mismatch + 1}',
        _csv(_hex(actual)),
        _csv(_hex(expected)),
      ].join(','),
    );
  }
}

String _csv(String value) => '"${value.replaceAll('"', '""')}"';

String _hex(String value) => value.runes
    .map((code) => code.toRadixString(16).toUpperCase().padLeft(4, '0'))
    .join(' ');

int? _firstMismatch(String expected, String actual) {
  if (expected == actual) {
    return null;
  }
  final expectedRunes = expected.runes.toList(growable: false);
  final actualRunes = actual.runes.toList(growable: false);
  final comparable = expectedRunes.length < actualRunes.length
      ? expectedRunes.length
      : actualRunes.length;
  for (var index = 0; index < comparable; index += 1) {
    if (expectedRunes[index] != actualRunes[index]) {
      return index;
    }
  }
  return comparable;
}
