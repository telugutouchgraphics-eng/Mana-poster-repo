import 'dart:convert';
import 'dart:io';

import 'package:mana_poster/features/prehome/services/telugu_legacy_offline_converter.dart';

void main(List<String> args) {
  final datasetPath = args.isEmpty ? 'test/data/telugu_regression.json' : args[0];
  final entries = (jsonDecode(File(datasetPath).readAsStringSync()) as List)
      .cast<Map<String, Object?>>();
  final failures = <Map<String, Object?>>[];
  final totalsByGroup = <String, int>{};
  final failuresByGroup = <String, int>{};

  for (final entry in entries) {
    final unicode = entry['unicode']! as String;
    final expected = entry['legacy']! as String;
    final group = entry['group']! as String;
    totalsByGroup[group] = (totalsByGroup[group] ?? 0) + 1;
    final actual = TeluguLegacyOfflineConverter.convert(unicode);
    if (actual == expected) {
      continue;
    }
    failuresByGroup[group] = (failuresByGroup[group] ?? 0) + 1;
    failures.add(<String, Object?>{
      'unicode': unicode,
      'group': group,
      'expectedHex': _hex(expected),
      'actualHex': _hex(actual),
      'firstMismatchGlyph': _firstMismatchGlyph(expected, actual) + 1,
    });
  }

  stdout.writeln('Total: ${entries.length}');
  stdout.writeln('Passed: ${entries.length - failures.length}');
  stdout.writeln('Failed: ${failures.length}');
  stdout.writeln('Failures by group:');
  for (final group in failuresByGroup.keys.toList()..sort()) {
    stdout.writeln(
      '$group: ${failuresByGroup[group]}/${totalsByGroup[group]} failed',
    );
  }
  stdout.writeln(jsonEncode(failures));
}

String _hex(String value) => value.runes
    .map((code) => code.toRadixString(16).toUpperCase().padLeft(4, '0'))
    .join(' ');

int _firstMismatchGlyph(String expected, String actual) {
  final expectedRunes = expected.runes.toList(growable: false);
  final actualRunes = actual.runes.toList(growable: false);
  final maxComparable = expectedRunes.length < actualRunes.length
      ? expectedRunes.length
      : actualRunes.length;
  for (var index = 0; index < maxComparable; index += 1) {
    if (expectedRunes[index] != actualRunes[index]) {
      return index;
    }
  }
  return maxComparable;
}
