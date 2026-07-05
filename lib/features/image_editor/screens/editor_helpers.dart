part of 'image_editor_screen.dart';

class _AdjustedPhotoPresentationCache {
  const _AdjustedPhotoPresentationCache();

  static final LinkedHashMap<String, _AdjustedPhotoPresentation> _cache =
      LinkedHashMap<String, _AdjustedPhotoPresentation>();
  static const int _maxEntries = 96;

  static _AdjustedPhotoPresentation resolve({
    required Uint8List bytes,
    required String key,
    required int? cacheWidth,
    required bool highQuality,
    required double opacity,
  }) {
    final cacheKey = highQuality ? '${key}_hq' : '${key}_cw_${cacheWidth ?? 0}';
    final existing = _cache.remove(cacheKey);
    if (existing != null) {
      _cache[cacheKey] = existing;
      return existing;
    }
    final image = Image.memory(
      bytes,
      gaplessPlayback: true,
      filterQuality: highQuality ? FilterQuality.high : FilterQuality.medium,
      fit: BoxFit.contain,
      cacheWidth: highQuality ? null : cacheWidth,
      frameBuilder:
          (BuildContext context, Widget child, int? frame, bool sync) => child,
    );
    final presentation = _AdjustedPhotoPresentation(
      key: key,
      image: image,
      opacity: opacity,
    );
    _cache[cacheKey] = presentation;
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
  if (width <= 0 || height <= 0) {
    return bytes;
  }
  final radius = brushRadiusNormalized == null || brushRadiusNormalized <= 0
      ? ((brushSize / 2) * (width / 360.0))
      : brushRadiusNormalized * math.min(width, height);
  final clampedRadius = radius
      .clamp(2.0, math.min(width, height) / 2)
      .toDouble();
  final alphaMask = Uint8List(width * height);
  var touchedMinX = width;
  var touchedMinY = height;
  var touchedMaxX = -1;
  var touchedMaxY = -1;

  double brushCoverage(double distanceSquared) {
    return _editorRoundBrushCoverage(
      distanceSquared: distanceSquared,
      radius: clampedRadius,
      hardness: hardness,
    );
  }

  void stampAt(double normalizedX, double normalizedY) {
    final mappedX = (flipX ? 1 - normalizedX : normalizedX).clamp(0.0, 1.0);
    final mappedY = (flipY ? 1 - normalizedY : normalizedY).clamp(0.0, 1.0);
    final centerX = mappedX * width;
    final centerY = mappedY * height;
    final minX = math.max(0, (centerX - clampedRadius).floor());
    final maxX = math.min(width - 1, (centerX + clampedRadius).floor());
    final minY = math.max(0, (centerY - clampedRadius).floor());
    final maxY = math.min(height - 1, (centerY + clampedRadius).floor());

    for (var y = minY; y <= maxY; y++) {
      final pixelCenterY = y + 0.5;
      for (var x = minX; x <= maxX; x++) {
        final pixelCenterX = x + 0.5;
        final dx = pixelCenterX - centerX;
        final dy = pixelCenterY - centerY;
        final coverage = brushCoverage((dx * dx) + (dy * dy));
        if (coverage <= 0) {
          continue;
        }
        final coverageByte = (coverage * 255).round().clamp(0, 255);
        final maskIndex = (y * width) + x;
        if (coverageByte > alphaMask[maskIndex]) {
          alphaMask[maskIndex] = coverageByte;
          if (x < touchedMinX) {
            touchedMinX = x;
          }
          if (x > touchedMaxX) {
            touchedMaxX = x;
          }
          if (y < touchedMinY) {
            touchedMinY = y;
          }
          if (y > touchedMaxY) {
            touchedMaxY = y;
          }
        }
      }
    }
  }

  for (var i = 0; i < points.length - 1; i += 2) {
    final x = points[i];
    final y = points[i + 1];
    stampAt(x, y);
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
      (distance * math.max(width, height) / (clampedRadius * 0.18)).ceil(),
    );
    for (var step = 1; step < steps; step++) {
      final t = step / steps;
      stampAt(x + (dx * t), y + (dy * t));
    }
  }

  if (touchedMaxX < touchedMinX || touchedMaxY < touchedMinY) {
    return bytes;
  }

  for (var y = touchedMinY; y <= touchedMaxY; y++) {
    for (var x = touchedMinX; x <= touchedMaxX; x++) {
      final maskValue = alphaMask[(y * width) + x];
      if (maskValue <= 0) {
        continue;
      }
      final pixel = output.getPixel(x, y);
      final alpha = pixel.a.toInt();
      if (alpha == 0) {
        continue;
      }
      final eraseCoverage = maskValue / 255;
      final nextAlpha = (alpha * (1 - eraseCoverage)).round().clamp(0, 255);
      output.setPixelRgba(x, y, pixel.r, pixel.g, pixel.b, nextAlpha);
    }
  }

  return Uint8List.fromList(img.encodePng(output));
}

