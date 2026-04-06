import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show Offset;

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_selfie_segmentation/google_mlkit_selfie_segmentation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import 'cloud_background_removal_service.dart';

class BackgroundRemovalResult {
  const BackgroundRemovalResult({
    required this.pngBytes,
    required this.engineLabel,
  });

  final Uint8List pngBytes;
  final String engineLabel;
}

enum BackgroundRefineMode { erase, restore }

class OfflineBackgroundRemovalService {
  const OfflineBackgroundRemovalService();

  static const Duration _cloudTimeout = Duration(seconds: 30);
  static const Duration _mlKitTimeout = Duration(seconds: 20);
  static const Duration _offlineTimeout = Duration(seconds: 20);

  Future<BackgroundRemovalResult> removeBackground(Uint8List imageBytes) async {
    final cloudService = CloudBackgroundRemovalService();
    if (cloudService.isConfigured) {
      try {
        final cloudResult = await cloudService
            .removeBackground(imageBytes)
            .timeout(_cloudTimeout);
        if (cloudResult != null) {
          final polishedBytes = await compute(
            _polishCutoutInIsolate,
            cloudResult.pngBytes,
          );
          return BackgroundRemovalResult(
            pngBytes: polishedBytes,
            engineLabel: 'Cloud rembg (open-source)',
          );
        }
      } catch (_) {
        // Fall through to on-device options when cloud path fails.
      }
    }

    final mlKitResult = await _removeBackgroundWithMlKit(
      imageBytes,
    ).timeout(_mlKitTimeout, onTimeout: () => null);
    if (mlKitResult != null) {
      final polishedBytes = await compute(_polishCutoutInIsolate, mlKitResult);
      return BackgroundRemovalResult(
        pngBytes: polishedBytes,
        engineLabel: 'Google ML Kit Selfie Segmentation',
      );
    }

    // Fallback: fully offline, no cloud/API keys and no paid SDK usage.
    final result = await compute(
      _removeBackgroundInIsolate,
      imageBytes,
    ).timeout(_offlineTimeout);
    final polishedBytes = await compute(
      _polishCutoutInIsolate,
      result.pngBytes,
    );
    return BackgroundRemovalResult(
      pngBytes: polishedBytes,
      engineLabel: '${result.engineLabel} + Edge Polish',
    );
  }

  Future<Uint8List?> _removeBackgroundWithMlKit(Uint8List imageBytes) async {
    if (kIsWeb) {
      return null;
    }

    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) {
      return null;
    }

    File? tempFile;
    final segmenter = SelfieSegmenter(mode: SegmenterMode.single);
    try {
      final tempDir = await getTemporaryDirectory();
      tempFile = File(
        '${tempDir.path}${Platform.pathSeparator}bg_source_${DateTime.now().microsecondsSinceEpoch}.jpg',
      );
      await tempFile.writeAsBytes(imageBytes, flush: true);

      final inputImage = InputImage.fromFilePath(tempFile.path);
      final mask = await segmenter.processImage(inputImage);
      if (mask == null || mask.confidences.isEmpty) {
        return null;
      }

      final output = img.Image.from(decoded);
      final alphaMap = List<int>.filled(output.width * output.height, 0);
      final confidenceBias = 0.12;

      for (var y = 0; y < output.height; y++) {
        final my = ((y / output.height) * mask.height).floor().clamp(
          0,
          mask.height - 1,
        );
        for (var x = 0; x < output.width; x++) {
          final mx = ((x / output.width) * mask.width).floor().clamp(
            0,
            mask.width - 1,
          );
          final maskIndex = (my * mask.width) + mx;
          final confidence = mask.confidences[maskIndex].clamp(0.0, 1.0);
          final fg = ((confidence - confidenceBias) / (1.0 - confidenceBias))
              .clamp(0.0, 1.0);
          alphaMap[(y * output.width) + x] = (fg * 255).round();
        }
      }

      final smoothedMask = _smoothAlphaMap(
        alphaMap,
        output.width,
        output.height,
        passes: 2,
      );

      for (var y = 0; y < output.height; y++) {
        for (var x = 0; x < output.width; x++) {
          final idx = (y * output.width) + x;
          final pixel = output.getPixel(x, y);
          final alpha = math.min(pixel.a.toInt(), smoothedMask[idx]);
          output.setPixelRgba(
            x,
            y,
            pixel.r.toInt(),
            pixel.g.toInt(),
            pixel.b.toInt(),
            alpha,
          );
        }
      }

      final transparent = _transparentRatio(output);
      final delta = _alphaDifference(decoded, output);
      if (transparent < 0.01 || delta < 0.02) {
        return null;
      }

      return Uint8List.fromList(img.encodePng(output));
    } catch (_) {
      return null;
    } finally {
      await segmenter.close();
      if (tempFile != null && await tempFile.exists()) {
        await tempFile.delete();
      }
    }
  }

  Future<Uint8List> applyBrushEdits({
    required Uint8List currentBytes,
    required Uint8List originalBytes,
    required BackgroundRefineMode mode,
    required List<Offset> points,
    required double brushRadius,
  }) async {
    return compute(_applyBrushEditsInIsolate, <String, Object>{
      'currentBytes': currentBytes,
      'originalBytes': originalBytes,
      'mode': mode.index,
      'brushRadius': brushRadius,
      'points': points
          .map((point) => <String, double>{'x': point.dx, 'y': point.dy})
          .toList(growable: false),
    });
  }

  Future<Uint8List> applyEdgeFeather({
    required Uint8List currentBytes,
    required double strength,
  }) async {
    return compute(_applyEdgeFeatherInIsolate, <String, Object>{
      'currentBytes': currentBytes,
      'strength': strength,
    });
  }
}

