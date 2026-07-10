import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mana_poster/features/prehome/services/telugu_legacy_offline_converter.dart';

void main() {
  test('matches offline AndhraCode Telugu legacy stress dataset', () async {
    final datasetFile = File('test/data/telugu_legacy_stress_dataset.json');
    final rawDataset = jsonDecode(await datasetFile.readAsString());
    expect(rawDataset, isA<List<dynamic>>());

    final entries = rawDataset.cast<Map<String, Object?>>();
    expect(entries.length, greaterThanOrEqualTo(100));

    final failures = <_StressFailure>[];
    for (final entry in entries) {
      final unicode = entry['unicode']! as String;
      final expected = entry['legacy']! as String;
      final actual = TeluguLegacyOfflineConverter.convert(unicode);
      if (actual != expected) {
        failures.add(
          _StressFailure(
            unicode: unicode,
            group: entry['group']! as String,
            expected: expected,
            actual: actual,
          ),
        );
      }
    }

    if (failures.isNotEmpty) {
      fail(_failureReport(failures));
    }
  });
}

String _failureReport(List<_StressFailure> failures) {
  final buffer = StringBuffer()..writeln('Stress failures: ${failures.length}');
  for (final failure in failures) {
    buffer
      ..writeln('Unicode: ${failure.unicode}')
      ..writeln('Group: ${failure.group}')
      ..writeln('Expected: ${_hex(failure.expected)}')
      ..writeln('Actual: ${_hex(failure.actual)}')
      ..writeln('First mismatch: ${failure.firstMismatch + 1}')
      ..writeln();
  }
  return buffer.toString();
}

String _hex(String value) => value.runes
    .map((code) => code.toRadixString(16).toUpperCase().padLeft(4, '0'))
    .join(' ');

class _StressFailure {
  const _StressFailure({
    required this.unicode,
    required this.group,
    required this.expected,
    required this.actual,
  });

  final String unicode;
  final String group;
  final String expected;
  final String actual;

  int get firstMismatch {
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
}