double _editorRoundBrushHardRadiusFactor(double hardness) {
  final value = hardness.clamp(0.0, 1.0).toDouble();
  if (value >= 0.999) {
    return 1;
  }
  if (value <= 0.001) {
    return 0;
  }
  return value;
}

double _editorRoundBrushCoverage({
  required double distanceSquared,
  required double radius,
  required double hardness,
}) {
  if (radius <= 0) {
    return 0;
  }
  final radiusSquared = radius * radius;
  if (distanceSquared > radiusSquared) {
    return 0;
  }
  final hardRadius = radius * _editorRoundBrushHardRadiusFactor(hardness);
  if (distanceSquared <= hardRadius * hardRadius) {
    return 1;
  }
  if (hardRadius >= radius) {
    return 1;
  }
  final distance = math.sqrt(distanceSquared);
  final edgeProgress = ((distance - hardRadius) / (radius - hardRadius)).clamp(
    0.0,
    1.0,
  );
  final feather = 1 - edgeProgress;
  return feather * feather * feather * (feather * ((feather * 6) - 15) + 10);
}

Widget _buildAdjustedPhoto({
  required Uint8List bytes,
  required String cacheKey,
  required int? cacheWidth,
  required bool highQuality,
  required double brightness,
  required double contrast,
  required double saturation,
  required double blur,
  required double sharpen,
  required double grain,
  required double vignette,
  required double motion,
  required double tiltShift,
  required double shadows,
  required double highlights,
  required double temperature,
  required double tint,
}) {
  final presentation = _AdjustedPhotoPresentationCache.resolve(
    bytes: bytes,
    key: cacheKey,
    cacheWidth: cacheWidth,
    highQuality: highQuality,
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
  final toneColorMatrix = _toneColorBalanceMatrix(
    shadows: shadows,
    highlights: highlights,
    temperature: temperature,
    tint: tint,
  );
  if (toneColorMatrix != null) {
    child = ColorFiltered(
      colorFilter: ColorFilter.matrix(toneColorMatrix),
      child: child,
    );
  }
  return _PhotoLocalEffectsLayer(
    sharpen: sharpen,
    grain: grain,
    vignette: vignette,
    motion: motion,
    tiltShift: tiltShift,
    child: child,
  );
}

// ignore: unused_element
Widget _buildAdjustedRawPhoto({
  required ui.Image image,
  required double brightness,
  required double contrast,
  required double saturation,
  required double blur,
  required double sharpen,
  required double grain,
  required double vignette,
  required double motion,
  required double tiltShift,
  required double shadows,
  required double highlights,
  required double temperature,
  required double tint,
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
  final toneColorMatrix = _toneColorBalanceMatrix(
    shadows: shadows,
    highlights: highlights,
    temperature: temperature,
    tint: tint,
  );
  if (toneColorMatrix != null) {
    child = ColorFiltered(
      colorFilter: ColorFilter.matrix(toneColorMatrix),
      child: child,
    );
  }
  return _PhotoLocalEffectsLayer(
    sharpen: sharpen,
    grain: grain,
    vignette: vignette,
    motion: motion,
    tiltShift: tiltShift,
    child: child,
  );
}

List<double>? _toneColorBalanceMatrix({
  required double shadows,
  required double highlights,
  required double temperature,
  required double tint,
}) {
  final shadow = shadows.clamp(-100.0, 100.0).toDouble() / 100;
  final highlight = highlights.clamp(-100.0, 100.0).toDouble() / 100;
  final warmth = temperature.clamp(-100.0, 100.0).toDouble() / 100;
  final tintAmount = tint.clamp(-100.0, 100.0).toDouble() / 100;
  if (shadow.abs() < 0.0001 &&
      highlight.abs() < 0.0001 &&
      warmth.abs() < 0.0001 &&
      tintAmount.abs() < 0.0001) {
    return null;
  }

  // A stable two-point RGB curve: shadows move the black point while
  // highlights move the white point. Temperature and tint then adjust channel
  // gains without altering alpha, so transparent photo edges remain intact.
  final blackPoint = shadow >= 0 ? shadow * 42 : shadow * 10;
  final whitePoint = 255 + (highlight * 54);
  final tonalScale = ((whitePoint - blackPoint) / 255).clamp(0.45, 1.55);
  final redScale = tonalScale * (1 + (warmth * 0.18) + (tintAmount * 0.06));
  final greenScale = tonalScale * (1 - (tintAmount * 0.12));
  final blueScale = tonalScale * (1 - (warmth * 0.18) + (tintAmount * 0.06));
  return <double>[
    redScale,
    0,
    0,
    0,
    blackPoint,
    0,
    greenScale,
    0,
    0,
    blackPoint,
    0,
    0,
    blueScale,
    0,
    blackPoint,
    0,
    0,
    0,
    1,
    0,
  ];
}

class _PhotoLocalEffectsLayer extends StatelessWidget {
  const _PhotoLocalEffectsLayer({
    required this.sharpen,
    required this.grain,
    required this.vignette,
    required this.motion,
    required this.tiltShift,
    required this.child,
  });

  final double sharpen;
  final double grain;
  final double vignette;
  final double motion;
  final double tiltShift;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final sharpenAmount = sharpen.clamp(0.0, 100.0).toDouble();
    final grainAmount = grain.clamp(0.0, 100.0).toDouble();
    final vignetteAmount = vignette.clamp(0.0, 100.0).toDouble();
    final motionAmount = motion.clamp(0.0, 100.0).toDouble();
    final tiltShiftAmount = tiltShift.clamp(0.0, 100.0).toDouble();
    Widget result = child;

    if (sharpenAmount > 0.01) {
      final clarity = math
          .pow((sharpenAmount / 100).clamp(0.0, 1.0), 0.78)
          .toDouble();
      final matrix = _brightnessContrastMatrix(
        brightness: 0,
        contrast: 1 + (clarity * 0.55),
      );
      result = ColorFiltered(
        colorFilter: ColorFilter.matrix(matrix),
        child: result,
      );
    }

    if (tiltShiftAmount > 0.01) {
      final tiltStrength = math
          .pow((tiltShiftAmount / 100).clamp(0.0, 1.0), 0.72)
          .toDouble();
      final blur = 3.0 + (tiltStrength * 22);
      final focusHalfHeight = 0.10 + ((1 - tiltStrength) * 0.26);
      result = Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Positioned.fill(
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: result,
            ),
          ),
          Positioned.fill(
            child: ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (Rect bounds) {
                final top = (0.5 - focusHalfHeight).clamp(0.05, 0.48);
                final bottom = (0.5 + focusHalfHeight).clamp(0.52, 0.95);
                return LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: const <Color>[
                    Color(0x00FFFFFF),
                    Color(0xFFFFFFFF),
                    Color(0xFFFFFFFF),
                    Color(0x00FFFFFF),
                  ],
                  stops: <double>[0, top.toDouble(), bottom.toDouble(), 1],
                ).createShader(bounds);
              },
              child: child,
            ),
          ),
        ],
      );
    }

    if (motionAmount > 0.01) {
      final motionStrength = math
          .pow((motionAmount / 100).clamp(0.0, 1.0), 0.78)
          .toDouble();
      final dx = 1.5 + (motionStrength * 18);
      final opacity = (motionStrength * 0.34).clamp(0.0, 0.34).toDouble();
      result = Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Positioned.fill(child: result),
          for (final offset in <double>[-2, -1, 1, 2])
            Positioned.fill(
              child: Opacity(
                opacity: opacity / offset.abs(),
                child: Transform.translate(
                  offset: Offset(dx * offset, 0),
                  child: child,
                ),
              ),
            ),
        ],
      );
    }

    if (grainAmount > 0.01 || vignetteAmount > 0.01) {
      result = Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Positioned.fill(child: result),
          if (grainAmount > 0.01)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _PhotoGrainPainter(intensity: grainAmount / 100),
                ),
              ),
            ),
          if (vignetteAmount > 0.01)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 0.68 + ((1 - (vignetteAmount / 100)) * 0.33),
                      colors: <Color>[
                        Colors.transparent,
                        Colors.black.withValues(
                          alpha: (0.12 + (vignetteAmount / 100 * 0.72))
                              .clamp(0.0, 0.84)
                              .toDouble(),
                        ),
                      ],
                      stops: const <double>[0.55, 1.0],
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    }

    return result;
  }
}

