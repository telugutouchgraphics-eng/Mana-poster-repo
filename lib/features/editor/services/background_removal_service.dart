import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

import 'package:mana_poster/features/editor/models/editor_stage.dart';
import 'package:mana_poster/features/editor/services/background_removal_source.dart';
import 'package:mana_poster/features/editor/utils/editor_image_source.dart';

enum BackgroundRemovalPipeline { offlineFast, onlineHd }

class BackgroundRemovalRequest {
  const BackgroundRemovalRequest({
    required this.imageUrl,
    required this.imageSize,
    this.pipeline = BackgroundRemovalPipeline.offlineFast,
  });

  final String imageUrl;
  final Size imageSize;
  final BackgroundRemovalPipeline pipeline;
}

class BackgroundRemovalResult {
  const BackgroundRemovalResult({
    required this.maskTemplate,
    required this.pipeline,
    required this.engineLabel,
  });

  final AutoMaskTemplate maskTemplate;
  final BackgroundRemovalPipeline pipeline;
  final String engineLabel;
}

abstract class BackgroundRemovalService {
  const BackgroundRemovalService();

  Future<BackgroundRemovalResult> autoRemove(BackgroundRemovalRequest request);
}

class OfflineFastBackgroundRemovalService extends BackgroundRemovalService {
  const OfflineFastBackgroundRemovalService();

  static const String modelSlot = 'onnx://BiRefNet-general-lite';

