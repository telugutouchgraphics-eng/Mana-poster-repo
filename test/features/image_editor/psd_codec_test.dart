import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:mana_poster/features/image_editor/screens/image_editor_screen.dart';
import 'package:psd_sdk/psd_sdk.dart' as psd;

void main() {
  test('PSD engine font decoder handles escaped UTF-16 names', () {
    final escapedName = Uint8List.fromList(
      r'\376\377\000P\000a\000l\000l\000a\000v\000i\000B\000o\000l\000d'
          .codeUnits,
    );

    expect(debugDecodePsdEngineNameForTest(escapedName), 'PallaviBold');
  });

  test('PSD type tool scale preserves transformed text size', () {
    final data = ByteData(50);
    data.setUint16(0, 1);
    data.setFloat64(2, 1);
    data.setFloat64(10, 0);
    data.setFloat64(18, 0);
    data.setFloat64(26, 0.625);
    data.setFloat64(34, 120);
    data.setFloat64(42, 80);

    expect(
      debugExtractPsdTypeToolVerticalScaleForTest(data.buffer.asUint8List()),
      closeTo(0.625, 0.000001),
    );
  });

  test('Pallavi fonts use legacy Telugu text conversion', () async {
    for (final family in const <String>[
      'Pallavi Bold',
      'Pallavi Medium',
      'Pallavi Thin',
    ]) {
      expect(debugIsLegacyTeluguFontFamilyForTest(family), isTrue);
      expect(
        debugResolveTextRenderFontFamilyForTest(family),
        'Anek Telugu Condensed Regular',
      );
      final converted = await debugResolveLegacyRenderTextForTest(
        text: 'తెలుగు',
        fontFamily: family,
      );
      expect(converted, isNotNull);
      expect(converted, isNotEmpty);
    }
  });

  test('Telugu font classification matches bundled font folders', () {
    final legacyFamilies = _pubspecFontFamiliesForAssetDir('telugu_legacy');
    final unicodeFamilies = _pubspecFontFamiliesForAssetDir('telugu_unicode');

    expect(legacyFamilies, isNotEmpty);
    expect(unicodeFamilies, isNotEmpty);

    for (final family in legacyFamilies) {
      expect(
        debugIsLegacyTeluguFontFamilyForTest(family),
        isTrue,
        reason: '$family must use legacy Telugu conversion',
      );
    }

    for (final family in unicodeFamilies) {
      expect(
        debugIsLegacyTeluguFontFamilyForTest(family),
        isFalse,
        reason: '$family must render as Unicode Telugu',
      );
      expect(debugResolveTextRenderFontFamilyForTest(family), family);
    }
  });

  test('PSD codec preserves layered 8-bit RGBA channels', () {
    const width = 3;
    const height = 2;
    final rgba = Uint8List.fromList(<int>[
      255,
      0,
      0,
      255,
      0,
      255,
      0,
      128,
      0,
      0,
      255,
      0,
      255,
      255,
      0,
      255,
      255,
      0,
      255,
      200,
      0,
      255,
      255,
      64,
    ]);
    final channels = _splitRgba(width, height, rgba);
    final document = psd.ExportDocument(
      width,
      height,
      8,
      psd.ExportColorMode.rgb,
    );
    final layer = document.addLayer(document, 'Layer 1');
    expect(layer, isNotNull);
    document
      ..updateMergedImage(channels.red, channels.green, channels.blue)
      ..updateLayer(
        layer!,
        psd.ExportChannel.red,
        0,
        0,
        width,
        height,
        channels.red,
        psd.CompressionType.rle,
      )
      ..updateLayer(
        layer,
        psd.ExportChannel.green,
        0,
        0,
        width,
        height,
        channels.green,
        psd.CompressionType.rle,
      )
      ..updateLayer(
        layer,
        psd.ExportChannel.blue,
        0,
        0,
        width,
        height,
        channels.blue,
        psd.CompressionType.rle,
      )
      ..updateLayer(
        layer,
        psd.ExportChannel.alpha,
        0,
        0,
        width,
        height,
        channels.alpha,
        psd.CompressionType.rle,
      );

    final file = psd.File();
    document.write(file);
    final output = file.bytes;
    expect(output, isNotNull);
    expect(output, isNotEmpty);

    final parsedFile = psd.File.fromByteData(output!);
    final parsedDocument = psd.Document.fromFile(parsedFile);
    expect(parsedDocument.width, width);
    expect(parsedDocument.height, height);
    expect(parsedDocument.bitsPerChannel, 8);
    expect(parsedDocument.colorMode, psd.ColorMode.rgb);

    final parsedLayer = parsedDocument
        .parseLayerMaskSection(parsedFile)
        ?.layers
        ?.whereType<psd.Layer>()
        .firstOrNull;
    expect(parsedLayer, isNotNull);
    parsedLayer!.extract(parsedFile);
    final decoded = psd.interleaveRGBA(
      parsedLayer.findChannel(psd.ChannelType.r)?.data,
      parsedLayer.findChannel(psd.ChannelType.g)?.data,
      parsedLayer.findChannel(psd.ChannelType.b)?.data,
      parsedLayer.findChannel(psd.ChannelType.transparencyMask)?.data,
      8,
      width,
      height,
    );
    expect(decoded, rgba);
  });

  test('PSD editor decoder preserves layer bounds and visible pixels', () {
    const canvasWidth = 5;
    const canvasHeight = 4;
    const layerWidth = 2;
    const layerHeight = 2;
    final rgba = Uint8List.fromList(<int>[
      255,
      0,
      0,
      255,
      0,
      255,
      0,
      128,
      0,
      0,
      255,
      64,
      255,
      255,
      0,
      0,
    ]);
    final channels = _splitRgba(layerWidth, layerHeight, rgba);
    final merged = Uint8List(canvasWidth * canvasHeight * 4);
    final mergedChannels = _splitRgba(canvasWidth, canvasHeight, merged);
    final document = psd.ExportDocument(
      canvasWidth,
      canvasHeight,
      8,
      psd.ExportColorMode.rgb,
    );
    document.updateMergedImage(
      mergedChannels.red,
      mergedChannels.green,
      mergedChannels.blue,
    );
    final layer = document.addLayer(document, 'Offset Layer');
    expect(layer, isNotNull);
    document
      ..updateLayer(
        layer!,
        psd.ExportChannel.red,
        1,
        1,
        3,
        3,
        channels.red,
        psd.CompressionType.rle,
      )
      ..updateLayer(
        layer,
        psd.ExportChannel.green,
        1,
        1,
        3,
        3,
        channels.green,
        psd.CompressionType.rle,
      )
      ..updateLayer(
        layer,
        psd.ExportChannel.blue,
        1,
        1,
        3,
        3,
        channels.blue,
        psd.CompressionType.rle,
      )
      ..updateLayer(
        layer,
        psd.ExportChannel.alpha,
        1,
        1,
        3,
        3,
        channels.alpha,
        psd.CompressionType.rle,
      );
    final file = psd.File();
    document.write(file);

    final payload = debugDecodePsdToEditorPayloadForTest(file.bytes!);

    expect(payload, isNotNull);
    expect(payload!['error'], isNull);
    expect(payload['width'], canvasWidth);
    expect(payload['height'], canvasHeight);
    final layers = payload['layers'] as List<Object?>;
    expect(layers, hasLength(1));
    final decodedLayer = layers.single as Map<String, Object?>;
    expect(decodedLayer['name'], 'Offset Layer');
    expect(decodedLayer['left'], 1);
    expect(decodedLayer['top'], 1);
    expect(decodedLayer['right'], 3);
    expect(decodedLayer['bottom'], 3);

    final decodedImage = img.decodePng(decodedLayer['bytes']! as Uint8List);
    expect(decodedImage, isNotNull);
    expect(decodedImage!.width, layerWidth);
    expect(decodedImage.height, layerHeight);
    expect(_pixelRgba(decodedImage, 0, 0), <int>[255, 0, 0, 255]);
    expect(_pixelRgba(decodedImage, 1, 0), <int>[0, 255, 0, 128]);
    expect(_pixelRgba(decodedImage, 0, 1), <int>[0, 0, 255, 64]);
    expect(_pixelRgba(decodedImage, 1, 1), <int>[255, 255, 0, 0]);
  });

  test('PSD layered exporter preserves RGBA pixels per layer', () {
    const width = 3;
    const height = 2;
    final mergedRgba = Uint8List.fromList(<int>[
      10,
      20,
      30,
      255,
      40,
      50,
      60,
      255,
      70,
      80,
      90,
      255,
      100,
      110,
      120,
      255,
      130,
      140,
      150,
      255,
      160,
      170,
      180,
      255,
    ]);
    final firstLayer = Uint8List.fromList(<int>[
      255,
      0,
      0,
      255,
      255,
      0,
      0,
      128,
      255,
      0,
      0,
      0,
      255,
      0,
      0,
      255,
      255,
      0,
      0,
      128,
      255,
      0,
      0,
      0,
    ]);
    final secondLayer = Uint8List.fromList(<int>[
      0,
      0,
      255,
      0,
      0,
      0,
      255,
      128,
      0,
      0,
      255,
      255,
      0,
      0,
      255,
      0,
      0,
      0,
      255,
      128,
      0,
      0,
      255,
      255,
    ]);

    final output = debugEncodeLayeredPsdFromRgbaPayloadForTest(
      <String, Object?>{
        'width': width,
        'height': height,
        'mergedRgba': mergedRgba,
        'layers': <Map<String, Object?>>[
          <String, Object?>{'name': 'Red Layer', 'rgba': firstLayer},
          <String, Object?>{'name': 'Blue Layer', 'rgba': secondLayer},
        ],
      },
    );

    final parsedFile = psd.File.fromByteData(output);
    final parsedDocument = psd.Document.fromFile(parsedFile);
    expect(parsedDocument.width, width);
    expect(parsedDocument.height, height);
    expect(parsedDocument.bitsPerChannel, 8);
    expect(parsedDocument.colorMode, psd.ColorMode.rgb);

    final parsedLayers = parsedDocument
        .parseLayerMaskSection(parsedFile)
        ?.layers
        ?.whereType<psd.Layer>()
        .toList(growable: false);
    expect(parsedLayers, isNotNull);
    expect(parsedLayers, hasLength(2));
    expect(_psdLayerName(parsedLayers![0]), 'Red Layer');
    expect(_psdLayerName(parsedLayers[1]), 'Blue Layer');
    expect(
      _decodedLayerRgba(parsedFile, parsedLayers[0], width, height),
      firstLayer,
    );
    expect(
      _decodedLayerRgba(parsedFile, parsedLayers[1], width, height),
      secondLayer,
    );
  });

  test('PSD layered exporter rejects invalid merged payload size', () {
    expect(
      () => debugEncodeLayeredPsdFromRgbaPayloadForTest(<String, Object?>{
        'width': 2,
        'height': 2,
        'mergedRgba': Uint8List(2 * 2 * 4 + 1),
        'layers': <Map<String, Object?>>[
          <String, Object?>{'name': 'Layer', 'rgba': Uint8List(2 * 2 * 4)},
        ],
      }),
      throwsA(
        isA<Exception>().having(
          (error) => error.toString(),
          'message',
          contains('PSD merged payload size is invalid'),
        ),
      ),
    );
  });

  test('PSD layered exporter skips invalid layers but keeps valid layers', () {
    const width = 2;
    const height = 2;
    final rgba = Uint8List.fromList(<int>[
      10,
      20,
      30,
      255,
      40,
      50,
      60,
      255,
      70,
      80,
      90,
      255,
      100,
      110,
      120,
      255,
    ]);

    final output = debugEncodeLayeredPsdFromRgbaPayloadForTest(
      <String, Object?>{
        'width': width,
        'height': height,
        'mergedRgba': rgba,
        'layers': <Map<String, Object?>>[
          <String, Object?>{
            'name': 'Invalid',
            'rgba': Uint8List(rgba.length - 1),
          },
          <String, Object?>{'name': 'Valid', 'rgba': rgba},
        ],
      },
    );

    final parsedFile = psd.File.fromByteData(output);
    final parsedDocument = psd.Document.fromFile(parsedFile);
    final parsedLayers = parsedDocument
        .parseLayerMaskSection(parsedFile)
        ?.layers
        ?.whereType<psd.Layer>()
        .toList(growable: false);
    expect(parsedLayers, isNotNull);
    expect(parsedLayers, hasLength(1));
    expect(_psdLayerName(parsedLayers!.single), 'Valid');
  });

  test('PSD layered exporter normalizes blank and long layer names', () {
    const width = 1;
    const height = 1;
    final rgba = Uint8List.fromList(<int>[1, 2, 3, 255]);
    final longName = 'Layer-${'x' * 400}';

    final output = debugEncodeLayeredPsdFromRgbaPayloadForTest(
      <String, Object?>{
        'width': width,
        'height': height,
        'mergedRgba': rgba,
        'layers': <Map<String, Object?>>[
          <String, Object?>{'name': '   ', 'rgba': rgba},
          <String, Object?>{'name': longName, 'rgba': rgba},
        ],
      },
    );

    final parsedFile = psd.File.fromByteData(output);
    final parsedDocument = psd.Document.fromFile(parsedFile);
    final parsedLayers = parsedDocument
        .parseLayerMaskSection(parsedFile)
        ?.layers
        ?.whereType<psd.Layer>()
        .toList(growable: false);

    expect(parsedLayers, isNotNull);
    expect(parsedLayers, hasLength(2));
    expect(_psdLayerName(parsedLayers![0]), 'Mana Poster Layer');
    expect(_psdLayerName(parsedLayers[1]).length, 255);
    expect(longName.startsWith(_psdLayerName(parsedLayers[1])), isTrue);
  });

  test('PSD editor decoder preserves layer opacity and hidden state', () {
    const width = 2;
    const height = 2;
    final rgba = Uint8List.fromList(<int>[
      255,
      120,
      60,
      255,
      255,
      120,
      60,
      255,
      255,
      120,
      60,
      255,
      255,
      120,
      60,
      255,
    ]);
    final output = debugEncodeLayeredPsdFromRgbaPayloadForTest(
      <String, Object?>{
        'width': width,
        'height': height,
        'mergedRgba': rgba,
        'layers': <Map<String, Object?>>[
          <String, Object?>{'name': 'Dim Hidden', 'rgba': rgba},
        ],
      },
    );
    final patched = _patchFirstLayerBlendState(
      output,
      opacity: 96,
      hidden: true,
    );

    final payload = debugDecodePsdToEditorPayloadForTest(patched);

    expect(payload, isNotNull);
    expect(payload!['error'], isNull);
    final layers = payload['layers'] as List<Object?>;
    expect(layers, hasLength(1));
    final decodedLayer = layers.single as Map<String, Object?>;
    expect(decodedLayer['name'], 'Dim Hidden');
    expect(decodedLayer['opacity'], closeTo(96 / 255, 0.0001));
    expect(decodedLayer['hidden'], isTrue);
  });

  test('PSD editor decoder rejects unsupported bit depth with clear error', () {
    final payload = debugDecodePsdToEditorPayloadForTest(
      _minimalPsdHeaderBytes(
        width: 2,
        height: 2,
        channels: 3,
        bitsPerChannel: 16,
        colorMode: 3,
      ),
    );

    expect(payload, isNotNull);
    expect(payload!['error'], 'Only 8-bit RGB PSD files are supported.');
  });

  test(
    'PSD editor decoder rejects unsupported color mode with clear error',
    () {
      final payload = debugDecodePsdToEditorPayloadForTest(
        _minimalPsdHeaderBytes(
          width: 2,
          height: 2,
          channels: 4,
          bitsPerChannel: 8,
          colorMode: 4,
        ),
      );

      expect(payload, isNotNull);
      expect(payload!['error'], 'Only RGB PSD files are supported.');
    },
  );

  test('PSD editor decoder returns safe error for malformed PSD bytes', () {
    final payload = debugDecodePsdToEditorPayloadForTest(
      Uint8List.fromList(<int>[0x38, 0x42, 0x50, 0x53, 0x00]),
    );

    expect(payload, isNotNull);
    expect(payload!['error'], 'PSD file import failed. Try another PSD.');
  });

  test('PSD editor decoder rejects oversized canvas before layer work', () {
    final payload = debugDecodePsdToEditorPayloadForTest(
      _minimalPsdHeaderBytes(
        width: 8001,
        height: 8001,
        channels: 3,
        bitsPerChannel: 8,
        colorMode: 3,
      ),
    );

    expect(payload, isNotNull);
    expect(
      payload!['error'],
      'PSD canvas is too large. Keep it under 64 megapixels for import.',
    );
  });
}