class _PhotoGrainPainter extends CustomPainter {
  const _PhotoGrainPainter({required this.intensity});

  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || intensity <= 0) {
      return;
    }
    final effectiveIntensity = math
        .pow(intensity.clamp(0.0, 1.0), 0.8)
        .toDouble();
    final step = (6 - (effectiveIntensity * 4.2)).clamp(1.8, 6.0).toDouble();
    final alpha = (0.025 + (effectiveIntensity * 0.14))
        .clamp(0.0, 0.18)
        .toDouble();
    final darkPaint = Paint()..color = Colors.black.withValues(alpha: alpha);
    final lightPaint = Paint()
      ..color = Colors.white.withValues(alpha: alpha * 0.62);
    for (double y = 0; y < size.height; y += step) {
      for (double x = 0; x < size.width; x += step) {
        final seed = (math.sin(x * 12.9898 + y * 78.233) * 43758.5453).abs();
        final value = seed - seed.floorToDouble();
        if (value > 0.62) {
          canvas.drawRect(Rect.fromLTWH(x, y, 1.4, 1.4), darkPaint);
        } else if (value < 0.16) {
          canvas.drawRect(Rect.fromLTWH(x, y, 1.0, 1.0), lightPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PhotoGrainPainter oldDelegate) =>
      (oldDelegate.intensity - intensity).abs() > 0.001;
}
