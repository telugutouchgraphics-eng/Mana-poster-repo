import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui show Image, ImageByteFormat;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_background_remover/image_background_remover.dart';
import 'package:path_provider/path_provider.dart';

class BackgroundRemovalResult {
  const BackgroundRemovalResult({
    required this.pngBytes,
    required this.engineLabel,
    required this.didRemoveBackground,
    this.outputFilePath,
  });

  final Uint8List pngBytes;
  final String engineLabel;
  final bool didRemoveBackground;
  final String? outputFilePath;
}

class OfflineBackgroundRemovalService {
  const OfflineBackgroundRemovalService();

  static Future<void>? _initialization;
  static Future<void> _serialQueue = Future<void>.value();

  void _debugLogStack(String message, StackTrace stackTrace) {
    if (!kDebugMode) {
      return;
    }
    debugPrint(message);
    debugPrintStack(stackTrace: stackTrace);
  }

  static Future<void> warmUp() {
    return const OfflineBackgroundRemovalService().ensureReady();
  }

  Future<void> ensureReady() {
    return _initialization ??= (() async {
      try {
        await BackgroundRemover.instance.initializeOrt();
      } catch (error, stackTrace) {
        _debugLogStack(
          'BackgroundRemover.initializeOrt failed: $error',
          stackTrace,
        );
        rethrow;
      }
    })();
  }

