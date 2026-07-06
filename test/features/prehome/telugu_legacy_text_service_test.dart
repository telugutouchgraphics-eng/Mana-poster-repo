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

  test('keeps Telugu three-consonant clusters in legacy conversion', () {
    const source = 'రాష్ట్ర';
    final legacy = TeluguLegacyOfflineConverter.convert(source);

    expect(legacy, isNot(source));
    expect(TeluguLegacyTextService.reverseConvertSync(legacy), source);
  });

  test('keeps Telugu vocalic-r signs in legacy conversion', () {
    final samples = <String>[
      String.fromCharCodes(const <int>[0x0C05, 0x0C2E, 0x0C43, 0x0C24]),
      String.fromCharCodes(const <int>[0x0C15, 0x0C43, 0x0C24, 0x0C3F]),
      String.fromCharCodes(
        const <int>[0x0C38, 0x0C4D, 0x0C2E, 0x0C43, 0x0C24, 0x0C3F],
      ),
      String.fromCharCodes(
        const <int>[
          0x0C2E,
          0x0C3E,
          0x0C24,
          0x0C43,
          0x0C2D,
          0x0C3E,
          0x0C37,
        ],
      ),
      String.fromCharCodes(
        const <int>[0x0C26, 0x0C43, 0x0C37, 0x0C4D, 0x0C1F, 0x0C3F],
      ),
      String.fromCharCodes(
        const <int>[0x0C35, 0x0C43, 0x0C26, 0x0C4D, 0x0C27, 0x0C3F],
      ),
    ];

    for (final source in samples) {
      final legacy = TeluguLegacyOfflineConverter.convert(source);

      expect(legacy, isNot(source));
      expect(legacy.runes, contains(0xF07F));
      expect(TeluguLegacyTextService.reverseConvertSync(legacy), source);
    }
  });

  test('uses trailing ra-vattu order for decorative legacy fonts', () {
    final source = String.fromCharCodes(
      const <int>[0x0C2A, 0x0C4D, 0x0C30, 0x0C17, 0x0C24, 0x0C3F],
    );
    final pallavi = TeluguLegacyTextService.convertSync(
      source,
      fontFamily: 'Pallavi Bold',
    );
    final amrutha = TeluguLegacyTextService.convertSync(
      source,
      fontFamily: 'Amrutha',
    );
    final bapuBrush = TeluguLegacyTextService.convertSync(
      source,
      fontFamily: 'Bapu Brush',
    );
    final ramanaBrush = TeluguLegacyTextService.convertSync(
      source,
      fontFamily: 'Ramana Brush',
    );

    expect(pallavi!.runes.take(3), const <int>[0xF0E7, 0xF07C, 0xF09F]);
    expect(amrutha!.runes.take(3), const <int>[0xF07C, 0xF09F, 0xF0E7]);
    expect(bapuBrush!.runes.take(3), const <int>[0xF07C, 0xF09F, 0xF0E7]);
    expect(ramanaBrush!.runes.take(3), const <int>[0xF07C, 0xF09F, 0xF0E7]);
  });

  test('reverse converts PSD mixed ASCII/private legacy Telugu text', () {
    final rawPsdText = String.fromCharCodes(const <int>[
      0x4e,
      0xf0bf,
      0xf0a3,
      0x7b,
      0xf0ec,
      0xf093,
      0x20,
      0xf0d4,
      0xf0e1,
      0x5d,
      0x24,
      0x54,
      0xf0bf,
      0x3d,
      0x7b,
      0xf0ec,
      0xf0bc,
      0x20,
      0x79,
      0xf0ee,
      0x5c,
      0x54,
      0x3e,
      0xf0b7,
      0x54,
      0x5c,
      0x71,
      0x54,
      0x0a,
      0xf093,
      0x2b,
      0xf09d,
      0x7c,
      0x20,
      0xf087,
      0x20,
      0x42,
      0x62,
      0xf0cd,
      0x65,
      0x5b,
      0x20,
      0x7c,
      0xf09f,
      0x2b,
      0x26,
      0xf083,
      0x54,
      0x3e,
      0xf0b7,
      0x0a,
      0xf0e7,
      0x7c,
      0xf09f,
      0xf0c8,
      0x5c,
      0x2b,
      0x3c,
      0xf08a,
      0x5d,
      0x20,
      0x4a,
      0x24,
      0xf0d4,
      0xf090,
      0xf0fd,
      0xf0cb,
      0xf0a2,
      0x20,
      0x64,
      0xf09f,
      0x5d,
      0xf0bf,
      0x3d,
      0xf0d4,
      0xf0e1,
      0xf0ef,
      0x20,
      0xf0bf,
      0xf0b1,
      0x2b,
      0xf0d4,
      0xf0e1,
      0x54,
      0x5c,
      0x54,
      0x0a,
      0xf093,
      0x2b,
      0x62,
      0xf0cd,
      0x5c,
      0xf093,
      0x2c,
      0x20,
      0xf0e7,
      0x7c,
      0xf09f,
      0xf0dc,
      0x20,
      0xf0ff,
      0xf0bf,
      0xf0a3,
      0xf0d8,
      0x73,
      0xf0c1,
      0xf0d6,
      0x20,
      0xf080,
      0x71,
      0x2b,
      0x3c,
      0xf0c3,
      0xf0d4,
      0xf090,
      0xf0e0,
      0x56,
      0xf09f,
      0xf0e4,
      0x5c,
      0x0a,
      0x65,
      0x54,
      0x3c,
      0xf0f3,
      0xf08a,
      0xf0ab,
      0x2c,
      0x20,
      0x64,
      0xf09f,
      0x54,
      0x73,
      0xf0c1,
      0xf0bf,
      0xf0ec,
      0xf08c,
      0xf0d4,
      0xf0e1,
      0x2b,
      0x3e,
      0xf0b1,
      0x2e,
      0x2e,
      0x2e,
      0xf087,
      0x20,
      0x79,
      0xf0ee,
      0x5c,
      0x54,
      0x3e,
      0xf0b7,
      0x54,
      0x5c,
      0x20,
      0x7c,
      0xf09f,
      0x2b,
      0x26,
      0xf083,
      0x54,
      0x3e,
      0xf0b7,
      0x71,
      0x54,
      0x0a,
      0xf0c8,
      0x73,
      0xf0c1,
      0x54,
      0x7c,
      0xf09f,
      0xf0da,
      0xf0bf,
      0xf0c3,
      0x79,
      0xf090,
      0x5c,
      0xf093,
      0x20,
      0xf0bf,
      0xf0c3,
      0x73,
      0xf0c1,
      0x54,
      0xf0c5,
      0xf0a3,
      0xf094,
      0x2b,
      0xf0b3,
      0xf0d6,
      0x2e,
      0x2e,
      0x2e,
      0x0a,
      0x4d,
      0x54,
      0xf0c5,
      0xf0a3,
      0xf094,
      0x20,
      0x4d,
      0x54,
      0x20,
      0xf0c5,
      0xf0a3,
      0xf094,
      0xf0b3,
      0x54,
      0x2b,
      0xf08b,
      0x20,
      0x64,
      0xf09f,
      0x75,
      0xf0f3,
      0xf084,
      0x54,
      0xf0ab,
      0x5c,
      0xf0c5,
      0xf0a3,
      0xf094,
    ]);
    const expected = '''
చీకటిని తరిమికొట్టి వెలుగులను
నింపే ఈ దీపావళి పండుగ
ప్రజలందరి జీవితాల్లో సరికొత్త కాంతులు
నింపాలని, ప్రతి ఒక్కరూ ఆనందోత్సాహాల
మధ్య, సురక్షితంగా...ఈ వెలుగుల పండుగను
జరుపుకోవాలని కోరుకుంటూ...
మీకు మీ కుటుంబ సభ్యులకు''';

    final converted = TeluguLegacyTextService.reverseConvertSync(rawPsdText);

    expect(converted, expected);
    expect(RegExp(r'[\uE000-\uF8FF]').hasMatch(converted), isFalse);
  });
}
