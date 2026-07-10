import 'dart:io';

import 'package:mana_poster/features/prehome/services/telugu_legacy_offline_converter.dart';
import 'package:mana_poster/features/prehome/services/telugu_legacy_text_service.dart';

void main() {
  final fonts = _readLegacyFonts();
  final clusters = <String, String>{
    'sra': '\u0C38\u0C4D\u0C30',
    'skra': '\u0C38\u0C4D\u0C15\u0C4D\u0C30',
    'stra': '\u0C38\u0C4D\u0C24\u0C4D\u0C30',
    'stta_ra': '\u0C38\u0C4D\u0C1F\u0C4D\u0C30',
    'sstta_ra': '\u0C37\u0C4D\u0C1F\u0C4D\u0C30',
    'kshma': '\u0C15\u0C4D\u0C37\u0C4D\u0C2E\u0C3F',
    'kshya': '\u0C15\u0C4D\u0C37\u0C4D\u0C2F\u0C3E',
    'ksa': '\u0C15\u0C4D\u0C38',
    'ks_dead': '\u0C15\u0C4D\u0C38\u0C4D',
    'kst': '\u0C15\u0C4D\u0C38\u0C4D\u0C1F',
    'kst_dead': '\u0C15\u0C4D\u0C38\u0C4D\u0C1F\u0C4D',
    'kstra': '\u0C15\u0C4D\u0C38\u0C4D\u0C1F\u0C4D\u0C30',
    'st_dead': '\u0C38\u0C4D\u0C1F\u0C4D',
    'text_word': '\u0C1F\u0C46\u0C15\u0C4D\u0C38\u0C4D\u0C1F\u0C4D',
  };

  final rows = <List<String>>[
    <String>[
      'font',
      'asset',
      'profile',
      'cluster',
      'unicode',
      'andhra_hex',
      'selected_hex',
      'first_mismatch',
      'status',
      'why',
    ],
  ];

  for (final font in fonts) {
    final trailing = TeluguLegacyTextService.usesTrailingRaVattu(font.family);
    final trailingKsaTta = TeluguLegacyTextService.usesTrailingKsaTtaVattu(
      font.family,
    );
    final profile = <String>[
      trailing ? 'andhra_trailing_rakaram' : 'leading_rakaram',
      trailingKsaTta ? 'andhra_kst_vattu_order' : 'separated_kst_vattu_order',
    ].join('+');
    final why = trailing
        ? 'Font renders AndhraCode trailing rakaram order correctly; kst family uses separated vattu order when needed.'
        : 'Font requires rakaram before the conjunct; kst family uses separated vattu order to avoid sa/tta vattu overlap.';

    for (final cluster in clusters.entries) {
      final andhra = TeluguLegacyOfflineConverter.convert(
        cluster.value,
        trailingRaVattu: true,
      );
      final selected = TeluguLegacyTextService.convertSync(
        cluster.value,
        fontFamily: font.family,
      );
      rows.add(<String>[
        font.family,
        font.asset,
        profile,
        cluster.key,
        cluster.value,
        _hex(andhra),
        _hex(selected ?? ''),
        _firstMismatch(andhra, selected ?? ''),
        selected == null || selected.isEmpty ? 'fail' : 'pass',
        why,
      ]);
    }
  }

  final out = File('test/data/telugu_legacy_font_profile_report.csv');
  out.parent.createSync(recursive: true);
  out.writeAsStringSync(rows.map(_csvRow).join('\n'));
  stdout.writeln('Wrote ${out.path}');
  stdout.writeln('Fonts audited: ${fonts.length}');
  stdout.writeln('Rows: ${rows.length - 1}');
}

List<_LegacyFont> _readLegacyFonts() {
  final lines = File('pubspec.yaml').readAsLinesSync();
  final fonts = <_LegacyFont>[];
  String? family;

  for (final rawLine in lines) {
    final line = rawLine.trim();
    if (line.startsWith('- family: ')) {
      family = line.substring('- family: '.length);
      continue;
    }
    if (family != null &&
        line.startsWith('- asset: assets/fonts/telugu_legacy/')) {
      fonts.add(_LegacyFont(family, line.substring('- asset: '.length)));
      family = null;
    }
  }

  fonts.sort((a, b) => a.family.compareTo(b.family));
  return fonts;
}

String _hex(String text) {
  return text.runes
      .map((code) => code.toRadixString(16).toUpperCase().padLeft(4, '0'))
      .join(' ');
}

String _firstMismatch(String expected, String actual) {
  final expectedRunes = expected.runes.toList(growable: false);
  final actualRunes = actual.runes.toList(growable: false);
  final comparable = expectedRunes.length < actualRunes.length
      ? expectedRunes.length
      : actualRunes.length;
  for (var index = 0; index < comparable; index += 1) {
    if (expectedRunes[index] != actualRunes[index]) {
      return 'glyph_${index + 1}';
    }
  }
  if (expectedRunes.length != actualRunes.length) {
    return 'glyph_${comparable + 1}';
  }
  return '';
}

String _csvRow(List<String> cells) {
  return cells.map((cell) => '"${cell.replaceAll('"', '""')}"').join(',');
}

class _LegacyFont {
  const _LegacyFont(this.family, this.asset);

  final String family;
  final String asset;
}