BackgroundRemovalResult _removeBackgroundInIsolate(Uint8List imageBytes) {
  final decoded = img.decodeImage(imageBytes);
  if (decoded == null) {
    throw Exception('Selected image decode kaaledu');
  }

  var output = _removeBackgroundEdgeFloodFill(decoded);
  var transparency = _transparentRatio(output);
  var engine = 'Offline Edge Cutout';

  if (transparency < 0.04) {
    output = _removeBackgroundDominantBorder(decoded);
    transparency = _transparentRatio(output);
    engine = 'Offline Border Key Cutout';
  }

  if (transparency < 0.02) {
    output = _forceBackgroundKnockout(output);
    engine = 'Offline Force Cutout';
  }

  final pngBytes = Uint8List.fromList(img.encodePng(output));

  return BackgroundRemovalResult(pngBytes: pngBytes, engineLabel: engine);
}

double _transparentRatio(img.Image image) {
  var transparent = 0;
  final total = image.width * image.height;
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      if (image.getPixel(x, y).a.toInt() < 245) {
        transparent++;
      }
    }
  }
  return transparent / math.max(total, 1);
}

double _alphaDifference(img.Image source, img.Image output) {
  if (source.width != output.width || source.height != output.height) {
    return 1;
  }

  var total = 0.0;
  final count = source.width * source.height;
  for (var y = 0; y < source.height; y++) {
    for (var x = 0; x < source.width; x++) {
      final a = source.getPixel(x, y).a.toInt();
      final b = output.getPixel(x, y).a.toInt();
      total += (a - b).abs() / 255.0;
    }
  }

  return total / math.max(count, 1);
}

Uint8List _polishCutoutInIsolate(Uint8List pngBytes) {
  final image = img.decodeImage(pngBytes);
  if (image == null) {
    return pngBytes;
  }

  final width = image.width;
  final height = image.height;
  final alphaMap = List<int>.filled(width * height, 0);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      alphaMap[(y * width) + x] = image.getPixel(x, y).a.toInt();
    }
  }

  final softAlpha = _smoothAlphaMapSoft(alphaMap, width, height, passes: 2);

  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final index = (y * width) + x;
      final pixel = image.getPixel(x, y);
      final originalA = pixel.a.toInt();
      var blendedA = ((originalA * 0.45) + (softAlpha[index] * 0.55))
          .round()
          .clamp(0, 255);

      // Slight edge feather for anti-jaggies, while keeping solid interiors solid.
      final normalized = blendedA / 255.0;
      blendedA = (math.pow(normalized, 1.08) * 255).round().clamp(0, 255);

      if (blendedA <= 6) {
        blendedA = 0;
      } else if (blendedA >= 252) {
        blendedA = 255;
      }

      image.setPixelRgba(
        x,
        y,
        pixel.r.toInt(),
        pixel.g.toInt(),
        pixel.b.toInt(),
        blendedA,
      );
    }
  }

  _decontaminateEdgeColors(image);

  return Uint8List.fromList(img.encodePng(image));
}

