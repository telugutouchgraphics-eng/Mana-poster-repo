part of 'image_editor_screen.dart';

class _AdjustedPhotoPresentationCache {
  const _AdjustedPhotoPresentationCache();

  static final LinkedHashMap<String, _AdjustedPhotoPresentation> _cache =
      LinkedHashMap<String, _AdjustedPhotoPresentation>();
  static const int _maxEntries = 96;

  static _AdjustedPhotoPresentation resolve({
    required Uint8List bytes,
    required String key,
    required double opacity,
  }) {
    final existing = _cache.remove(key);
    if (existing != null) {
      _cache[key] = existing;
      return existing;
    }
    final image = Image.memory(
      bytes,
      gaplessPlayback: true,
      filterQuality: FilterQuality.low,
      fit: BoxFit.contain,
      frameBuilder:
          (BuildContext context, Widget child, int? frame, bool sync) => child,
    );
    final presentation = _AdjustedPhotoPresentation(
      key: key,
      image: image,
      opacity: opacity,
    );
    _cache[key] = presentation;
    if (_cache.length > _maxEntries) {
      _cache.remove(_cache.keys.first);
    }
    return presentation;
  }
}

bool _isMatrixFinite(Matrix4 matrix) {
  for (final value in matrix.storage) {
    if (!value.isFinite) {
      return false;
    }
  }
  return true;
}

String _photoBytesSignature(Uint8List bytes) {
  final length = bytes.length;
  if (length == 0) {
    return '0_0';
  }
  final sample = bytes.length > 64 ? 64 : bytes.length;
  var hash = 17;
  for (var i = 0; i < sample; i++) {
    hash = 37 * hash + bytes[i];
  }
  return '${bytes.length}_$hash';
}

Uint8List _magicWandRemoveColorBytes(Map<String, Object?> input) {
  final bytes = input['bytes'] as Uint8List;
  final seedX = input['x'] as int;
  final seedY = input['y'] as int;
  final tolerance = input['tolerance'] as int? ?? 38;
  final featherRadius = input['featherRadius'] as int? ?? 3;
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    return bytes;
  }

  final output = img.Image.from(decoded).convert(numChannels: 4);
  final width = output.width;
  final height = output.height;
  if (seedX < 0 || seedY < 0 || seedX >= width || seedY >= height) {
    return bytes;
  }

  final seed = output.getPixel(seedX, seedY);
  final seedR = seed.r.toInt();
  final seedG = seed.g.toInt();
  final seedB = seed.b.toInt();
  if (seed.a < 8) {
    return bytes;
  }

  final toleranceSq = tolerance * tolerance * 3;
  final featherTolerance = tolerance + 34;
  final featherToleranceSq = featherTolerance * featherTolerance * 3;

  bool matchesSeed(int x, int y, int maxDistanceSq) {
    final pixel = output.getPixel(x, y);
    if (pixel.a < 8) {
      return false;
    }
    final dr = pixel.r.toInt() - seedR;
    final dg = pixel.g.toInt() - seedG;
    final db = pixel.b.toInt() - seedB;
    return (dr * dr) + (dg * dg) + (db * db) <= maxDistanceSq;
  }

  final visited = Uint8List(width * height);
  final removeMask = Uint8List(width * height);
  final queue = <int>[(seedY * width) + seedX];
  visited[(seedY * width) + seedX] = 1;
  var head = 0;
  var removedCount = 0;

  while (head < queue.length) {
    final index = queue[head++];
    final x = index % width;
    final y = index ~/ width;
    if (!matchesSeed(x, y, toleranceSq)) {
      continue;
    }
    removeMask[index] = 1;
    removedCount++;

    void push(int nx, int ny) {
      if (nx < 0 || ny < 0 || nx >= width || ny >= height) {
        return;
      }
      final nextIndex = (ny * width) + nx;
      if (visited[nextIndex] != 0) {
        return;
      }
      visited[nextIndex] = 1;
      queue.add(nextIndex);
    }

    push(x + 1, y);
    push(x - 1, y);
    push(x, y + 1);
    push(x, y - 1);
  }

  if (removedCount == 0) {
    return bytes;
  }

  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final index = (y * width) + x;
      if (removeMask[index] == 1) {
        final pixel = output.getPixel(x, y);
        output.setPixelRgba(x, y, pixel.r, pixel.g, pixel.b, 0);
      }
    }
  }

  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final index = (y * width) + x;
      if (removeMask[index] != 1) {
        continue;
      }
      for (var dy = -featherRadius; dy <= featherRadius; dy++) {
        for (var dx = -featherRadius; dx <= featherRadius; dx++) {
          if (dx == 0 && dy == 0) {
            continue;
          }
          final nx = x + dx;
          final ny = y + dy;
          if (nx < 0 || ny < 0 || nx >= width || ny >= height) {
            continue;
          }
          final nextIndex = (ny * width) + nx;
          if (removeMask[nextIndex] == 1 ||
              !matchesSeed(nx, ny, featherToleranceSq)) {
            continue;
          }
          final distance = math.sqrt((dx * dx) + (dy * dy));
          if (distance > featherRadius) {
            continue;
          }
          final pixel = output.getPixel(nx, ny);
          final factor = (distance / (featherRadius + 1)).clamp(0.0, 1.0);
          final nextAlpha = math.min(
            pixel.a.toInt(),
            (pixel.a * factor).round().clamp(0, 255),
          );
          output.setPixelRgba(nx, ny, pixel.r, pixel.g, pixel.b, nextAlpha);
        }
      }
    }
  }

  return Uint8List.fromList(img.encodePng(output));
}

