import 'dart:convert';
import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mana_poster/features/prehome/services/telugu_legacy_offline_converter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('matches offline AndhraCode Telugu legacy regression dataset', () async {
    final datasetFile = File('test/data/telugu_regression.json');
    final mappingTableFile = File('test/data/telugu_legacy_mapping_table.json');
    final rawDataset = jsonDecode(await datasetFile.readAsString());
    final rawMappingTable = jsonDecode(await mappingTableFile.readAsString());
    expect(rawDataset, isA<List<dynamic>>());
    expect(rawMappingTable, isA<Map<String, dynamic>>());

    final entries = rawDataset.cast<Map<String, Object?>>();
    expect(entries.length, greaterThanOrEqualTo(1000));
    expect(rawMappingTable['runtimeDependency'], 'none');
    expect(rawMappingTable['count'], entries.length);
    expect(rawMappingTable['mappings'], isA<List<dynamic>>());

    final fontBytes = await File(
      'assets/fonts/telugu_legacy/pallavi_bold.ttf',
    ).readAsBytes();
    final fontLoader = FontLoader('Pallavi Bold')
      ..addFont(
        Future<ByteData>.value(
          ByteData.sublistView(Uint8List.fromList(fontBytes)),
        ),
      );
    await fontLoader.load();

    final failures = <_LegacyRegressionFailure>[];
    final totalsByGroup = <String, int>{};
    final failuresByGroup = <String, int>{};

    for (final entry in entries) {
      final unicode = entry['unicode']! as String;
      final expected = entry['legacy']! as String;
      final group = entry['group']! as String;
      final description = entry['description']! as String;
      totalsByGroup[group] = (totalsByGroup[group] ?? 0) + 1;

      final actual = TeluguLegacyOfflineConverter.convert(unicode);
      if (actual != expected) {
        failures.add(
          _LegacyRegressionFailure(
            unicode: unicode,
            group: group,
            description: description,
            expected: expected,
            actual: actual,
          ),
        );
        failuresByGroup[group] = (failuresByGroup[group] ?? 0) + 1;
        continue;
      }

      expect(
        RegExp(r'[\u0C00-\u0C7F]').hasMatch(actual),
        isFalse,
        reason:
            'Converted legacy text must not contain Telugu Unicode: $unicode',
      );
      _verifyLegacyTextCanRender(actual);
    }

    final passed = entries.length - failures.length;
    final coverageReport = _coverageReport(
      total: entries.length,
      passed: passed,
      failures: failures,
      totalsByGroup: totalsByGroup,
      failuresByGroup: failuresByGroup,
    );
    // ignore: avoid_print
    print(coverageReport);

    if (failures.isNotEmpty) {
      fail(_failureReport(failures, coverageReport));
    }
  });
}

void _verifyLegacyTextCanRender(String legacyText) {
  final painter = TextPainter(
    text: TextSpan(
      text: legacyText,
      style: const TextStyle(fontFamily: 'Pallavi Bold', fontSize: 32),
    ),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: 1200);
  expect(painter.width, greaterThan(0));
  expect(painter.height, greaterThan(0));
}

String _coverageReport({
  required int total,
  required int passed,
  required List<_LegacyRegressionFailure> failures,
  required Map<String, int> totalsByGroup,
  required Map<String, int> failuresByGroup,
}) {
  final lines = <String>[
    'Telugu legacy regression coverage',
    'Total words: $total',
    'Passed: $passed',
    'Failed: ${failures.length}',
    'Coverage by conjunct:',
  ];
  final groups = totalsByGroup.keys.toList()..sort();
  for (final group in groups) {
    final groupTotal = totalsByGroup[group]!;
    final failed = failuresByGroup[group] ?? 0;
    final percent = ((groupTotal - failed) * 100 / groupTotal).toStringAsFixed(
      failed == 0 ? 0 : 1,
    );
    lines.add('$group: $percent%');
  }
  return lines.join('\n');
}

String _failureReport(
  List<_LegacyRegressionFailure> failures,
  String coverageReport,
) {
  final lines = <String>['FAILED', coverageReport, ''];
  for (final failure in failures.take(25)) {
    lines.addAll(<String>[
      'Unicode:',
      failure.unicode,
      'Group:',
      failure.group,
      'Description:',
      failure.description,
      'Expected:',
      _hex(failure.expected),
      'Actual:',
      _hex(failure.actual),
      'Mismatch:',
      'glyph #${failure.firstMismatchGlyph + 1}',
      'Reason:',
      'Incorrect ${failure.group} conjunct mapping',
      '',
    ]);
  }
  if (failures.length > 25) {
    lines.add('... ${failures.length - 25} more failures');
  }
  return lines.join('\n');
}

String _hex(String text) {
  return text.runes
      .map((code) => code.toRadixString(16).toUpperCase().padLeft(4, '0'))
      .join(' ');
}

class _LegacyRegressionFailure {
  const _LegacyRegressionFailure({
    required this.unicode,
    required this.group,
    required this.description,
    required this.expected,
    required this.actual,
  });

  final String unicode;
  final String group;
  final String description;
  final String expected;
  final String actual;

  int get firstMismatchGlyph {
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
}