void _decontaminateEdgeColors(img.Image image) {
  final width = image.width;
  final height = image.height;
  final source = img.Image.from(image);

  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final pixel = source.getPixel(x, y);
      final alpha = pixel.a.toInt();
      if (alpha <= 0 || alpha >= 245) {
        continue;
      }

      var rSum = 0.0;
      var gSum = 0.0;
      var bSum = 0.0;
      var count = 0.0;

      for (var oy = -1; oy <= 1; oy++) {
        final ny = y + oy;
        if (ny < 0 || ny >= height) {
          continue;
        }
        for (var ox = -1; ox <= 1; ox++) {
          final nx = x + ox;
          if (nx < 0 || nx >= width) {
            continue;
          }
          final near = source.getPixel(nx, ny);
          if (near.a.toInt() < 245) {
            continue;
          }
          rSum += near.r;
          gSum += near.g;
          bSum += near.b;
          count += 1;
        }
      }

      if (count == 0) {
        continue;
      }

      final edgeR = (rSum / count).round();
      final edgeG = (gSum / count).round();
      final edgeB = (bSum / count).round();
      final mix = ((255 - alpha) / 255.0 * 0.82).clamp(0.0, 1.0);

      final outR = (pixel.r + ((edgeR - pixel.r) * mix)).round().clamp(0, 255);
      final outG = (pixel.g + ((edgeG - pixel.g) * mix)).round().clamp(0, 255);
      final outB = (pixel.b + ((edgeB - pixel.b) * mix)).round().clamp(0, 255);

      image.setPixelRgba(x, y, outR, outG, outB, alpha);
    }
  }
}

img.Image _removeBackgroundEdgeFloodFill(img.Image image) {
  final sample = _downscaleForAnalysis(image);
  final width = sample.width;
  final height = sample.height;
  final total = width * height;
  final visited = Uint8List(total);
  final backgroundMask = Uint8List(total);
  final queue = List<int>.filled(total, 0, growable: false);
  var head = 0;
  var tail = 0;

  final corners = _cornerAverages(sample);
  final threshold = _adaptiveThreshold(corners);
  final seedThreshold = (threshold * 0.92).clamp(20.0, 82.0);
  final growThreshold = (threshold * 1.12).clamp(24.0, 96.0);
  final subjectBounds = _estimateSubjectBounds(sample, corners, threshold);
  final centerProtectThreshold = (threshold * 0.86).clamp(16.0, 72.0);

  void seedAt(int x, int y) {
    final index = (y * width) + x;
    if (visited[index] == 1) {
      return;
    }
    visited[index] = 1;
    final distance = _distanceToBackground(sample.getPixel(x, y), corners);
    if (distance <= seedThreshold) {
      backgroundMask[index] = 1;
      queue[tail++] = index;
    }
  }

  for (var x = 0; x < width; x++) {
    seedAt(x, 0);
    seedAt(x, height - 1);
  }
  for (var y = 1; y < height - 1; y++) {
    seedAt(0, y);
    seedAt(width - 1, y);
  }

  while (head < tail) {
    final index = queue[head++];
    final x = index % width;
    final y = index ~/ width;

    void tryVisit(int nx, int ny) {
      if (nx < 0 || ny < 0 || nx >= width || ny >= height) {
        return;
      }
      final nIndex = (ny * width) + nx;
      if (visited[nIndex] == 1) {
        return;
      }
      visited[nIndex] = 1;
      final pixel = sample.getPixel(nx, ny);
      final distance = _distanceToBackground(pixel, corners);
      final normalizedX =
          ((nx / width) - subjectBounds.centerX) /
          math.max(subjectBounds.radiusX, 0.001);
      final normalizedY =
          ((ny / height) - subjectBounds.centerY) /
          math.max(subjectBounds.radiusY, 0.001);
      final ellipseDistance =
          (normalizedX * normalizedX) + (normalizedY * normalizedY);
      final protectedCenter =
          ellipseDistance < 1.0 && distance > centerProtectThreshold;
      if (protectedCenter) {
        return;
      }
      if (distance <= growThreshold) {
        backgroundMask[nIndex] = 1;
        queue[tail++] = nIndex;
      }
    }

    tryVisit(x - 1, y);
    tryVisit(x + 1, y);
    tryVisit(x, y - 1);
    tryVisit(x, y + 1);
  }

  final foregroundMask = Uint8List(total);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final index = (y * width) + x;
      if (backgroundMask[index] == 1) {
        foregroundMask[index] = 0;
        continue;
      }

      final pixel = sample.getPixel(x, y);
      final distance = _distanceToBackground(pixel, corners);
      final normalizedX =
          ((x / width) - subjectBounds.centerX) /
          math.max(subjectBounds.radiusX, 0.001);
      final normalizedY =
          ((y / height) - subjectBounds.centerY) /
          math.max(subjectBounds.radiusY, 0.001);
      final ellipseDistance =
          (normalizedX * normalizedX) + (normalizedY * normalizedY);

      final colorStrength =
          ((distance - (threshold * 0.68)) / (threshold * 1.18)).clamp(
            0.0,
            1.0,
          );
      final centerStrength = (1.14 - ellipseDistance).clamp(0.0, 1.0);
      final alpha = (math.max(colorStrength, centerStrength * 0.92) * 255)
          .round()
          .clamp(0, 255);
      foregroundMask[index] = alpha;
    }
  }
  final smoothedMask = _smoothAlphaMap(
    foregroundMask.map((value) => value.toInt()).toList(growable: false),
    width,
    height,
    passes: 2,
  );

  final output = img.Image.from(image);
  final scaleX = width / image.width;
  final scaleY = height / image.height;

  for (var y = 0; y < image.height; y++) {
    final sy = (y * scaleY).round().clamp(0, height - 1);
    for (var x = 0; x < image.width; x++) {
      final sx = (x * scaleX).round().clamp(0, width - 1);
      final smallAlpha = smoothedMask[(sy * width) + sx].clamp(0, 255);
      final pixel = output.getPixel(x, y);
      final alpha = math.min(pixel.a.toInt(), smallAlpha);
      output.setPixelRgba(
        x,
        y,
        pixel.r.toInt(),
        pixel.g.toInt(),
        pixel.b.toInt(),
        alpha,
      );
    }
  }

  return output;
}

