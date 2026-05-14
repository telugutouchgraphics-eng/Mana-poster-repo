import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui show Image, ImageByteFormat;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_background_remover/image_background_remover.dart';

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
        resultImage = await BackgroundRemover.instance.removeBg(
          imageBytes,
          threshold: 0.52,
          smoothMask: true,
          enhanceEdges: true,
        );
      } catch (error, stackTrace) {
        _debugLogStack('BackgroundRemover.removeBg failed: $error', stackTrace);
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
        return BackgroundRemovalResult(
          pngBytes: pngBytes,
          engineLabel: 'image_background_remover',
          didRemoveBackground: true,
          outputFilePath: null,
        );
      } finally {
        resultImage.dispose();
      }
    });
  }

  Future<Uint8List> finalizeCutout(Uint8List pngBytes) async {
    return compute(_decontaminateRemovedImageBytes, pngBytes);
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
    [-1, -1],
    [0, -1],
    [1, -1],
    [-1, 0],
    [1, 0],
    [-1, 1],
    [0, 1],
    [1, 1],
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
      final fringeStrength =
          ((transparentNeighbors / 8.0) * (1 - alphaFraction)).clamp(0.0, 1.0);

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
      final decontaminateBlend = (0.68 + (fringeStrength * 0.24)).clamp(
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
        final inwardBlend = (0.28 + (fringeStrength * 0.36)).clamp(0.0, 0.64);
        red = _blendChannel(red, avgRed, inwardBlend);
        green = _blendChannel(green, avgGreen, inwardBlend);
        blue = _blendChannel(blue, avgBlue, inwardBlend);
      }

      var nextAlpha = alpha;
      if (transparentNeighbors > 0) {
        final contractAmount =
            (fringeStrength * 10).round() + (alpha < 72 ? 4 : 0);
        nextAlpha = (alpha - contractAmount).clamp(0, 255);
      }

      // Bright/dark edge mattes become visible on posters. Pull their color
      // inward and trim alpha only at the edge, so the cutout stays soft.
      if (transparentNeighbors > 0) {
        final brightness = (red + green + blue) / 3.0;
        final spread =
            _channelMax3(red, green, blue) - _channelMin3(red, green, blue);
        final looksLikeWhiteMatte = brightness > 214 && spread < 44;
        final looksLikeVeryBrightFringe = brightness > 235 && spread < 64;
        final looksLikeBlackMatte = brightness < 48 && spread < 48;
        final looksLikeVeryDarkFringe = brightness < 26 && spread < 68;

        final hasMatte =
            looksLikeWhiteMatte ||
            looksLikeVeryBrightFringe ||
            looksLikeBlackMatte ||
            looksLikeVeryDarkFringe;
        if (hasMatte) {
          if (strongNeighborCount > 0) {
            final avgRed = (strongRed / strongNeighborCount).round();
            final avgGreen = (strongGreen / strongNeighborCount).round();
            final avgBlue = (strongBlue / strongNeighborCount).round();
            final matteBlend = (0.5 + (fringeStrength * 0.28)).clamp(0.0, 0.78);
            red = _blendChannel(red, avgRed, matteBlend);
            green = _blendChannel(green, avgGreen, matteBlend);
            blue = _blendChannel(blue, avgBlue, matteBlend);
          }

          final whiteTrim = looksLikeWhiteMatte || looksLikeVeryBrightFringe
              ? ((brightness - 210) * 0.32).round()
              : 0;
          final blackTrim = looksLikeBlackMatte || looksLikeVeryDarkFringe
              ? ((54 - brightness) * 0.36).round()
              : 0;
          final extraTrim =
              whiteTrim +
              blackTrim +
              (fringeStrength * 14).round() +
              (hasMatte ? 5 : 0);
          nextAlpha = (nextAlpha - extraTrim).clamp(0, 255);
        }
      }

      output.setPixelRgba(x, y, red, green, blue, nextAlpha);
    }
  }

  _softenCutoutEdges(output);
  return Uint8List.fromList(img.encodePng(output));
}

