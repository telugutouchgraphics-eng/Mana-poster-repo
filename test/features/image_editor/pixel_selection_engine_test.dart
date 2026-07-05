import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:mana_poster/features/image_editor/screens/image_editor_screen.dart';

void main() {
  test('pixel selection trims transparent padding to visible alpha bounds', () {
    final source = img.Image(width: 10, height: 8, numChannels: 4);
    for (var y = 2; y <= 4; y++) {
      for (var x = 3; x <= 5; x++) {
        source.setPixelRgba(x, y, 220, 40, 30, 255);
      }
    }

    final result = extractPixelSelectionBytesForTesting(<String, Object?>{
      'bytes': Uint8List.fromList(img.encodePng(source)),
      'mode': 0,
      'points': <double>[0, 0, 1, 1],
      'feather': 0.0,
    });

    expect(result['cropLeft'], 3);
    expect(result['cropTop'], 2);
    expect(result['cropWidth'], 3);
    expect(result['cropHeight'], 3);
    final cropped = img.decodePng(result['selection']! as Uint8List);
    expect(cropped, isNotNull);
    expect(cropped!.width, 3);
    expect(cropped.height, 3);
  });

  test('pixel selection reports an empty transparent selection', () {
    final source = img.Image(width: 6, height: 4, numChannels: 4);

    final result = extractPixelSelectionBytesForTesting(<String, Object?>{
      'bytes': Uint8List.fromList(img.encodePng(source)),
      'mode': 0,
      'points': <double>[0, 0, 1, 1],
      'feather': 0.0,
    });

    expect(result['empty'], isTrue);
    expect(result['selection'], isNull);
  });
}