img.Image _removeBackgroundDominantBorder(img.Image image) {
  final sample = _downscaleForAnalysis(image);
  final corners = _cornerAverages(sample);
  final mean = _RgbSample(
    corners.fold<double>(0, (s, c) => s + c.r) / corners.length,
    corners.fold<double>(0, (s, c) => s + c.g) / corners.length,
    corners.fold<double>(0, (s, c) => s + c.b) / corners.length,
  );

  final threshold = _adaptiveThreshold(corners);
  final output = img.Image.from(image);
  final bounds = _estimateSubjectBounds(sample, corners, threshold);
  final safeRadiusX = math.max(bounds.radiusX, 0.001);
  final safeRadiusY = math.max(bounds.radiusY, 0.001);

  for (var y = 0; y < output.height; y++) {
    for (var x = 0; x < output.width; x++) {
      final pixel = output.getPixel(x, y);
      final dr = pixel.r - mean.r;
      final dg = pixel.g - mean.g;
      final db = pixel.b - mean.b;
      final colorDistance = math.sqrt((dr * dr) + (dg * dg) + (db * db));

      final nx = ((x / output.width) - bounds.centerX) / safeRadiusX;
      final ny = ((y / output.height) - bounds.centerY) / safeRadiusY;
      final ellipseDistance = (nx * nx) + (ny * ny);
      final centerBias = (1.18 - ellipseDistance).clamp(0.0, 1.0);

      final bgStrength =
          ((colorDistance - (threshold * 0.55)) / (threshold * 1.25)).clamp(
            0.0,
            1.0,
          );
      final alpha = (math.max(bgStrength, centerBias * 0.88) * pixel.a)
          .round()
          .clamp(0, 255);
      output.setPixelRgba(
        x,
        y,
        pixel.r.toInt(),
        pixel.g.toInt(),
        pixel.b.toInt(),
        alpha,
      );
    }
  }

  return output;
}

img.Image _forceBackgroundKnockout(img.Image image) {
  final sample = _downscaleForAnalysis(image);
  final corners = _cornerAverages(sample);
  final threshold = _adaptiveThreshold(corners);
  final output = img.Image.from(image);

  for (var y = 0; y < output.height; y++) {
    for (var x = 0; x < output.width; x++) {
      final pixel = output.getPixel(x, y);
      final distance = _distanceToBackground(pixel, corners);
      final isBgLike = distance < (threshold * 0.78);
      if (isBgLike) {
        final reducedAlpha = (pixel.a * 0.08).round().clamp(0, 255);
        output.setPixelRgba(
          x,
          y,
          pixel.r.toInt(),
          pixel.g.toInt(),
          pixel.b.toInt(),
          reducedAlpha,
        );
      }
    }
  }

  return output;
}