  @override
  Future<BackgroundRemovalResult> autoRemove(
    BackgroundRemovalRequest request,
  ) async {
    try {
      final bytes = await _loadImageBytes(request.imageUrl);
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        return _fallbackResult(request);
      }

      final mask = _estimateSubjectMask(decoded);
      return BackgroundRemovalResult(
        pipeline: BackgroundRemovalPipeline.offlineFast,
        engineLabel: 'Offline Fast Heuristic',
        maskTemplate: mask.copyWith(
          source: 'offline-fast-heuristic',
          modelSlot: modelSlot,
        ),
      );
    } catch (_) {
      return _fallbackResult(request);
    }
  }

  Future<Uint8List> _loadImageBytes(String source) async {
    if (isRemoteImageSource(source)) {
      final bundle = NetworkAssetBundle(Uri.parse(source));
      final data = await bundle.load(source);
      return data.buffer.asUint8List();
    }
    return loadBackgroundRemovalFileBytes(source);
  }

  AutoMaskTemplate _estimateSubjectMask(img.Image image) {
    final sampleImage = _downscaleForAnalysis(image);
    final width = sampleImage.width;
    final height = sampleImage.height;
    if (width <= 2 || height <= 2) {
      return const AutoMaskTemplate(
        kind: AutoMaskTemplateKind.subjectEllipse,
        center: Offset(0.5, 0.5),
        radiusX: 0.34,
        radiusY: 0.42,
        feather: 0.14,
      );
    }

    final corners = _cornerAverages(sampleImage);
    final threshold = _adaptiveThreshold(corners);

    var minX = width;
    var minY = height;
    var maxX = -1;
    var maxY = -1;
    var foregroundPixels = 0;

    for (var y = 0; y < height; y += 1) {
      for (var x = 0; x < width; x += 1) {
        final pixel = sampleImage.getPixel(x, y);
        if (pixel.a < 16) {
          continue;
        }

        final distance = _distanceToBackground(pixel, corners);
        if (distance < threshold) {
          continue;
        }

        foregroundPixels += 1;
        if (x < minX) minX = x;
        if (y < minY) minY = y;
        if (x > maxX) maxX = x;
        if (y > maxY) maxY = y;
      }
    }

    if (foregroundPixels <= ((width * height) * 0.01) ||
        maxX <= minX ||
        maxY <= minY) {
      return const AutoMaskTemplate(
        kind: AutoMaskTemplateKind.subjectEllipse,
        center: Offset(0.5, 0.52),
        radiusX: 0.34,
        radiusY: 0.42,
        feather: 0.16,
      );
    }

    final padX = math.max(6.0, (maxX - minX) * 0.12);
    final padY = math.max(8.0, (maxY - minY) * 0.12);
    final clampedMinX = math.max(0.0, minX - padX);
    final clampedMinY = math.max(0.0, minY - padY);
    final clampedMaxX = math.min(width - 1.0, maxX + padX);
    final clampedMaxY = math.min(height - 1.0, maxY + padY);

    final center = Offset(
      ((clampedMinX + clampedMaxX) / 2) / width,
      ((clampedMinY + clampedMaxY) / 2) / height,
    );
    final radiusX = (((clampedMaxX - clampedMinX) / 2) / width).clamp(
      0.12,
      0.48,
    );
    final radiusY = (((clampedMaxY - clampedMinY) / 2) / height).clamp(
      0.16,
      0.49,
    );

    final coverage = foregroundPixels / (width * height);
    final feather = (0.08 + (coverage * 0.22)).clamp(0.10, 0.22);

    return AutoMaskTemplate(
      kind: AutoMaskTemplateKind.subjectEllipse,
      center: center,
      radiusX: radiusX,
      radiusY: radiusY,
      feather: feather,
    );
  }

  img.Image _downscaleForAnalysis(img.Image image) {
    const target = 160;
    final longest = math.max(image.width, image.height).toDouble();
    if (longest <= target) {
      return image;
    }
    final scale = target / longest;
    final width = math.max(24, (image.width * scale).round());
    final height = math.max(24, (image.height * scale).round());
    return img.copyResize(image, width: width, height: height);
  }

  List<_RgbSample> _cornerAverages(img.Image image) {
    final patchWidth = math.max(4, (image.width * 0.12).round());
    final patchHeight = math.max(4, (image.height * 0.12).round());
    return <_RgbSample>[
      _averagePatch(image, 0, 0, patchWidth, patchHeight),
      _averagePatch(
        image,
        image.width - patchWidth,
        0,
        patchWidth,
        patchHeight,
      ),
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
    for (var y = math.max(0, startY); y < yEnd; y += 1) {
      for (var x = math.max(0, startX); x < xEnd; x += 1) {
        final pixel = image.getPixel(x, y);
        r += pixel.r.toDouble();
        g += pixel.g.toDouble();
        b += pixel.b.toDouble();
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

  BackgroundRemovalResult _fallbackResult(BackgroundRemovalRequest request) {
    final aspectRatio =
        request.imageSize.width <= 0 || request.imageSize.height <= 0
        ? 1.0
        : request.imageSize.width / request.imageSize.height;
    final portraitBias = aspectRatio < 1 ? 0.08 : 0.0;

    return BackgroundRemovalResult(
      pipeline: BackgroundRemovalPipeline.offlineFast,
      engineLabel: 'Offline Fast Fallback',
      maskTemplate: AutoMaskTemplate(
        kind: AutoMaskTemplateKind.subjectEllipse,
        center: Offset(0.5, 0.52 - portraitBias),
        radiusX: aspectRatio > 1.2 ? 0.28 : 0.34,
        radiusY: aspectRatio < 0.9 ? 0.48 : 0.42,
        feather: 0.16,
        source: 'offline-fast-fallback',
        modelSlot: modelSlot,
      ),
    );
  }
}

class OnlineHdBackgroundRemovalService extends BackgroundRemovalService {
  const OnlineHdBackgroundRemovalService();

  static const String modelSlot = 'server://rembg+BiRefNet-general';

  @override
  Future<BackgroundRemovalResult> autoRemove(
    BackgroundRemovalRequest request,
  ) async {
    return const BackgroundRemovalResult(
      pipeline: BackgroundRemovalPipeline.onlineHd,
      engineLabel: 'Online HD Slot',
      maskTemplate: AutoMaskTemplate(
        kind: AutoMaskTemplateKind.subjectEllipse,
        center: Offset(0.5, 0.5),
        radiusX: 0.34,
        radiusY: 0.44,
        feather: 0.18,
        source: 'online-hd-slot',
        modelSlot: modelSlot,
      ),
    );
  }
}

class HybridBackgroundRemovalService extends BackgroundRemovalService {
  const HybridBackgroundRemovalService({
    this.offline = const OfflineFastBackgroundRemovalService(),
    this.online = const OnlineHdBackgroundRemovalService(),
  });

  final BackgroundRemovalService offline;
  final BackgroundRemovalService online;

  @override
  Future<BackgroundRemovalResult> autoRemove(BackgroundRemovalRequest request) {
    switch (request.pipeline) {
      case BackgroundRemovalPipeline.offlineFast:
        return offline.autoRemove(request);
      case BackgroundRemovalPipeline.onlineHd:
        return online.autoRemove(request);
    }
  }
}

class _RgbSample {
  const _RgbSample(this.r, this.g, this.b);

  final double r;
  final double g;
  final double b;
}