void _softenCutoutEdges(img.Image output) {
  final width = output.width;
  final height = output.height;
  final alphaMap = List<int>.filled(width * height, 0);

  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      alphaMap[(y * width) + x] = output.getPixel(x, y).a.toInt();
    }
  }

  bool hasTransparentNeighbor(int x, int y) {
    for (var dy = -2; dy <= 2; dy++) {
      for (var dx = -2; dx <= 2; dx++) {
        if (dx == 0 && dy == 0) {
          continue;
        }
        final nx = x + dx;
        final ny = y + dy;
        if (nx < 0 || ny < 0 || nx >= width || ny >= height) {
          return true;
        }
        if (alphaMap[(ny * width) + nx] < 24) {
          return true;
        }
      }
    }
    return false;
  }

  ({int red, int green, int blue})? nearestSolidColor(int x, int y) {
    var totalWeight = 0.0;
    var red = 0.0;
    var green = 0.0;
    var blue = 0.0;
    for (var dy = -5; dy <= 5; dy++) {
      for (var dx = -5; dx <= 5; dx++) {
        final nx = x + dx;
        final ny = y + dy;
        if (nx < 0 || ny < 0 || nx >= width || ny >= height) {
          continue;
        }
        final neighborAlpha = alphaMap[(ny * width) + nx];
        if (neighborAlpha < 210) {
          continue;
        }
        final distance = math.sqrt((dx * dx) + (dy * dy));
        if (distance > 5) {
          continue;
        }
        final weight = (1 / (1 + distance)) * (neighborAlpha / 255.0);
        final pixel = output.getPixel(nx, ny);
        red += pixel.r * weight;
        green += pixel.g * weight;
        blue += pixel.b * weight;
        totalWeight += weight;
      }
    }
    if (totalWeight <= 0) {
      return null;
    }
    return (
      red: (red / totalWeight).round().clamp(0, 255),
      green: (green / totalWeight).round().clamp(0, 255),
      blue: (blue / totalWeight).round().clamp(0, 255),
    );
  }

  final updates = <({int x, int y, int red, int green, int blue, int alpha})>[];

  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final index = (y * width) + x;
      final alpha = alphaMap[index];
      final edge = alpha > 0 && (alpha < 250 || hasTransparentNeighbor(x, y));
      final outsideEdge =
          alpha == 0 && _hasOpaqueNeighbor(alphaMap, width, height, x, y);
      if (!edge && !outsideEdge) {
        continue;
      }
      final solid = nearestSolidColor(x, y);
      if (solid == null) {
        continue;
      }
      final pixel = output.getPixel(x, y);

      if (outsideEdge) {
        updates.add((
          x: x,
          y: y,
          red: solid.red,
          green: solid.green,
          blue: solid.blue,
          alpha: 22,
        ));
        continue;
      }

      final blend = alpha < 190 ? 0.84 : 0.58;
      final nextAlpha = hasTransparentNeighbor(x, y)
          ? math.min(alpha, alpha > 225 ? 218 : alpha)
          : alpha;
      updates.add((
        x: x,
        y: y,
        red: _blendChannel(pixel.r.toInt(), solid.red, blend),
        green: _blendChannel(pixel.g.toInt(), solid.green, blend),
        blue: _blendChannel(pixel.b.toInt(), solid.blue, blend),
        alpha: nextAlpha,
      ));
    }
  }

  for (final update in updates) {
    output.setPixelRgba(
      update.x,
      update.y,
      update.red,
      update.green,
      update.blue,
      update.alpha,
    );
  }
}

bool _hasOpaqueNeighbor(
  List<int> alphaMap,
  int width,
  int height,
  int x,
  int y,
) {
  for (var dy = -2; dy <= 2; dy++) {
    for (var dx = -2; dx <= 2; dx++) {
      final nx = x + dx;
      final ny = y + dy;
      if (nx < 0 || ny < 0 || nx >= width || ny >= height) {
        continue;
      }
      if (alphaMap[(ny * width) + nx] > 210) {
        return true;
      }
    }
  }
  return false;
}