_SubjectBounds _estimateSubjectBounds(
  img.Image image,
  List<_RgbSample> corners,
  double threshold,
) {
  var minX = image.width.toDouble();
  var minY = image.height.toDouble();
  var maxX = -1.0;
  var maxY = -1.0;
  var foregroundPixels = 0;

  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final pixel = image.getPixel(x, y);
      if (pixel.a < 16) {
        continue;
      }
      final distance = _distanceToBackground(pixel, corners);
      if (distance < (threshold * 0.9)) {
        continue;
      }
      foregroundPixels += 1;
      minX = math.min(minX, x.toDouble());
      minY = math.min(minY, y.toDouble());
      maxX = math.max(maxX, x.toDouble());
      maxY = math.max(maxY, y.toDouble());
    }
  }

  if (foregroundPixels <= ((image.width * image.height) * 0.008) ||
      maxX <= minX ||
      maxY <= minY) {
    return const _SubjectBounds(
      centerX: 0.5,
      centerY: 0.54,
      radiusX: 0.34,
      radiusY: 0.44,
    );
  }

  final padX = math.max(6.0, (maxX - minX) * 0.12);
  final padY = math.max(8.0, (maxY - minY) * 0.12);
  final clampedMinX = math.max(0.0, minX - padX);
  final clampedMinY = math.max(0.0, minY - padY);
  final clampedMaxX = math.min(image.width - 1.0, maxX + padX);
  final clampedMaxY = math.min(image.height - 1.0, maxY + padY);

  return _SubjectBounds(
    centerX: ((clampedMinX + clampedMaxX) / 2) / image.width,
    centerY: ((clampedMinY + clampedMaxY) / 2) / image.height,
    radiusX: (((clampedMaxX - clampedMinX) / 2) / image.width).clamp(
      0.14,
      0.49,
    ),
    radiusY: (((clampedMaxY - clampedMinY) / 2) / image.height).clamp(
      0.18,
      0.52,
    ),
  );
}

Uint8List _applyBrushEditsInIsolate(Map<String, Object> payload) {
  final currentBytes = payload['currentBytes']! as Uint8List;
  final originalBytes = payload['originalBytes']! as Uint8List;
  final mode = BackgroundRefineMode.values[payload['mode']! as int];
  final brushRadius = payload['brushRadius']! as double;
  final pointsPayload = payload['points']! as List<Object>;

  final current = img.decodeImage(currentBytes);
  final original = img.decodeImage(originalBytes);
  if (current == null || original == null) {
    throw Exception('Refine image decode kaaledu');
  }
  if (current.width != original.width || current.height != original.height) {
    throw Exception('Refine source size mismatch');
  }

  final points = pointsPayload
      .map((entry) {
        final map = entry as Map<Object?, Object?>;
        return Offset(
          (map['x']! as num).toDouble(),
          (map['y']! as num).toDouble(),
        );
      })
      .toList(growable: false);
  if (points.isEmpty) {
    return currentBytes;
  }

  for (var i = 0; i < points.length; i++) {
    final point = points[i];
    _paintCircle(
      current: current,
      original: original,
      mode: mode,
      centerX: point.dx,
      centerY: point.dy,
      radius: brushRadius,
    );
    if (i > 0) {
      _paintBridge(
        current: current,
        original: original,
        mode: mode,
        start: points[i - 1],
        end: point,
        radius: brushRadius,
      );
    }
  }

  return Uint8List.fromList(img.encodePng(current));
}

Uint8List _applyEdgeFeatherInIsolate(Map<String, Object> payload) {
  final currentBytes = payload['currentBytes']! as Uint8List;
  final strength = payload['strength']! as double;
  final image = img.decodeImage(currentBytes);
  if (image == null) {
    throw Exception('Feather image decode kaaledu');
  }

  final alphaMap = List<int>.filled(image.width * image.height, 0);
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      alphaMap[(y * image.width) + x] = image.getPixel(x, y).a.toInt();
    }
  }

  final passes = strength.round().clamp(1, 6);
  final smoothed = _smoothAlphaMap(
    alphaMap,
    image.width,
    image.height,
    passes: passes,
  );

  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final pixel = image.getPixel(x, y);
      final alpha = smoothed[(y * image.width) + x];
      image.setPixelRgba(
        x,
        y,
        pixel.r.toInt(),
        pixel.g.toInt(),
        pixel.b.toInt(),
        alpha,
      );
    }
  }

  return Uint8List.fromList(img.encodePng(image));
}

