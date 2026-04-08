import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui show Offset, ImageByteFormat;

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

enum BackgroundRefineMode { erase, restore }

class OfflineBackgroundRemovalService {
  const OfflineBackgroundRemovalService();

  Future<BackgroundRemovalResult> removeBackground(Uint8List imageBytes) async {
    final resultImage = await BackgroundRemover.instance.removeBg(imageBytes);
    try {
      final byteData = await resultImage.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (byteData == null) {
        throw Exception('PNG encode failed');
      }
      final pngBytes = byteData.buffer.asUint8List();
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
  }

  Future<Uint8List> applyBrushEdits({
    required Uint8List currentBytes,
    required Uint8List originalBytes,
    required BackgroundRefineMode mode,
    required List<ui.Offset> points,
    required double brushRadius,
    required double softness,
    required double strength,
  }) async {
    final current = img.decodeImage(currentBytes);
    final original = img.decodeImage(originalBytes);
    if (current == null || original == null) {
      throw Exception('Magic Tool image decode kaaledu');
    }
    if (current.width != original.width || current.height != original.height) {
      throw Exception('Magic Tool source size mismatch');
    }

    final output = img.Image.from(current).convert(numChannels: 4);
    final radiusSquared = brushRadius * brushRadius;
    final radiusInt = brushRadius.ceil();
    final normalizedSoftness = softness.clamp(0.0, 1.0);
    final normalizedStrength = strength.clamp(0.0, 1.0);
    final hardRadius = brushRadius * (1 - normalizedSoftness);

    for (final point in points) {
      final centerX = point.dx.round();
      final centerY = point.dy.round();
      final startX = (centerX - radiusInt).clamp(0, output.width - 1);
      final endX = (centerX + radiusInt).clamp(0, output.width - 1);
      final startY = (centerY - radiusInt).clamp(0, output.height - 1);
      final endY = (centerY + radiusInt).clamp(0, output.height - 1);

      for (var y = startY; y <= endY; y++) {
        for (var x = startX; x <= endX; x++) {
          final dx = x - point.dx;
          final dy = y - point.dy;
          final distanceSquared = (dx * dx) + (dy * dy);
          if (distanceSquared > radiusSquared) {
            continue;
          }
          final distance = distanceSquared == 0
              ? 0.0
              : math.sqrt(distanceSquared);
          final featherWeight = distance <= hardRadius
              ? 1.0
              : (brushRadius - distance) /
                    math.max(brushRadius - hardRadius, 0.001);
          final weight = (featherWeight.clamp(0.0, 1.0) * normalizedStrength)
              .clamp(0.0, 1.0);
          if (weight <= 0) {
            continue;
          }
          if (mode == BackgroundRefineMode.erase) {
            final pixel = output.getPixel(x, y);
            final nextAlpha = (pixel.a * (1 - weight)).round().clamp(0, 255);
            output.setPixelRgba(
              x,
              y,
              pixel.r.toInt(),
              pixel.g.toInt(),
              pixel.b.toInt(),
              nextAlpha,
            );
          } else {
            final currentPixel = output.getPixel(x, y);
            final pixel = original.getPixel(x, y);
            int blend(int from, int to) =>
                (from + ((to - from) * weight)).round().clamp(0, 255);
            output.setPixelRgba(
              x,
              y,
              blend(currentPixel.r.toInt(), pixel.r.toInt()),
              blend(currentPixel.g.toInt(), pixel.g.toInt()),
              blend(currentPixel.b.toInt(), pixel.b.toInt()),
              blend(currentPixel.a.toInt(), pixel.a.toInt()),
            );
          }
        }
      }
    }

    return Uint8List.fromList(img.encodePng(output));
  }

  Future<Uint8List> applyEdgeFeather({
    required Uint8List currentBytes,
    required double strength,
  }) async {
    final decoded = img.decodeImage(currentBytes);
    if (decoded == null) {
      throw Exception('Magic Tool image decode kaaledu');
    }
    final output = img.Image.from(decoded).convert(numChannels: 4);
    final alphaMap = List<int>.filled(output.width * output.height, 0);
    for (var y = 0; y < output.height; y++) {
      for (var x = 0; x < output.width; x++) {
        alphaMap[(y * output.width) + x] = output.getPixel(x, y).a.toInt();
      }
    }

    final passes = strength.clamp(1, 6).round();
    final smoothed = _smoothAlphaMap(
      alphaMap,
      output.width,
      output.height,
      passes: passes,
    );

    for (var y = 0; y < output.height; y++) {
      for (var x = 0; x < output.width; x++) {
        final pixel = output.getPixel(x, y);
        output.setPixelRgba(
          x,
          y,
          pixel.r.toInt(),
          pixel.g.toInt(),
          pixel.b.toInt(),
          smoothed[(y * output.width) + x],
        );
      }
    }

    return Uint8List.fromList(img.encodePng(output));
  }

  Future<Uint8List> applyEdgeSmooth({
    required Uint8List currentBytes,
    required double strength,
  }) async {
    final decoded = img.decodeImage(currentBytes);
    if (decoded == null) {
      throw Exception('Magic Tool image decode kaaledu');
    }
    final output = img.Image.from(decoded).convert(numChannels: 4);
    final alphaMap = List<int>.filled(output.width * output.height, 0);
    for (var y = 0; y < output.height; y++) {
      for (var x = 0; x < output.width; x++) {
        alphaMap[(y * output.width) + x] = output.getPixel(x, y).a.toInt();
      }
    }

    final passes = strength.clamp(1, 5).round();
    final smoothed = _smoothAlphaMap(
      alphaMap,
      output.width,
      output.height,
      passes: passes,
    );

    for (var y = 0; y < output.height; y++) {
      for (var x = 0; x < output.width; x++) {
        final pixel = output.getPixel(x, y);
        final originalAlpha = alphaMap[(y * output.width) + x];
        final smoothAlpha = smoothed[(y * output.width) + x];
        final blendedAlpha =
            ((originalAlpha * 0.35) + (smoothAlpha * 0.65)).round().clamp(
              0,
              255,
            );
        output.setPixelRgba(
          x,
          y,
          pixel.r.toInt(),
          pixel.g.toInt(),
          pixel.b.toInt(),
          blendedAlpha,
        );
      }
    }

    return Uint8List.fromList(img.encodePng(output));
  }

  Future<Uint8List> applyMaskExpansion({
    required Uint8List currentBytes,
    required double amount,
  }) async {
    final decoded = img.decodeImage(currentBytes);
    if (decoded == null) {
      throw Exception('Magic Tool image decode kaaledu');
    }
    final output = img.Image.from(decoded).convert(numChannels: 4);
    final alphaMap = List<int>.filled(output.width * output.height, 0);
    for (var y = 0; y < output.height; y++) {
      for (var x = 0; x < output.width; x++) {
        alphaMap[(y * output.width) + x] = output.getPixel(x, y).a.toInt();
      }
    }

    final iterations = amount.abs().clamp(1, 8).round();
    final expanded = _morphAlphaMap(
      alphaMap,
      output.width,
      output.height,
      passes: iterations,
      expand: amount >= 0,
    );

    for (var y = 0; y < output.height; y++) {
      for (var x = 0; x < output.width; x++) {
        final pixel = output.getPixel(x, y);
        output.setPixelRgba(
          x,
          y,
          pixel.r.toInt(),
          pixel.g.toInt(),
          pixel.b.toInt(),
          expanded[(y * output.width) + x],
        );
      }
    }

    return Uint8List.fromList(img.encodePng(output));
  }

  Future<File> _persistTempPng(Uint8List pngBytes) async {
    final tempDir = await getTemporaryDirectory();
    final file = File(
      '${tempDir.path}${Platform.pathSeparator}bg_removed_${DateTime.now().microsecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(pngBytes, flush: true);
    return file;
  }
}

List<int> _morphAlphaMap(
  List<int> alphaMap,
  int width,
  int height, {
  required int passes,
  required bool expand,
}) {
  var current = List<int>.from(alphaMap);
  const offsets = <List<int>>[
    [-1, -1], [0, -1], [1, -1],
    [-1, 0], [0, 0], [1, 0],
    [-1, 1], [0, 1], [1, 1],
  ];

  for (var pass = 0; pass < passes; pass++) {
    final next = List<int>.filled(current.length, 0);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        var chosen = current[(y * width) + x];
        for (final offset in offsets) {
          final nx = x + offset[0];
          final ny = y + offset[1];
          if (nx < 0 || ny < 0 || nx >= width || ny >= height) {
            continue;
          }
          final candidate = current[(ny * width) + nx];
          chosen = expand
              ? math.max(chosen, candidate)
              : math.min(chosen, candidate);
        }
        next[(y * width) + x] = chosen;
      }
    }
    current = next;
  }

  return current;
}

List<int> _smoothAlphaMap(
  List<int> alphaMap,
  int width,
  int height, {
  required int passes,
}) {
  var current = List<int>.from(alphaMap);
  const weights = <int>[
    1, 2, 1,
    2, 4, 2,
    1, 2, 1,
  ];
  const offsets = <List<int>>[
    [-1, -1], [0, -1], [1, -1],
    [-1, 0], [0, 0], [1, 0],
    [-1, 1], [0, 1], [1, 1],
  ];

  for (var pass = 0; pass < passes; pass++) {
    final next = List<int>.filled(current.length, 0);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        var weightedSum = 0;
        var totalWeight = 0;
        for (var i = 0; i < offsets.length; i++) {
          final nx = x + offsets[i][0];
          final ny = y + offsets[i][1];
          if (nx < 0 || ny < 0 || nx >= width || ny >= height) {
            continue;
          }
          final weight = weights[i];
          weightedSum += current[(ny * width) + nx] * weight;
          totalWeight += weight;
        }
        next[(y * width) + x] = totalWeight == 0
            ? current[(y * width) + x]
            : (weightedSum / totalWeight).round().clamp(0, 255);
      }
    }
    current = next;
  }

  return current;
}
