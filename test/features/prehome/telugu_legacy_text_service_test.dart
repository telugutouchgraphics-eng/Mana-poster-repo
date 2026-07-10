import 'package:flutter_test/flutter_test.dart';
import 'package:mana_poster/features/prehome/services/telugu_legacy_offline_converter.dart';
import 'package:mana_poster/features/prehome/services/telugu_legacy_text_service.dart';

void main() {
  test('reverse converts legacy Telugu glyph text back to Unicode', () {
    const source = 'తెలుగు ప్రజలకు దీపాల శుభాకాంక్షలు';
    final legacy = TeluguLegacyOfflineConverter.convert(source);

    expect(legacy, isNot(source));
    expect(TeluguLegacyTextService.reverseConvertSync(legacy), source);
  });

  test('matches AndhraCode refreshed conjunct samples', () {
    final samples = <String, List<int>>{
      'అ': const <int>[0xF06E],
      'ఆ': const <int>[0xF080],
      'ఇ': const <int>[0xF082],
      'ఈ': const <int>[0xF087],
      'ఉ': const <int>[0xF096],
      'ఊ': const <int>[0xF07D],
      'ఋ': const <int>[0xF08B, 0xF054, 0xF054],
      'ౠ': const <int>[0xF08B, 0xF054, 0xF0D6],
      'ఎ': const <int>[0xF06D],
      'ఏ': const <int>[0xF040],
      'ఐ': const <int>[0xF0D7],
      'ఒ': const <int>[0xF0FF],
      'ఓ': const <int>[0xF07A],
      'ఔ': const <int>[0xF057],
      'అం': const <int>[0xF06E, 0xF02B],
      'అః': const <int>[0xF06E, 0xF027],
      'లక్ష్మి': const <int>[0xF05C, 0xF0BF, 0xF0EC, 0xF0EB],
      'మహారాష్ట్ర': const <int>[
        0xF065,
        0xF054,
        0xF056,
        0xF09F,
        0xF0E4,
        0xF073,
        0xF090,
        0xF077,
        0xF09F,
        0xF0BC,
        0xF081,
      ],
      'స్త్రీ': const <int>[0xF064, 0xF0D3, 0xF0EF, 0xF081],
      'స్రి': const <int>[0xF064, 0xF0BE, 0xF0E7],
      'స్క్రీ': const <int>[0xF064, 0xF0D3, 0xF0D8, 0xF0E7],
      'త్రై': const <int>[0xF0D4, 0xF0EE, 0xF0D5, 0xF081],
      '\u0C15\u0C4D\u0C38': const <int>[0xF0BF, 0xF0A3, 0xF0E0],
      '\u0C15\u0C4D\u0C38\u0C4D': const <int>[0xF0BF, 0xF0F9, 0xF0E0],
      '\u0C15\u0C4D\u0C38\u0C4D\u0C1F': const <int>[
        0xF0BF,
        0xF0A3,
        0xF0E0,
        0xF0BC,
      ],
      '\u0C15\u0C4D\u0C38\u0C4D\u0C1F\u0C4D': const <int>[
        0xF0BF,
        0xF0F9,
        0xF0E0,
        0xF0BC,
      ],
      '\u0C15\u0C4D\u0C38\u0C4D\u0C1F\u0C4D\u0C30': const <int>[
        0xF0BF,
        0xF0F9,
        0xF064,
        0xF09F,
        0xF0BC,
        0xF081,
      ],
      '\u0C38\u0C4D\u0C1F\u0C4D': const <int>[0xF064, 0xF074, 0xF0BC],
      '\u0C1F\u0C46\u0C15\u0C4D\u0C38\u0C4D\u0C1F\u0C4D': const <int>[
        0xF066,
        0xF0C9,
        0xF0BF,
        0xF0F9,
        0xF0E0,
        0xF0BC,
      ],
      'ABC 123 77% A-Z 0.5': const <int>[
        0xF041,
        0xF042,
        0xF043,
        0xF020,
        0xF031,
        0xF032,
        0xF033,
        0xF020,
        0xF037,
        0xF037,
        0xF025,
        0xF020,
        0xF041,
        0xF060,
        0xF05A,
        0xF020,
        0xF030,
        0xF02E,
        0xF035,
      ],
    };

    for (final entry in samples.entries) {
      expect(
        TeluguLegacyOfflineConverter.convert(entry.key).runes,
        entry.value,
        reason: entry.key,
      );
    }
  });

  test('repairs split ksha input before legacy conversion', () {
    final legacy = TeluguLegacyTextService.convertSync(
      String.fromCharCodes(const <int>[
        0x0C32,
        0x0C15,
        0x0C4D,
        0x0C4D,
        0x0C37,
        0x0C4D,
        0x0C2E,
        0x0C3F,
      ]),
      fontFamily: 'Pallavi Bold',
    );

    expect(legacy?.runes, const <int>[0xF05C, 0xF0BF, 0xF0EC, 0xF0EB]);
  });

  test('uses font-specific rakaram order for legacy fonts', () {
    const ssttaRa = '\u0C37\u0C4D\u0C1F\u0C4D\u0C30';
    const skra = '\u0C38\u0C4D\u0C15\u0C4D\u0C30';
    const stra = '\u0C38\u0C4D\u0C24\u0C4D\u0C30';

    expect(
      TeluguLegacyTextService.convertSync(
        ssttaRa,
        fontFamily: 'Aaradhana',
      )?.runes,
      const <int>[0xF077, 0xF09F, 0xF0BC, 0xF081],
    );
    expect(
      TeluguLegacyTextService.convertSync(
        ssttaRa,
        fontFamily: 'Bapu Bold',
      )?.runes,
      const <int>[0xF077, 0xF09F, 0xF0BC, 0xF081],
    );
    expect(
      TeluguLegacyTextService.convertSync(
        ssttaRa,
        fontFamily: 'Bapu Script',
      )?.runes,
      const <int>[0xF077, 0xF09F, 0xF0BC, 0xF081],
    );
    expect(
      TeluguLegacyTextService.convertSync(
        ssttaRa,
        fontFamily: 'Ramana Brush',
      )?.runes,
      const <int>[0xF077, 0xF09F, 0xF0BC, 0xF081],
    );
    expect(
      TeluguLegacyTextService.convertSync(
        ssttaRa,
        fontFamily: 'Ramana Script',
      )?.runes,
      const <int>[0xF077, 0xF09F, 0xF0BC, 0xF081],
    );
    expect(
      TeluguLegacyTextService.convertSync(
        ssttaRa,
        fontFamily: 'Ramana Script Medium',
      )?.runes,
      const <int>[0xF077, 0xF09F, 0xF0BC, 0xF081],
    );
    expect(
      TeluguLegacyTextService.convertSync(
        ssttaRa,
        fontFamily: 'Pallavi Bold',
      )?.runes,
      const <int>[0xF081, 0xF077, 0xF09F, 0xF0BC],
    );
    expect(
      TeluguLegacyTextService.convertSync(
        skra,
        fontFamily: 'Pallavi Bold',
      )?.runes,
      const <int>[0xF0E7, 0xF064, 0xF09F, 0xF0D8],
    );
    expect(
      TeluguLegacyTextService.convertSync(
        stra,
        fontFamily: 'Pallavi Bold',
      )?.runes,
      const <int>[0xF081, 0xF064, 0xF09F, 0xF0EF],
    );
  });

  test('uses font-specific kst vattu order for legacy fonts', () {
    const kst = '\u0C15\u0C4D\u0C38\u0C4D\u0C1F';
    const kstDead = '\u0C15\u0C4D\u0C38\u0C4D\u0C1F\u0C4D';
    const textWord = '\u0C1F\u0C46\u0C15\u0C4D\u0C38\u0C4D\u0C1F\u0C4D';

    expect(TeluguLegacyOfflineConverter.convert(kstDead).runes, const <int>[
      0xF0BF,
      0xF0F9,
      0xF0E0,
      0xF0BC,
    ]);
    expect(
      TeluguLegacyTextService.convertSync(
        kst,
        fontFamily: 'Pallavi Bold',
      )?.runes,
      const <int>[0xF0BF, 0xF0A3, 0xF0BC, 0xF0E0],
    );
    expect(
      TeluguLegacyTextService.convertSync(
        kstDead,
        fontFamily: 'Pallavi Bold',
      )?.runes,
      const <int>[0xF0BF, 0xF0F9, 0xF0BC, 0xF0E0],
    );
    expect(
      TeluguLegacyTextService.convertSync(
        textWord,
        fontFamily: 'Pallavi Bold',
      )?.runes,
      const <int>[0xF066, 0xF0C9, 0xF0BF, 0xF0F9, 0xF0BC, 0xF0E0],
    );
  });

  test('reverse converts private legacy Telugu text', () {
    final rawLegacyText = String.fromCharCodes(const <int>[
      0xF05C,
      0xF0BF,
      0xF0EC,
      0xF0EB,
    ]);

    expect(
      TeluguLegacyTextService.reverseConvertSync(rawLegacyText),
      'లక్ష్మి',
    );
  });
}