img.Image _downscaleForAnalysis(img.Image image) {
  const target = 180;
  final longest = math.max(image.width, image.height).toDouble();
  if (longest <= target) {
    return image;
  }
  final scale = target / longest;
  final width = math.max(32, (image.width * scale).round());
  final height = math.max(32, (image.height * scale).round());
  return img.copyResize(image, width: width, height: height);
}

List<_RgbSample> _cornerAverages(img.Image image) {
  final patchWidth = math.max(4, (image.width * 0.12).round());
  final patchHeight = math.max(4, (image.height * 0.12).round());
  return <_RgbSample>[
    _averagePatch(image, 0, 0, patchWidth, patchHeight),
    _averagePatch(image, image.width - patchWidth, 0, patchWidth, patchHeight),
    _averagePatch(
      image,
      0,
      image.height - patchHeight,
      patchWidth,
      patchHeight,
    ),
    _averagePatch(
      image,
      image.width - patchWidth,
      image.height - patchHeight,
      patchWidth,
      patchHeight,
    ),
  ];
}

_RgbSample _averagePatch(
  img.Image image,
  int startX,
  int startY,
  int width,
  int height,
) {
  var r = 0.0;
  var g = 0.0;
  var b = 0.0;
  var count = 0.0;
  final xEnd = math.min(image.width, startX + width);
  final yEnd = math.min(image.height, startY + height);

  for (var y = math.max(0, startY); y < yEnd; y++) {
    for (var x = math.max(0, startX); x < xEnd; x++) {
      final pixel = image.getPixel(x, y);
      r += pixel.r;
      g += pixel.g;
      b += pixel.b;
      count += 1;
    }
  }

  if (count == 0) {
    return const _RgbSample(255, 255, 255);
  }

  return _RgbSample(r / count, g / count, b / count);
}

double _adaptiveThreshold(List<_RgbSample> corners) {
  final meanR =
      corners.fold<double>(0, (sum, item) => sum + item.r) / corners.length;
  final meanG =
      corners.fold<double>(0, (sum, item) => sum + item.g) / corners.length;
  final meanB =
      corners.fold<double>(0, (sum, item) => sum + item.b) / corners.length;

  final variance =
      corners.fold<double>(0, (sum, item) {
        return sum +
            math.pow(item.r - meanR, 2) +
            math.pow(item.g - meanG, 2) +
            math.pow(item.b - meanB, 2);
      }) /
      (corners.length * 3);

  return (34 + math.sqrt(variance) * 1.35).clamp(26, 72).toDouble();
}

List<int> _smoothAlphaMap(
  List<int> alphaMap,
  int width,
  int height, {
  int passes = 2,
}) {
  var current = List<int>.from(alphaMap);
  var next = List<int>.filled(alphaMap.length, 0);

  for (var pass = 0; pass < passes; pass++) {
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        var alphaSum = 0;
        var weightSum = 0;

        for (var offsetY = -1; offsetY <= 1; offsetY++) {
          final sampleY = (y + offsetY).clamp(0, height - 1);
          for (var offsetX = -1; offsetX <= 1; offsetX++) {
            final sampleX = (x + offsetX).clamp(0, width - 1);
            final weight = offsetX == 0 && offsetY == 0 ? 4 : 1;
            alphaSum += current[(sampleY * width) + sampleX] * weight;
            weightSum += weight;
          }
        }

        var alpha = (alphaSum / weightSum).round().clamp(0, 255);
        if (alpha < 18) {
          alpha = 0;
        } else if (alpha > 245) {
          alpha = 255;
        }
        next[(y * width) + x] = alpha;
      }
    }
    final temp = current;
    current = next;
    next = temp;
  }

  return current;
}