List<String> _pubspecFontFamiliesForAssetDir(String directoryName) {
  final pubspec = File('pubspec.yaml').readAsLinesSync();
  final families = <String>[];
  String? currentFamily;
  for (final line in pubspec) {
    final trimmed = line.trim();
    if (trimmed.startsWith('- family: ')) {
      currentFamily = trimmed.substring('- family: '.length).trim();
      continue;
    }
    if (trimmed.startsWith('- asset: assets/fonts/$directoryName/')) {
      final family = currentFamily;
      if (family != null && family.isNotEmpty) {
        families.add(family);
      }
    }
  }
  return families;
}

({Uint8List red, Uint8List green, Uint8List blue, Uint8List alpha}) _splitRgba(
  int width,
  int height,
  Uint8List rgba,
) {
  final pixelCount = width * height;
  final red = Uint8List(pixelCount);
  final green = Uint8List(pixelCount);
  final blue = Uint8List(pixelCount);
  final alpha = Uint8List(pixelCount);
  for (var i = 0; i < pixelCount; i++) {
    final offset = i * 4;
    red[i] = rgba[offset];
    green[i] = rgba[offset + 1];
    blue[i] = rgba[offset + 2];
    alpha[i] = rgba[offset + 3];
  }
  return (red: red, green: green, blue: blue, alpha: alpha);
}

