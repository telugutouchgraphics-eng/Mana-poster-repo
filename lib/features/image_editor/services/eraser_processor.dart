import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import 'eraser_controller.dart';

Uint8List applyEraserChunksToPng(Map<String, dynamic> payload) {
  final currentBytes = payload['currentBytes'] as Uint8List?;
  final restoreBytes = payload['restoreBytes'] as Uint8List?;
  final chunksData = (payload['chunks'] as List<dynamic>? ?? const <dynamic>[]);
  final radiusScale = (payload['radiusScale'] as num?)?.toDouble() ?? 1.0;

  final currentDecoded = currentBytes == null
      ? null
      : img.decodeImage(currentBytes);
  final restoreDecoded = restoreBytes == null
      ? null
      : img.decodeImage(restoreBytes);
  if (currentDecoded == null) {
    return currentBytes ?? Uint8List(0);
  }

  final workingImage = img.Image.from(currentDecoded).convert(numChannels: 4);
  img.Image restoreImage = restoreDecoded != null
      ? img.Image.from(restoreDecoded).convert(numChannels: 4)
      : img.Image.from(currentDecoded).convert(numChannels: 4);
  if (restoreImage.width != workingImage.width ||
      restoreImage.height != workingImage.height) {
    restoreImage = img
        .copyResize(
          restoreImage,
          width: workingImage.width,
          height: workingImage.height,
          interpolation: img.Interpolation.linear,
        )
        .convert(numChannels: 4);
  }

  final chunks = chunksData
      .whereType<Map>()
      .map(
        (item) => EraserStrokeChunk.fromMap(
          item.map(
            (Object? key, Object? value) => MapEntry(key.toString(), value),
          ),
        ),
      )
      .toList(growable: false);

  for (final chunk in chunks) {
    _applyChunk(
      workingImage: workingImage,
      restoreImage: restoreImage,
      chunk: chunk,
      radiusScale: radiusScale,
    );
  }
  return Uint8List.fromList(img.encodePng(workingImage));
}

void _applyChunk({
  required img.Image workingImage,
  required img.Image restoreImage,
  required EraserStrokeChunk chunk,
  required double radiusScale,
}) {
  if (chunk.points.isEmpty) {
    return;
  }
  for (final point in chunk.points) {
    final centerX =
        point.normalized.dx.clamp(0.0, 1.0) * (workingImage.width - 1);
    final centerY =
        point.normalized.dy.clamp(0.0, 1.0) * (workingImage.height - 1);
    _applyStamp(
      workingImage: workingImage,
      restoreImage: restoreImage,
      centerX: centerX,
      centerY: centerY,
      radius: (point.radiusInImagePixels * radiusScale).clamp(0.75, 8192.0),
      hardness: point.hardness,
      strength: point.strength * point.pressure,
      mode: chunk.mode,
    );
  }
}

void _applyStamp({
  required img.Image workingImage,
  required img.Image restoreImage,
  required double centerX,
  required double centerY,
  required double radius,
  required double hardness,
  required double strength,
  required EraserBlendMode mode,
}) {
  final left = math.max(0, (centerX - radius).floor());
  final right = math.min(workingImage.width - 1, (centerX + radius).ceil());
  final top = math.max(0, (centerY - radius).floor());
  final bottom = math.min(workingImage.height - 1, (centerY + radius).ceil());
  final safeHardness = hardness.clamp(0.0, 1.0);
  final innerRadius = radius * safeHardness;
  final featherWidth = math.max(radius - innerRadius, 0.0001);

  for (var y = top; y <= bottom; y++) {
    for (var x = left; x <= right; x++) {
      final dx = (x + 0.5) - centerX;
      final dy = (y + 0.5) - centerY;
      final distance = math.sqrt((dx * dx) + (dy * dy));
      if (distance > radius) {
        continue;
      }
      final amount = _maskAmount(
        distance: distance,
        radius: radius,
        innerRadius: innerRadius,
        featherWidth: featherWidth,
        strength: strength,
      );
      if (amount <= 0.0001) {
        continue;
      }

      final currentPixel = workingImage.getPixel(x, y);
      if (mode == EraserBlendMode.erase) {
        final nextAlpha = (currentPixel.a.toDouble() * (1 - amount))
            .round()
            .clamp(0, 255);
        workingImage.setPixelRgba(
          x,
          y,
          currentPixel.r.toInt(),
          currentPixel.g.toInt(),
          currentPixel.b.toInt(),
          nextAlpha,
        );
      } else {
        final sourcePixel = restoreImage.getPixel(x, y);
        workingImage.setPixelRgba(
          x,
          y,
          _blendChannel(currentPixel.r.toInt(), sourcePixel.r.toInt(), amount),
          _blendChannel(currentPixel.g.toInt(), sourcePixel.g.toInt(), amount),
          _blendChannel(currentPixel.b.toInt(), sourcePixel.b.toInt(), amount),
          _blendChannel(currentPixel.a.toInt(), sourcePixel.a.toInt(), amount),
        );
      }
    }
  }
}

double _maskAmount({
  required double distance,
  required double radius,
  required double innerRadius,
  required double featherWidth,
  required double strength,
}) {
  if (distance <= innerRadius) {
    return strength.clamp(0.0, 1.0);
  }
  final normalized = ((radius - distance) / featherWidth).clamp(0.0, 1.0);
  final eased = normalized * normalized * (3 - (2 * normalized));
  return (eased * strength).clamp(0.0, 1.0);
}

int _blendChannel(int from, int to, double weight) {
  return (from + ((to - from) * weight)).round().clamp(0, 255);
}