Uint8List _erasePhotoBrushBytes(Map<String, Object?> input) {
  final bytes = input['bytes'] as Uint8List;
  final points = (input['points'] as List).cast<double>();
  final brushSize = (input['brushSize'] as num?)?.toDouble() ?? 42;
  final brushRadiusNormalized = (input['brushRadiusNormalized'] as num?)
      ?.toDouble();
  final hardness = ((input['hardness'] as num?)?.toDouble() ?? 0.28).clamp(
    0.0,
    1.0,
  );
  final flipX = input['flipX'] as bool? ?? false;
  final flipY = input['flipY'] as bool? ?? false;
  final decoded = img.decodeImage(bytes);
  if (decoded == null || points.length < 2) {
    return bytes;
  }

  final output = img.Image.from(decoded).convert(numChannels: 4);
  final width = output.width;
  final height = output.height;
  final radius = brushRadiusNormalized == null || brushRadiusNormalized <= 0
      ? ((brushSize / 2) * (width / 360.0))
      : brushRadiusNormalized * math.min(width, height);
  final clampedRadius = radius
      .clamp(2.0, math.min(width, height) / 2)
      .toDouble();
  final hardRadius = clampedRadius * (hardness * 0.72).clamp(0.0, 0.82);
  final softSpan = math.max(0.001, clampedRadius - hardRadius);

  void eraseAt(double normalizedX, double normalizedY) {
    final mappedX = (flipX ? 1 - normalizedX : normalizedX).clamp(0.0, 1.0);
    final mappedY = (flipY ? 1 - normalizedY : normalizedY).clamp(0.0, 1.0);
    final centerX = mappedX * (width - 1);
    final centerY = mappedY * (height - 1);
    final minX = math.max(0, (centerX - clampedRadius).floor());
    final maxX = math.min(width - 1, (centerX + clampedRadius).ceil());
    final minY = math.max(0, (centerY - clampedRadius).floor());
    final maxY = math.min(height - 1, (centerY + clampedRadius).ceil());

    for (var y = minY; y <= maxY; y++) {
      for (var x = minX; x <= maxX; x++) {
        final dx = x - centerX;
        final dy = y - centerY;
        final distance = math.sqrt((dx * dx) + (dy * dy));
        if (distance > clampedRadius) {
          continue;
        }
        final pixel = output.getPixel(x, y);
        final alpha = pixel.a.toInt();
        if (alpha == 0) {
          continue;
        }
        final strength = distance <= hardRadius
            ? 1.0
            : (1 - ((distance - hardRadius) / softSpan)).clamp(0.0, 1.0);
        final easedStrength =
            strength * strength * (3 - (2 * strength)); // smoothstep feather
        final nextAlpha = (alpha * (1 - easedStrength)).round().clamp(0, 255);
        output.setPixelRgba(x, y, pixel.r, pixel.g, pixel.b, nextAlpha);
      }
    }
  }

  for (var i = 0; i < points.length - 1; i += 2) {
    final x = points[i];
    final y = points[i + 1];
    eraseAt(x, y);
    if (i + 3 >= points.length) {
      continue;
    }
    final nextX = points[i + 2];
    final nextY = points[i + 3];
    final dx = nextX - x;
    final dy = nextY - y;
    final distance = math.sqrt((dx * dx) + (dy * dy));
    final steps = math.max(
      1,
      (distance * math.max(width, height) / (clampedRadius * 0.28)).ceil(),
    );
    for (var step = 1; step < steps; step++) {
      final t = step / steps;
      eraseAt(x + (dx * t), y + (dy * t));
    }
  }

  return Uint8List.fromList(img.encodePng(output));
}