List<int> _pixelRgba(img.Image image, int x, int y) {
  final pixel = image.getPixel(x, y);
  return <int>[
    pixel.r.toInt(),
    pixel.g.toInt(),
    pixel.b.toInt(),
    pixel.a.toInt(),
  ];
}

String _psdLayerName(psd.Layer layer) {
  final utf16Name = layer.utf16Name;
  if (utf16Name != null) {
    return String.fromCharCodes(utf16Name.where((value) => value != 0)).trim();
  }
  return (layer.name ?? '').trim();
}

Uint8List? _decodedLayerRgba(
  psd.File file,
  psd.Layer layer,
  int width,
  int height,
) {
  layer.extract(file);
  return psd.interleaveRGBA(
    layer.findChannel(psd.ChannelType.r)?.data,
    layer.findChannel(psd.ChannelType.g)?.data,
    layer.findChannel(psd.ChannelType.b)?.data,
    layer.findChannel(psd.ChannelType.transparencyMask)?.data,
    8,
    width,
    height,
  );
}

Uint8List _patchFirstLayerBlendState(
  Uint8List psdBytes, {
  required int opacity,
  required bool hidden,
}) {
  final patched = Uint8List.fromList(psdBytes);
  final data = ByteData.sublistView(patched);
  var offset = 26;
  final colorModeLength = data.getUint32(offset, Endian.big);
  offset += 4 + colorModeLength;
  final imageResourcesLength = data.getUint32(offset, Endian.big);
  offset += 4 + imageResourcesLength;
  final layerMaskLength = data.getUint32(offset, Endian.big);
  expect(layerMaskLength, greaterThan(4));
  offset += 4;
  final layerInfoLength = data.getUint32(offset, Endian.big);
  expect(layerInfoLength, greaterThan(0));
  offset += 4;
  final layerCount = data.getInt16(offset, Endian.big).abs();
  expect(layerCount, greaterThan(0));
  offset += 2;
  offset += 16;
  final channelCount = data.getUint16(offset, Endian.big);
  offset += 2 + (channelCount * 6);
  expect(String.fromCharCodes(patched.sublist(offset, offset + 4)), '8BIM');
  offset += 8;
  patched[offset] = opacity.clamp(0, 255);
  patched[offset + 2] = hidden ? 0x02 : 0x00;
  return patched;
}

Uint8List _minimalPsdHeaderBytes({
  required int width,
  required int height,
  required int channels,
  required int bitsPerChannel,
  required int colorMode,
}) {
  final builder = BytesBuilder(copy: false)
    ..add('8BPS'.codeUnits)
    ..add(_uint16(1))
    ..add(Uint8List(6))
    ..add(_uint16(channels))
    ..add(_uint32(height))
    ..add(_uint32(width))
    ..add(_uint16(bitsPerChannel))
    ..add(_uint16(colorMode))
    ..add(_uint32(0))
    ..add(_uint32(0))
    ..add(_uint32(0));
  return builder.takeBytes();
}

Uint8List _uint16(int value) {
  final data = ByteData(2)..setUint16(0, value, Endian.big);
  return data.buffer.asUint8List();
}

Uint8List _uint32(int value) {
  final data = ByteData(4)..setUint32(0, value, Endian.big);
  return data.buffer.asUint8List();
}