  Future<T> _runSerialized<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    _serialQueue = _serialQueue.catchError((_) {}).then((_) async {
      try {
        final result = await action();
        completer.complete(result);
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  Future<BackgroundRemovalResult> removeBackground(Uint8List imageBytes) async {
    return _runSerialized(() async {
      await ensureReady();
      ui.Image? resultImage;
      try {
        resultImage = await BackgroundRemover.instance.removeBg(imageBytes);
      } catch (error, stackTrace) {
        _debugLogStack(
          'BackgroundRemover.removeBg failed: $error',
          stackTrace,
        );
        rethrow;
      }
      try {
        final byteData = await resultImage.toByteData(
          format: ui.ImageByteFormat.png,
        );
        if (byteData == null) {
          throw Exception('PNG encode failed');
        }
        final pngBytes = await _decontaminateRemovedImage(
          byteData.buffer.asUint8List(),
        );
        final tempFile = await _persistTempPng(pngBytes);
        return BackgroundRemovalResult(
          pngBytes: pngBytes,
          engineLabel: 'image_background_remover',
          didRemoveBackground: true,
          outputFilePath: tempFile.path,
        );
      } finally {
        resultImage.dispose();
      }
    });
  }

  Future<Uint8List> finalizeCutout(Uint8List pngBytes) async {
    return compute(_decontaminateRemovedImageBytes, pngBytes);
  }

  Future<File> _persistTempPng(Uint8List pngBytes) async {
    final tempDir = await getTemporaryDirectory();
    final file = File(
      '${tempDir.path}${Platform.pathSeparator}bg_removed_${DateTime.now().microsecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(pngBytes, flush: true);
    return file;
  }

  Future<Uint8List> _decontaminateRemovedImage(Uint8List pngBytes) async {
    return compute(_decontaminateRemovedImageBytes, pngBytes);
  }
}

int _blendChannel(int from, int to, double weight) {
  return (from + ((to - from) * weight)).round().clamp(0, 255);
}

int _channelMax3(int a, int b, int c) {
  return math.max(a, math.max(b, c));
}

int _channelMin3(int a, int b, int c) {
  return math.min(a, math.min(b, c));
}

Uint8List _decontaminateRemovedImageBytes(Uint8List pngBytes) {
  final decoded = img.decodeImage(pngBytes);
  if (decoded == null) {
    return pngBytes;
  }
  final output = img.Image.from(decoded).convert(numChannels: 4);
  final width = output.width;
  final height = output.height;
  final alphaMap = List<int>.filled(width * height, 0);

  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      alphaMap[(y * width) + x] = output.getPixel(x, y).a.toInt();
    }
  }

  const neighborOffsets = <List<int>>[
    [-1, -1], [0, -1], [1, -1],
    [-1, 0], [1, 0],
    [-1, 1], [0, 1], [1, 1],
  ];

  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final index = (y * width) + x;
      final alpha = alphaMap[index];
      if (alpha <= 0) {
        continue;
      }

      var transparentNeighbors = 0;
      var strongNeighborCount = 0;
      var strongRed = 0.0;
      var strongGreen = 0.0;
      var strongBlue = 0.0;

      for (final offset in neighborOffsets) {
        final nx = x + offset[0];
        final ny = y + offset[1];
        if (nx < 0 || ny < 0 || nx >= width || ny >= height) {
          transparentNeighbors++;
          continue;
        }
        final neighborAlpha = alphaMap[(ny * width) + nx];
        if (neighborAlpha < 8) {
          transparentNeighbors++;
        }
        if (neighborAlpha >= math.max(160, alpha + 24)) {
          final neighborPixel = output.getPixel(nx, ny);
          strongRed += neighborPixel.r.toDouble();
          strongGreen += neighborPixel.g.toDouble();
          strongBlue += neighborPixel.b.toDouble();
          strongNeighborCount++;
        }
      }

      final isEdgePixel = transparentNeighbors > 0 || alpha < 245;
      if (!isEdgePixel) {
        continue;
      }

      final pixel = output.getPixel(x, y);
      final alphaFraction = alpha / 255.0;
      final fringeStrength = ((transparentNeighbors / 8.0) * (1 - alphaFraction))
          .clamp(0.0, 1.0);

      int unmatte(int channel) {
        final corrected =
            ((channel / 255.0) - (1.0 - alphaFraction)) /
            math.max(alphaFraction, 0.001);
        return (corrected * 255.0).round().clamp(0, 255);
      }

      var red = pixel.r.toInt();
      var green = pixel.g.toInt();
      var blue = pixel.b.toInt();

      final correctedRed = unmatte(red);
      final correctedGreen = unmatte(green);
      final correctedBlue = unmatte(blue);
      final decontaminateBlend = (0.55 + (fringeStrength * 0.35)).clamp(
        0.0,
        0.92,
      );

      red = _blendChannel(red, correctedRed, decontaminateBlend);
      green = _blendChannel(green, correctedGreen, decontaminateBlend);
      blue = _blendChannel(blue, correctedBlue, decontaminateBlend);

      if (strongNeighborCount > 0) {
        final avgRed = (strongRed / strongNeighborCount).round();
        final avgGreen = (strongGreen / strongNeighborCount).round();
        final avgBlue = (strongBlue / strongNeighborCount).round();
        final inwardBlend = (0.12 + (fringeStrength * 0.28)).clamp(0.0, 0.4);
        red = _blendChannel(red, avgRed, inwardBlend);
        green = _blendChannel(green, avgGreen, inwardBlend);
        blue = _blendChannel(blue, avgBlue, inwardBlend);
      }

      var nextAlpha = alpha;
      if (transparentNeighbors > 0) {
        final contractAmount =
            (fringeStrength * 22).round() +
            (alpha < 160 ? 6 : 0) +
            (alpha < 96 ? 6 : 0);
        nextAlpha = (alpha - contractAmount).clamp(0, 255);
      }

      // White or near-white edge mattes become visible on posters when the
      // source photo background is bright. Trim those edge pixels a bit more
      // so the subject stays clean without a light halo.
      if (transparentNeighbors > 0) {
        final brightness = (red + green + blue) / 3.0;
        final spread = _channelMax3(red, green, blue) - _channelMin3(red, green, blue);
        final looksLikeWhiteMatte = brightness > 214 && spread < 44;
        final looksLikeVeryBrightFringe = brightness > 235 && spread < 64;

        if (looksLikeWhiteMatte || looksLikeVeryBrightFringe) {
          final extraTrim =
              ((brightness - 210) * 0.55).round() +
              (fringeStrength * 26).round() +
              (looksLikeWhiteMatte ? 12 : 0);
          nextAlpha = (nextAlpha - extraTrim).clamp(0, 255);
        }
      }

      output.setPixelRgba(x, y, red, green, blue, nextAlpha);
    }
  }

  return Uint8List.fromList(img.encodePng(output));
}