Widget _buildAdjustedPhoto({
  required Uint8List bytes,
  required String cacheKey,
  required int? cacheWidth,
  required double brightness,
  required double contrast,
  required double saturation,
  required double blur,
}) {
  final _ = cacheWidth;
  final presentation = _AdjustedPhotoPresentationCache.resolve(
    bytes: bytes,
    key: cacheKey,
    opacity: 1,
  );
  Widget child = presentation.image;

  final blurSigma = _mapAdjustBlurToSigma(blur);
  if (blurSigma > 0.01) {
    child = ImageFiltered(
      imageFilter: ui.ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
      child: child,
    );
  }
  final saturationMatrix = saturation == 1
      ? null
      : _saturationMatrix(saturation);
  if (saturationMatrix != null) {
    child = ColorFiltered(
      colorFilter: ColorFilter.matrix(saturationMatrix),
      child: child,
    );
  }
  final brightnessContrastMatrix =
      brightness.abs() < 0.0001 && (contrast - 1).abs() < 0.0001
      ? null
      : _brightnessContrastMatrix(brightness: brightness, contrast: contrast);
  if (brightnessContrastMatrix != null) {
    child = ColorFiltered(
      colorFilter: ColorFilter.matrix(brightnessContrastMatrix),
      child: child,
    );
  }
  return child;
}

// ignore: unused_element
Widget _buildAdjustedRawPhoto({
  required ui.Image image,
  required double brightness,
  required double contrast,
  required double saturation,
  required double blur,
}) {
  Widget child = RawImage(
    image: image,
    fit: BoxFit.contain,
    filterQuality: FilterQuality.medium,
  );

  final blurSigma = _mapAdjustBlurToSigma(blur);
  if (blurSigma > 0.01) {
    child = ImageFiltered(
      imageFilter: ui.ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
      child: child,
    );
  }
  final saturationMatrix = saturation == 1
      ? null
      : _saturationMatrix(saturation);
  if (saturationMatrix != null) {
    child = ColorFiltered(
      colorFilter: ColorFilter.matrix(saturationMatrix),
      child: child,
    );
  }
  final brightnessContrastMatrix =
      brightness.abs() < 0.0001 && (contrast - 1).abs() < 0.0001
      ? null
      : _brightnessContrastMatrix(brightness: brightness, contrast: contrast);
  if (brightnessContrastMatrix != null) {
    child = ColorFiltered(
      colorFilter: ColorFilter.matrix(brightnessContrastMatrix),
      child: child,
    );
  }
  return child;
}
