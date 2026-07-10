import 'dart:io';

import 'package:mana_poster/features/prehome/services/telugu_legacy_offline_converter.dart';

void main() {
  const samples = <String, List<int>>{
    '\u0C05': <int>[0xF06E],
    '\u0C06': <int>[0xF080],
    '\u0C07': <int>[0xF082],
    '\u0C08': <int>[0xF087],
    '\u0C09': <int>[0xF096],
    '\u0C0A': <int>[0xF07D],
    '\u0C0B': <int>[0xF08B, 0xF054, 0xF054],
    '\u0C60': <int>[0xF08B, 0xF054, 0xF0D6],
    '\u0C0E': <int>[0xF06D],
    '\u0C0F': <int>[0xF040],
    '\u0C10': <int>[0xF0D7],
    '\u0C12': <int>[0xF0FF],
    '\u0C13': <int>[0xF07A],
    '\u0C14': <int>[0xF057],
    '\u0C05\u0C02': <int>[0xF06E, 0xF02B],
    '\u0C05\u0C03': <int>[0xF06E, 0xF027],
  };

  final fonts = _readLegacyFonts();
  final rows = <List<String>>[
    <String>[
      'font',
      'unicode',
      'our_hex',
      'andhracode_hex',
      'glyphs',
      'status',
      'reason',
    ],
  ];

  for (final font in fonts) {
    for (final sample in samples.entries) {
      final actual = TeluguLegacyOfflineConverter.convert(sample.key);
      final expected = String.fromCharCodes(sample.value);
      final status = actual == expected ? 'PASS' : 'FAIL';
      rows.add(<String>[
        font.family,
        sample.key,
        _hex(actual),
        _hex(expected),
        sample.value
            .map(
              (code) =>
                  'U+${code.toRadixString(16).toUpperCase().padLeft(4, '0')}',
            )
            .join(' '),
        status,
        status == 'PASS'
            ? 'matches AndhraCode standalone vowel mapping'
            : 'converter vowel mapping differs from AndhraCode',
      ]);
    }
  }

  final out = File('test/data/telugu_legacy_vowel_report.csv');
  out.parent.createSync(recursive: true);
  out.writeAsStringSync(rows.map(_csvRow).join('\n'));
  stdout.writeln('Wrote ${out.path}');
  stdout.writeln('Fonts audited: ${fonts.length}');
  stdout.writeln('Rows: ${rows.length - 1}');
  stdout.writeln(
    'Failures: ${rows.skip(1).where((row) => row[5] == 'FAIL').length}',
  );
}

List<_LegacyFont> _readLegacyFonts() {
  final lines = File('pubspec.yaml').readAsLinesSync();
  final fonts = <_LegacyFont>[];
  String? family;
  for (final rawLine in lines) {
    final line = rawLine.trim();
    if (line.startsWith('- family: ')) {
      family = line.substring('- family: '.length);
    } else if (family != null &&
        line.startsWith('- asset: assets/fonts/telugu_legacy/')) {
      fonts.add(_LegacyFont(family));
      family = null;
    }
  }
  return fonts;
}

String _hex(String text) {
  return text.runes
      .map((code) => code.toRadixString(16).toUpperCase().padLeft(4, '0'))
      .join(' ');
}

String _csvRow(List<String> cells) {
  return cells.map((cell) => '"${cell.replaceAll('"', '""')}"').join(',');
}

class _LegacyFont {
  const _LegacyFont(this.family);

  final String family;
}