List<int> _smoothAlphaMapSoft(
  List<int> alphaMap,
  int width,
  int height, {
  int passes = 2,
}) {
  var current = List<int>.from(alphaMap);
  var next = List<int>.filled(alphaMap.length, 0);

  for (var pass = 0; pass < passes; pass++) {
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        var alphaSum = 0;
        var weightSum = 0;

        for (var offsetY = -1; offsetY <= 1; offsetY++) {
          final sampleY = (y + offsetY).clamp(0, height - 1);
          for (var offsetX = -1; offsetX <= 1; offsetX++) {
            final sampleX = (x + offsetX).clamp(0, width - 1);
            final axisWeight = (offsetX == 0 || offsetY == 0) ? 2 : 1;
            final centerBoost = (offsetX == 0 && offsetY == 0) ? 2 : 0;
            final weight = axisWeight + centerBoost;
            alphaSum += current[(sampleY * width) + sampleX] * weight;
            weightSum += weight;
          }
        }

        next[(y * width) + x] = (alphaSum / weightSum).round().clamp(0, 255);
      }
    }
    final temp = current;
    current = next;
    next = temp;
  }

  return current;
}

void _paintBridge({
  required img.Image current,
  required img.Image original,
  required BackgroundRefineMode mode,
  required Offset start,
  required Offset end,
  required double radius,
}) {
  final deltaX = end.dx - start.dx;
  final deltaY = end.dy - start.dy;
  final distance = math.sqrt((deltaX * deltaX) + (deltaY * deltaY));
  final steps = math.max(1, (distance / math.max(radius * 0.35, 1)).round());

  for (var i = 1; i < steps; i++) {
    final t = i / steps;
    _paintCircle(
      current: current,
      original: original,
      mode: mode,
      centerX: start.dx + (deltaX * t),
      centerY: start.dy + (deltaY * t),
      radius: radius,
    );
  }
}

void _paintCircle({
  required img.Image current,
  required img.Image original,
  required BackgroundRefineMode mode,
  required double centerX,
  required double centerY,
  required double radius,
}) {
  final minX = math.max(0, (centerX - radius - 1).floor());
  final maxX = math.min(current.width - 1, (centerX + radius + 1).ceil());
  final minY = math.max(0, (centerY - radius - 1).floor());
  final maxY = math.min(current.height - 1, (centerY + radius + 1).ceil());
  final radiusSquared = radius * radius;

  for (var y = minY; y <= maxY; y++) {
    for (var x = minX; x <= maxX; x++) {
      final dx = x - centerX;
      final dy = y - centerY;
      final distanceSquared = (dx * dx) + (dy * dy);
      if (distanceSquared > radiusSquared) {
        continue;
      }

      final softness =
          1 - (math.sqrt(distanceSquared) / math.max(radius, 0.001));
      final blend = (softness * softness).clamp(0.0, 1.0);
      final currentPixel = current.getPixel(x, y);

      if (mode == BackgroundRefineMode.erase) {
        final newAlpha = (currentPixel.a * (1 - blend)).round().clamp(0, 255);
        current.setPixelRgba(
          x,
          y,
          currentPixel.r.toInt(),
          currentPixel.g.toInt(),
          currentPixel.b.toInt(),
          newAlpha,
        );
      } else {
        final sourcePixel = original.getPixel(x, y);
        current.setPixelRgba(
          x,
          y,
          _blendChannel(currentPixel.r, sourcePixel.r, blend),
          _blendChannel(currentPixel.g, sourcePixel.g, blend),
          _blendChannel(currentPixel.b, sourcePixel.b, blend),
          _blendChannel(currentPixel.a, sourcePixel.a, blend),
        );
      }
    }
  }
}

int _blendChannel(num current, num target, double blend) {
  return (current + ((target - current) * blend)).round().clamp(0, 255);
}

double _distanceToBackground(img.Pixel pixel, List<_RgbSample> corners) {
  var minDistance = double.infinity;
  for (final corner in corners) {
    final dr = pixel.r - corner.r;
    final dg = pixel.g - corner.g;
    final db = pixel.b - corner.b;
    final distance = math.sqrt((dr * dr) + (dg * dg) + (db * db));
    if (distance < minDistance) {
      minDistance = distance;
    }
  }
  return minDistance;
}

class _RgbSample {
  const _RgbSample(this.r, this.g, this.b);

  final double r;
  final double g;
  final double b;

  double get luma => _lumaFromRgb(r, g, b);
}

class _SubjectBounds {
  const _SubjectBounds({
    required this.centerX,
    required this.centerY,
    required this.radiusX,
    required this.radiusY,
  });

  final double centerX;
  final double centerY;
  final double radiusX;
  final double radiusY;
}

double _lumaFromRgb(double r, double g, double b) {
  return (0.2126 * r) + (0.7152 * g) + (0.0722 * b);
}
